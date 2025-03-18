package cluster

import (
	"encoding/json"
	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/server"
)

type ClusterDelegate struct {
	nodeID       string
	stateManager *server.StateManager
	persistence  *server.ConfigPersistence
	updater      *server.Updater
}

func NewClusterDelegate(nodeID string, stateManager *server.StateManager, persistence *server.ConfigPersistence, updater *server.Updater) *ClusterDelegate {
	return &ClusterDelegate{
		nodeID:       nodeID,
		stateManager: stateManager,
		persistence:  persistence,
		updater:      updater,
	}
}

func (d *ClusterDelegate) NodeMeta(limit int) []byte {
	meta := struct {
		NodeID  string `json:"node_id"`
		Version int64  `json:"version"`
	}{
		NodeID:  d.nodeID,
		Version: d.stateManager.GetVersion(),
	}
	data, err := json.Marshal(meta)
	if err != nil {
		logging.GetLogger().Error("Error marshaling metadata: %v", err)
		return []byte{}
	}
	if len(data) > limit {
		return data[:limit]
	}
	return data
}

func (d *ClusterDelegate) NotifyMsg(msg []byte) {
	if len(msg) == 0 {
		return
	}

	logger := logging.GetLogger()

	// Attempt to unmarshal into a generic map to check for a snapshot op.
	var genericMsg map[string]any
	if err := json.Unmarshal(msg, &genericMsg); err != nil {
		logger.Error("Error unmarshaling message into generic map: %v", err)
		return
	}

	// If an "op" field exists, assume this is a snapshot operation.
	if opVal, ok := genericMsg["op"]; ok {
		opStr, ok := opVal.(string)
		if !ok {
			logger.Error("Snapshot operation field is not a string")
			return
		}

		// Unmarshal into a SnapshotUpdate.
		var snapshotUpdate api.SnapshotUpdate
		if err := json.Unmarshal(msg, &snapshotUpdate); err != nil {
			logger.Error("Error unmarshaling SnapshotUpdate: %v", err)
			return
		}

		logger.Debug("Processing snapshot op %q for snapshot %q", opStr, snapshotUpdate.Name)
		switch api.SnapshotOp(opStr) {
		case api.SnapshotOpCreate:
			if err := d.persistence.SaveSnapshot(snapshotUpdate.Name); err != nil {
				logger.Error("Error creating snapshot: %v", err)
			}
		case api.SnapshotOpActivate:
			if err := d.persistence.ActivateSnapshot(snapshotUpdate.Name); err != nil {
				logger.Error("Error activating snapshot: %v", err)
			}
		case api.SnapshotOpDelete:
			if err := d.persistence.DeleteSnapshot(snapshotUpdate.Name); err != nil {
				logger.Error("Error deleting snapshot: %v", err)
			}
		default:
			logger.Error("Unknown snapshot op: %s", opStr)
		}
		// Exit early to prevent further processing.
		return
	}

	// Handle binary version message.
	var binaryMsg server.VersionMessage
	if err := json.Unmarshal(msg, &binaryMsg); err == nil {
		if err := d.updater.PerformRemoteUpdate(binaryMsg); err != nil {
			logger.Error("PerformRemoteUpdate error: %v", err)
		}
		// Exit early to prevent further processing.
		return
	}

	// Process config update.
	var update api.ConfigUpdate
	if err := json.Unmarshal(msg, &update); err != nil {
		logger.Error("Error unmarshaling update: %v", err)
		return
	}

	if err := d.stateManager.ApplyUpdate(update); err != nil {
		logger.Error("Error applying update: %v", err)
		return
	}

	// Log the update for a representative key.
	var updateKey string
	for k := range update.Data {
		updateKey = k
		break
	}

	logger.Debug("Applied update for key %s from node %s (version: %d)",
		updateKey, update.NodeID, update.Version)
}

func (d *ClusterDelegate) GetBroadcasts(overhead, limit int) [][]byte {
	return nil
}

func (d *ClusterDelegate) LocalState(join bool) []byte {

	logger := logging.GetLogger()
	logger.Debug("LocalState requested (join=%v)", join)

	state := d.stateManager.GetFullState()
	snapshot := struct {
		Version int64                      `json:"version"`
		NodeID  string                     `json:"node_id"`
		State   map[string]*api.StateEntry `json:"state"`
	}{
		Version: d.stateManager.GetVersion(),
		NodeID:  d.nodeID,
		State:   state,
	}

	data, err := json.Marshal(snapshot)
	if err != nil {
		logger.Error("Error marshaling local state: %v", err)
		return nil
	}

	logger.Debug("Providing local state with %d entries (version: %d)",
		len(state), snapshot.Version)

	return data
}

func (d *ClusterDelegate) MergeRemoteState(buf []byte, join bool) {
	if len(buf) == 0 {
		return
	}

	logger := logging.GetLogger()
	logger.Debug("MergeRemoteState called (join=%v, size=%d)", join, len(buf))

	var snapshot struct {
		Version int64                      `json:"version"`
		NodeID  string                     `json:"node_id"`
		State   map[string]*api.StateEntry `json:"state"`
	}

	if err := json.Unmarshal(buf, &snapshot); err != nil {
		logger.Error("Error unmarshaling remote state: %v", err)
		return
	}

	logger.Debug("Merging remote state from node %s with %d entries (version: %d)",
		snapshot.NodeID, len(snapshot.State), snapshot.Version)
	d.stateManager.MergeRemoteState(snapshot.State, snapshot.NodeID)

	d.persistence.MarkDirty()
}
