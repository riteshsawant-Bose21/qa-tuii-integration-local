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

	var message api.NotifyMessage
	if err := json.Unmarshal(msg, &message); err != nil {
		logger.Error("Error unmarshaling message: %v", err)
		return
	}

	// Check which message type was unmarshaled.
	switch message.Operation {

	case api.NotifyOpConfigUpdate:
		if err := d.stateManager.ApplyUpdate(*message.ConfigUpdate); err != nil {
			logger.Error("Error applying update: %v", err)
			return
		}

	case api.NotifyOpSnapActivate:
		if err := d.persistence.ActivateSnapshot(message.SnapshotUpdate.Name); err != nil {
			logger.Error("Error activating snapshot: %v", err)
		}

	case api.NotifyOpSnapCreate:
		if err := d.persistence.CreateSnapshot(message.SnapshotUpdate.Name); err != nil {
			logger.Error("Error creating snapshot: %v", err)
		}

	case api.NotifyOpSnapDelete:
		if err := d.persistence.DeleteSnapshot(message.SnapshotUpdate.Name); err != nil {
			logger.Error("Error deleting snapshot: %v", err)
		}

	case api.NotifyOpSnapImport:
		if err := d.persistence.ImportSnapshots(message.SnapshotUpdate.Data); err != nil {
			logger.Error("Error deleting snapshot: %v", err)
		}

	case api.NotifyOpVersionUpdate:
		if err := d.updater.PerformRemoteUpdate(*message.VersionMessage); err != nil {
			logger.Error("PerformRemoteUpdate error: %v", err)
		}

	default:
		logger.Error("Unknown message type")
	}
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
