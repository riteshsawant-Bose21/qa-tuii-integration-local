package pubsub

import (
	"context"
	"encoding/json"
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/cluster/transport"
	"fusion/internal/persistence"
	"sync"
	"time"
)

const configUpdateReliableDebounce = 250 * time.Millisecond

type Broadcaster interface {
	BroadcastMessage(msg *api.NotifyMessage) error
}

// ClusterObserverBroadcaster is implemented by observer transports that
// should receive events originating from another cluster node.
// WebSockets should receive these updates; local-only transports such as UDP should not.
type ClusterObserverBroadcaster interface {
	BroadcastToClusterObservers(msg *api.NotifyMessage) error
}

type LocalBroadcaster func(*api.NotifyMessage)

type configUpdateDebounceState struct {
	mu      sync.Mutex
	pending *api.NotifyMessage
	timer   *time.Timer
	window  time.Duration
}

type Hub struct {
	broadcasters []Broadcaster
	stateManager *persistence.StateManager
	persistence  *persistence.Persistence
	transport    transport.ClusterInterface

	configUpdates configUpdateDebounceState

	// SWUpdate progress monitoring
	swUpdateMutex    sync.RWMutex
	swUpdateActive   bool
	swUpdateCancel   context.CancelFunc
	swUpdateProgress map[string]*api.SoftwareUpdateProgress // node_name -> latest progress
}

func NewHub(stateManager *persistence.StateManager, persistence *persistence.Persistence) *Hub {
	return &Hub{
		stateManager: stateManager,
		persistence:  persistence,
		configUpdates: configUpdateDebounceState{
			window: configUpdateReliableDebounce,
		},
		swUpdateProgress: make(map[string]*api.SoftwareUpdateProgress),
	}
}

// SetClusterTransport injects the cluster transport (backed by memberlist).
// This is called once during app wiring after memberlist is constructed.
func (h *Hub) SetClusterTransport(t transport.ClusterInterface) {
	h.transport = t
}
func (h *Hub) Register(b Broadcaster) {
	h.broadcasters = append(h.broadcasters, b)
}

func (h *Hub) BroadcastToObservers(msg *api.NotifyMessage) {

	for _, bc := range h.broadcasters {
		if err := bc.BroadcastMessage(msg); err != nil {
			logging.GetLogger().Error("local broadcast failed: %v", err)
		}
	}
}

func (h *Hub) BroadcastToClusterObservers(msg *api.NotifyMessage) {
	for _, bc := range h.broadcasters {
		clusterBroadcaster, ok := bc.(ClusterObserverBroadcaster)
		if !ok {
			continue
		}
		if err := clusterBroadcaster.BroadcastToClusterObservers(msg); err != nil {
			logging.GetLogger().Error("cluster observer broadcast failed: %v", err)
		}
	}
}

