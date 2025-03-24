package server

import (
	"bytes"
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"io"
	"net/http"
	"time"

	"github.com/hashicorp/memberlist"
)

// HandleListSnapshots returns a list of all available snapshot names.
func (h *Handler) HandleListSnapshots() ([]string, error) {
	return h.persistence.ListSnapshots()
}

// HandleActivateSnapshot activates the specified snapshot and broadcasts the change to the cluster.
func (h *Handler) HandleActivateSnapshot(name string) error {
	if err := h.persistence.ActivateSnapshot(name); err != nil {
		return fmt.Errorf("failed to activate snapshot: %w", err)
	}
	if err := h.handleSnapshotOperation(h.stateManager.node, name, api.NotifyOpSnapActivate, nil); err != nil {
		return fmt.Errorf("failed to handle snapshot activate: %w", err)
	}
	return nil
}

// HandleCreateSnapshot creates a new snapshot and broadcasts it to the cluster with the current system state.
func (h *Handler) HandleCreateSnapshot(name string) error {
	if err := h.persistence.CreateSnapshot(name); err != nil {
		return fmt.Errorf("failed to create snapshot: %w", err)
	}

	data := TransformState(h.stateManager.GetFullState())
	if err := h.handleSnapshotOperation(h.stateManager.node, name, api.NotifyOpSnapCreate, data); err != nil {
		return fmt.Errorf("failed to handle snapshot create: %w", err)
	}
	return nil
}

// HandleDeleteSnapshot removes the specified snapshot and notifies the cluster.
func (h *Handler) HandleDeleteSnapshot(name string) error {
	if err := h.persistence.DeleteSnapshot(name); err != nil {
		return fmt.Errorf("failed to delete snapshot: %w", err)
	}
	if err := h.handleSnapshotOperation(h.stateManager.node, name, api.NotifyOpSnapDelete, nil); err != nil {
		return fmt.Errorf("failed to handle snapshot delete: %w", err)
	}
	return nil
}

// HandleImportSnapshots imports a batch of snapshots and broadcasts the import operation to the cluster.
func (h *Handler) HandleImportSnapshots(data map[string]any) error {
	if err := h.persistence.ImportSnapshots(data); err != nil {
		return fmt.Errorf("failed to import snapshot: %w", err)
	}

	if err := h.handleSnapshotOperation(h.stateManager.node, defaultBucketName, api.NotifyOpSnapImport, data); err != nil {
		return fmt.Errorf("failed to handle snapshot import: %w", err)
	}

	return nil
}

// HandleSnapshotExists checks if a snapshot with the given name exists.
func (h *Handler) HandleSnapshotExists(name string) (bool, error) {
	return h.persistence.SnapshotExists(name)
}

// HandleGetSnapshotMetadata retrieves metadata for all stored snapshots.
func (h *Handler) HandleGetSnapshotMetadata() (api.SnapshotMetadata, error) {
	return h.persistence.GetSnapshotMetadata()
}

// HandleGetSnapshot returns the full snapshot data for the specified name.
func (h *Handler) HandleGetSnapshot(name string) (any, error) {
	return h.persistence.GetSnapshot(name)
}

// HandleExportSnapshots exports all current snapshots.
func (h *Handler) HandleExportSnapshots() (any, error) {
	return h.persistence.ExportSnapshots()
}

// handleSnapshotOperation constructs a snapshot update message and broadcasts it to the cluster.
func (h *Handler) handleSnapshotOperation(node string, name string, update api.NotifyOp, data map[string]any) error {
	message := api.NotifyMessage{
		Operation:      update,
		Node:           node,
		SnapshotUpdate: &api.SnapshotUpdate{Name: name, Data: data, Timestamp: time.Now().UTC()},
	}
	return h.broadcastUpdate(message)
}

// ValidateSnapshots checks if all nodes in the cluster have consistent snapshot metadata and resolves any mismatches.
func ValidateSnapshots(list *memberlist.Memberlist) {
	logger := logging.GetLogger()
	members := list.Members()

	var snapshots []api.SnapshotMemberMetadata

	// Collect metadata for all alive members.
	for _, member := range members {
		if member.State != memberlist.StateAlive {
			continue
		}

		url := fmt.Sprintf("http://%s%s/snapshots/metadata", member.Addr.String(), api.HTTPPort)
		resp, err := http.Get(url)
		if err != nil {
			logger.Warn("Failed to get metadata from %s: %v", member.Name, err)
			continue
		}

		body, err := io.ReadAll(resp.Body)
		resp.Body.Close()
		if err != nil {
			logger.Warn("Error reading response body from %s: %v", member.Name, err)
			continue
		}

		var metadata api.SnapshotMetadata
		if err := json.Unmarshal(body, &metadata); err != nil {
			logger.Warn("Failed to unmarshal JSON from %s: %v. Raw JSON: %s", member.Name, err, string(body))
			continue
		}

		snapshots = append(snapshots, api.SnapshotMemberMetadata{Member: member, Metadata: metadata})
	}

	// Check for consistency by comparing DBHash values.
	consistent := true
	if len(snapshots) > 0 {
		firstHash := snapshots[0].Metadata.DBHash
		for _, ms := range snapshots[1:] {
			if ms.Metadata.DBHash != firstHash {
				consistent = false
				break
			}
		}
	}

	if consistent {
		logger.Info("[SNAPSHOTS] Snapshots consistent across cluster")
		return
	}

	logger.Warn("[SNAPSHOTS] Inconsistent Snapshot detected")

	rectifySnapshots(snapshots)
}

// rectifySnapshots resolves snapshot inconsistencies by pushing the most current snapshot to all outdated nodes.
func rectifySnapshots(snapshots []api.SnapshotMemberMetadata) {
	logger := logging.GetLogger()

	// Determine the snapshot with the most recent timestamp.
	mostCurrent := snapshots[0]
	for _, ms := range snapshots[1:] {
		if ms.Metadata.Timestamp.After(mostCurrent.Metadata.Timestamp) {
			mostCurrent = ms
		}
	}
	logger.Info("Most current snapshot found on member %s with timestamp %v",
		mostCurrent.Member.Name, mostCurrent.Metadata.Timestamp)

	// Propagate the most current snapshot to all nodes with outdated data.
	for _, ms := range snapshots {
		if ms.Metadata.DBHash != mostCurrent.Metadata.DBHash {
			importURL := fmt.Sprintf("http://%s%s/snapshots/import", ms.Member.Addr.String(), api.HTTPPort)
			// Prepare payload with all necessary snapshot data.
			payload, err := json.Marshal(map[string]interface{}{
				"active_snapshot": mostCurrent.Metadata.ActiveSnapshot,
				"timestamp":       mostCurrent.Metadata.Timestamp,
				"hash":            mostCurrent.Metadata.DBHash,
				"valid":           mostCurrent.Metadata.Valid,
			})
			if err != nil {
				logger.Warn("Failed to marshal payload for %s: %v", ms.Member.Name, err)
				continue
			}

			resp, err := http.Post(importURL, "application/json", bytes.NewBuffer(payload))
			if err != nil {
				logger.Warn("Failed to import snapshot on %s: %v", ms.Member.Name, err)
				continue
			}
			resp.Body.Close()
			logger.Info("Successfully synced snapshot on %s", ms.Member.Name)
		}
	}
}