// broadcastMessage processes an incoming NotifyMessage by applying configuration or snapshot updates,
// performing version changes, and then broadcasting the message to other nodes and local clients if needed.
func (h *Hub) BroadcastToNodes(message *api.NotifyMessage) error {

	logger := logging.GetLogger()

	logger.Debug("Hub::BroadcastToNodes: %v", message)

	switch message.Operation {

	case api.NotifyOpAudioRemove:
		if message.AudioRemove == nil {
			return fmt.Errorf("AudioRemove required for operation")
		}

	case api.NotifyOpAudioSync:
		if message.AudioSync == nil {
			return fmt.Errorf("AudioSync required for operation")
		}

		err := h.persistence.SyncAudioFile(message.AudioSync)
		if err != nil {
			return fmt.Errorf("audio sync failed: %w", err)
		}

	case api.NotifyOpConfigUpdate:

		var dirty bool
		var err error

		if h.transport == nil || h.transport.LocalNode() == nil {
			return fmt.Errorf("cluster transport not configured")
		}
		localNode := h.transport.LocalNode().Name

		if message.Node != localNode {
			// Handle remote update
			dirty, err = h.stateManager.ApplyUpdate(*message.ConfigUpdate)
			if err != nil {
				return fmt.Errorf("failed to apply remote update: %w", err)
			}
			if !dirty {
				logger.Debug(
					"broadcastMessage: skipping stale ConfigUpdate version=%v from node=%s",
					message.ConfigUpdate.Version,
					message.Node,
				)
				return nil
			}
		} else {
			// Local update: We already applied it before calling BroadcastToNodes
			dirty = true
		}

		// Overwrite with effective local Lamport version
		updated := *message.ConfigUpdate
		updated.Version = h.stateManager.GetVersion()
		logger.Debug("BroadcastToNodes::NotifyOpConfigUpdate setting Version: %d", updated.Version.Counter)
		message.ConfigUpdate = &updated

		h.persistence.MarkDirty()

		if message.Node == localNode {
			h.BroadcastToObservers(message)
			h.queueConfigUpdate(message)
			return nil
		}

	case api.NotifyOpTimeMachineActivate:
		if message.SnapshotOperation == nil || message.SnapshotOperation.Name == "" {
			return fmt.Errorf("SnapshotOperation with valid name required for snap activate")
		}

		logging.GetLogger().Debug("[Hub] SnapActivate on %s for %s (origin=%s)",
			h.transport.LocalNode().Name,
			message.SnapshotOperation.Name,
			message.Node,
		)

		if err := h.persistence.ActivateSnapshot(message.SnapshotOperation.Name); err != nil {
			return fmt.Errorf("error activating snapshot: %v", err)
		}

	case api.NotifyOpTimeMachineCreate:
		if err := h.persistence.CreateSnapshot(message.SnapshotOperation.Name); err != nil {
			return fmt.Errorf("error creating snapshot: %v", err)
		}

	case api.NotifyOpTimeMachineSave:
		if err := h.persistence.SaveSnapshot(message.SnapshotOperation.Name); err != nil {
			logger.Error("Error saving snapshot: %v", err)
		}

	case api.NotifyOpTimeMachineDelete:
		if err := h.persistence.DeleteSnapshot(message.SnapshotOperation.Name); err != nil {
			return fmt.Errorf("error deleting snapshot: %v", err)
		}

	case api.NotifyOpSnapshotDefsUpsert:
		if len(message.SnapshotDefinitions) == 0 {
			return fmt.Errorf("SnapshotDefinitions required for operation")
		}
		if h.transport == nil || h.transport.LocalNode() == nil {
			return fmt.Errorf("cluster transport not configured")
		}
		if message.Node != h.transport.LocalNode().Name {
			if err := h.persistence.UpsertSnapshotDefinitions(message.SnapshotDefinitions); err != nil {
				return fmt.Errorf("error upserting snapshot definitions: %v", err)
			}
		}

	case api.NotifyOpSceneSetsUpsert:
		if len(message.SceneSets) == 0 {
			return fmt.Errorf("SceneSets required for operation")
		}
		if h.transport == nil || h.transport.LocalNode() == nil {
			return fmt.Errorf("cluster transport not configured")
		}
		if message.Node != h.transport.LocalNode().Name {
			if err := h.persistence.UpsertSceneSets(message.SceneSets); err != nil {
				return fmt.Errorf("error upserting scene sets: %v", err)
			}
		}

	case api.NotifyOpSnapshotDefsDeleteAll:
		if h.transport == nil || h.transport.LocalNode() == nil {
			return fmt.Errorf("cluster transport not configured")
		}
		if message.Node != h.transport.LocalNode().Name {
			if err := h.persistence.DeleteAllSnapshotDefinitions(); err != nil {
				return fmt.Errorf("error deleting snapshot definitions: %v", err)
			}
		}

	case api.NotifyOpSnapshotDefDelete:
		if message.SnapshotOperation == nil || message.SnapshotOperation.Name == "" {
			return fmt.Errorf("SnapshotOperation with valid name required for snapshot delete")
		}
		if h.transport == nil || h.transport.LocalNode() == nil {
			return fmt.Errorf("cluster transport not configured")
		}
		if message.Node != h.transport.LocalNode().Name {
			if err := h.persistence.DeleteSnapshotDefinition(message.SnapshotOperation.Name); err != nil {
				return fmt.Errorf("error deleting snapshot definition: %v", err)
			}
		}

	case api.NotifyOpSceneSetsDeleteAll:
		if h.transport == nil || h.transport.LocalNode() == nil {
			return fmt.Errorf("cluster transport not configured")
		}
		if message.Node != h.transport.LocalNode().Name {
			if err := h.persistence.DeleteAllSceneSets(); err != nil {
				return fmt.Errorf("error deleting scene sets: %v", err)
			}
		}

	case api.NotifyOpSceneSetDelete:
		if message.SceneSetOperation == nil || message.SceneSetOperation.SetID == "" {
			return fmt.Errorf("SceneSetOperation with valid set_id required for scene set delete")
		}
		if h.transport == nil || h.transport.LocalNode() == nil {
			return fmt.Errorf("cluster transport not configured")
		}
		if message.Node != h.transport.LocalNode().Name {
			if err := h.persistence.DeleteSceneSet(message.SceneSetOperation.SetID); err != nil {
				return fmt.Errorf("error deleting scene set: %v", err)
			}
		}

	case api.NotifyOpSceneDelete:
		if message.SceneOperation == nil || message.SceneOperation.SceneID == "" {
			return fmt.Errorf("SceneOperation with valid scene_id required for scene delete")
		}
		if h.transport == nil || h.transport.LocalNode() == nil {
			return fmt.Errorf("cluster transport not configured")
		}
		if message.Node != h.transport.LocalNode().Name {
			if err := h.persistence.DeleteScene(message.SceneOperation.SceneID); err != nil {
				return fmt.Errorf("error deleting scene: %v", err)
			}
		}

	case api.NotifyOpSnapshotV2Activate:
		if message.SnapshotActivation == nil {
			return fmt.Errorf("SnapshotActivation required for operation")
		}

	case api.NotifyOpSceneActivate:
		if message.SceneActivation == nil {
			return fmt.Errorf("SceneActivation required for operation")
		}
		if h.transport == nil || h.transport.LocalNode() == nil {
			return fmt.Errorf("cluster transport not configured")
		}
		if message.Node != h.transport.LocalNode().Name {
			if err := h.persistence.SetCurrentScene(message.SceneActivation.SetID, message.SceneActivation.SceneID); err != nil {
				return fmt.Errorf("error setting current scene: %v", err)
			}
		}

	case api.NotifyOpDeviceUpdate:
		if message.DeviceInfo == nil {
			return fmt.Errorf("DeviceInfo required for operation")
		}

	case api.NotifyOpVersionUpdate:
		if message.VersionUpdate == nil {
			return fmt.Errorf("VersionUpdate required for operation")
		}

	case api.NotifyOpSoftwareUpdate:
		logger.Info("[Hub] Broadcasting software update trigger")
		// Primary starts follower orchestration: broadcast to followers first,
		// wait for all followers to reach DONE, then start self-update.
		if h.transport != nil && h.transport.LocalNode() != nil && message.Node == h.transport.LocalNode().Name {
			h.startFollowerOrchestration()
		}

	case api.NotifyOpSoftwareUpdateProgress:
		if message.SoftwareUpdateProgress == nil {
			return fmt.Errorf("SoftwareUpdateProgress required for progress operation")
		}
		logger.Debug("[Hub] Processing software update progress from %s: %s %d%% (step %d/%d)",
			message.SoftwareUpdateProgress.NodeName,
			message.SoftwareUpdateProgress.Status,
			message.SoftwareUpdateProgress.CurPercent,
			message.SoftwareUpdateProgress.CurStep,
			message.SoftwareUpdateProgress.NSteps)

		// Store progress; aggregation is attached after gossip fanout (see below)
		h.updateSWProgress(message.SoftwareUpdateProgress)

	case api.NotifyOpSoftwareUpdateAvailable:
		if message.SoftwareUpdate == nil {
			return fmt.Errorf("SoftwareUpdate required for SoftwareUpdate available operation")
		}
		logger.Info("[Hub] Broadcasting SoftwareUpdate availability: %s (%d bytes) from %s",
			message.SoftwareUpdate.Filename, message.SoftwareUpdate.SizeBytes, message.SoftwareUpdate.SourceIP)

	case api.NotifyOpSoftwareUpdateSyncAck:
		if message.SoftwareUpdateAck == nil {
			return fmt.Errorf("SoftwareUpdateAck required for SoftwareUpdate sync acknowledgment operation")
		}
		logger.Info("[Hub] Broadcasting SoftwareUpdate sync acknowledgment: %s (success: %v, sync ID: %s)",
			message.SoftwareUpdateAck.Filename, message.SoftwareUpdateAck.Success, message.SoftwareUpdateAck.SyncID)

	default:
		return fmt.Errorf("unknown operation type: %s", message.Operation)
	}

	// Broadcast the message to other nodes if this is the origin node.
	if h.transport == nil || h.transport.LocalNode() == nil {
		return fmt.Errorf("cluster transport not configured")
	}

	localNode := h.transport.LocalNode().Name
	logger.Debug("Hub::BroadcastToNodes: messageNode (%s) localNode (%s), ", message.Node, localNode)

	if message.Node == localNode {
		data, err := json.Marshal(message)
		if err != nil {
			return fmt.Errorf("failed to marshal update: %w", err)
		}
		// Primary never triggers itself via gossip for software updates.
		// The orchestration goroutine (waitForFollowersThenUpdateSelf) starts
		// the primary's own update after all followers have reached DONE.
		h.broadcastToNodes(data, false)
	}

	// Attach the aggregated progress map only for local WebSocket delivery.
	// This is done after gossiping so the cluster payload stays lean (single-node only).
	if message.Operation == api.NotifyOpSoftwareUpdateProgress {
		message.SoftwareUpdateProgressAll = h.getAggregatedProgress()
	}

	if message.Operation == api.NotifyOpVersionUpdate {
		return nil
	}

	h.BroadcastToObservers(message)

	return nil
}

func (h *Hub) queueConfigUpdate(message *api.NotifyMessage) {
	if message == nil {
		return
	}

	h.configUpdates.mu.Lock()
	h.configUpdates.pending = cloneNotifyMessageForBroadcast(message)
	if h.configUpdates.timer == nil {
		h.configUpdates.timer = time.AfterFunc(h.configUpdates.window, h.flushConfigUpdate)
	}
	h.configUpdates.mu.Unlock()
}

func (h *Hub) flushConfigUpdate() {
	h.configUpdates.mu.Lock()
	message := h.configUpdates.pending
	h.configUpdates.pending = nil
	h.configUpdates.timer = nil
	h.configUpdates.mu.Unlock()

	if message == nil {
		return
	}

	data, err := json.Marshal(message)
	if err != nil {
		logging.GetLogger().Error("failed to marshal debounced config update: %v", err)
		return
	}
	h.broadcastToNodes(data, false)
}

func cloneNotifyMessageForBroadcast(message *api.NotifyMessage) *api.NotifyMessage {
	if message == nil {
		return nil
	}

	cloned := *message
	if message.ConfigUpdate != nil {
		cfg := *message.ConfigUpdate
		cloned.ConfigUpdate = &cfg
	}
	if message.ConfigValue != nil {
		cfg := *message.ConfigValue
		cloned.ConfigValue = &cfg
	}
	if message.DeviceInfo != nil {
		info := *message.DeviceInfo
		cloned.DeviceInfo = &info
	}
	return &cloned
}

func (h *Hub) BroadcastVersionUpdate(node string, metadata *api.DatabaseMetadata) {
	if metadata == nil || h.transport == nil || h.transport.LocalNode() == nil {
		return
	}

	msg := api.NewNotifyMessage(
		api.NotifyOpVersionUpdate,
		node,
		api.WithVersionUpdate(&api.VersionUpdate{
			Version: metadata.Version,
			Hash:    metadata.Hash,
			NodeID:  node,
		}),
	)

	if err := h.BroadcastToNodes(msg); err != nil {
		logging.GetLogger().Error("failed to broadcast version update: %v", err)
	}
}

func (h *Hub) broadcastToNodes(message []byte, includeLocalNode bool) {
	logger := logging.GetLogger()

	if h.transport == nil || h.transport.LocalNode() == nil {
		logger.Error("cluster transport not configured; cannot broadcast to nodes")
		return
	}

	localName := h.transport.LocalNode().Name
	members := h.transport.MemberListMembers()

	logger.Debug("[Hub] Broadcasting gossip to %d cluster members from %s", len(members), localName)

	for _, node := range members {
		// Skip local node unless explicitly requested to include it
		if !includeLocalNode && node.Name == localName {
			continue
		}
		logger.Debug("[Hub] Sending gossip message to node %s", node.Name)
		if err := h.transport.SendReliable(node, message); err != nil {
			logger.Error("Failed to send message to node %s: %v", node.Name, err)
		} else {
			logger.Debug("[Hub] Successfully sent gossip message to node %s", node.Name)
		}
	}
}
