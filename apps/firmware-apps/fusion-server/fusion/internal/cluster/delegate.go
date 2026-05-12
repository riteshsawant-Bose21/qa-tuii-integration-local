package cluster

import (
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/persistence"
	"fusion/internal/pubsub"
	"fusion/internal/routes"
	"fusion/internal/tasks"
	"fusion/internal/utils"
	"io"
	"math"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"time"

	json "github.com/goccy/go-json"
)

const (
	maxLatencyCount   = 1000
	skewPruneInterval = 1 * time.Minute
	skewPruneAge      = 10 * time.Minute
	skewTime          = 500 * time.Millisecond
)

// SyncHandler defines the interface for handling software update sync acknowledgments
type SyncHandler interface {
	HandleSyncAck(nodeName string, ack *api.SoftwareUpdateSyncAck)
}

type SkewEntry struct {
	Skew     time.Duration
	Detected time.Time
}

// SkewStore holds time skew values detected from incoming messages
type SkewStore struct {
	mu        sync.RWMutex
	timeSkews map[string]*SkewEntry
}

type versionUpdateState struct {
	mu   sync.Mutex
	seen map[string]api.VersionUpdate
}

func NewSkewStore() *SkewStore {
	return &SkewStore{
		timeSkews: make(map[string]*SkewEntry),
	}
}

// Add inserts a new record and updates rolling stats.
func (s *SkewStore) Add(node string, skew time.Duration, detected time.Time) {
	s.mu.Lock()
	s.timeSkews[node] = &SkewEntry{
		Skew:     skew,
		Detected: detected,
	}
	s.mu.Unlock()
}

// Prune removes stale records from the store.
func (s *SkewStore) Prune(ticker *time.Ticker, maxAge time.Duration) {
	for range ticker.C {
		now := time.Now()
		s.mu.Lock()
		for node, entry := range s.timeSkews {
			if now.Sub(entry.Detected) > maxAge {
				delete(s.timeSkews, node)
			}
		}
		s.mu.Unlock()
	}
}

type ClusterDelegate struct {
	appConfig     *api.AppConfig
	persistence   *persistence.Persistence
	stateManager  *persistence.StateManager
	taskManager   *tasks.TaskManager
	syncLatencies *SyncLatencyStore
	skewStore     *SkewStore
	versionState  versionUpdateState
	hub           *pubsub.Hub
	handler       SyncHandler // Interface to handle sync acknowledgments
}

func NewClusterDelegate(
	config *api.AppConfig,
	persistence *persistence.Persistence,
	stateManager *persistence.StateManager,
	taskManager *tasks.TaskManager,
	hub *pubsub.Hub) *ClusterDelegate {
	delegate := &ClusterDelegate{
		appConfig:     config,
		persistence:   persistence,
		stateManager:  stateManager,
		taskManager:   taskManager,
		hub:           hub,
		syncLatencies: NewSyncLatencyStore(maxLatencyCount, latencyPruneTime),
		skewStore:     NewSkewStore(),
		versionState: versionUpdateState{
			seen: make(map[string]api.VersionUpdate),
		},
	}

	delegate.startSkewPruner()

	return delegate
}

// SetSyncHandler sets the sync handler for processing software update acknowledgments
func (d *ClusterDelegate) SetSyncHandler(handler SyncHandler) {
	d.handler = handler
}

func (d *ClusterDelegate) NodeMeta(limit int) []byte {

	version := d.stateManager.GetVersion()

	meta := struct {
		NodeID  string      `json:"node_id"`
		Version api.Version `json:"version"`
	}{
		NodeID:  d.appConfig.NodeName,
		Version: version,
	}

	data, err := json.Marshal(meta)
	if err != nil {
		logging.GetLogger().Error("Error marshaling metadata: %v", err)
		return nil
	}

	if len(data) > limit {
		logging.GetLogger().Warn("NodeMeta (%d bytes) exceeds limit (%d), dropping metadata", len(data), limit)
		return nil
	}

	return data
}

func (d *ClusterDelegate) NotifyMsg(msg []byte) {

	logger := logging.GetLogger()

	if len(msg) == 0 {
		logger.Warn("Received empty message")
		return
	}

	var message api.NotifyMessage
	if err := json.Unmarshal(msg, &message); err != nil {
		logger.Error("Error unmarshaling message: %v", err)
		return
	}

	logger.Debug("[Delegate] Received gossip message: %s from %s", message.Operation, message.Node)

	now := time.Now().UTC()

	if !message.SentAt.IsZero() {

		// Detect clock skew
		if message.SentAt.After(now.Add(skewTime)) {
			skew := message.SentAt.Sub(now)
			d.skewStore.Add(message.Node, skew, now)
			logger.Warn("Clock skew detected: message from %s is %v ahead", message.Node, skew)
		}

		// Calculate latency, clamped to zero
		latency := max(now.Sub(message.SentAt), 0)
		latencyMs := float64(latency.Nanoseconds()) / 1e6
		latencyMs = math.Round(latencyMs*100) / 100

		d.syncLatencies.Add(SyncLatency{
			Sender:    message.Node,
			Receiver:  d.appConfig.NodeName,
			Operation: string(message.Operation),
			Latency:   latencyMs,
			Timestamp: time.Now(),
		})
	}

	switch message.Operation {

	case api.NotifyOpAudioRemove:
		if message.AudioRemove == nil {
			logger.Error("AudioRemove message with nil payload from %s", message.Node)
			return
		}
		if err := d.handleAudioRemove(message.AudioRemove); err != nil {
			logger.Error("Error handling audio remove from %s: %v", message.Node, err)
		}

	case api.NotifyOpAudioSync:
		if message.AudioSync == nil {
			logger.Error("AudioSync message with nil payload from %s", message.Node)
			return
		}
		if err := d.handleAudioSync(message.AudioSync); err != nil {
			logger.Error("Error handling audio sync from %s: %v", message.Node, err)
		}

	case api.NotifyOpConfigUpdate:
		dirty, err := d.stateManager.ApplyUpdate(*message.ConfigUpdate)
		if err != nil {
			logger.Error("Error applying update: %v", err)
			return
		}

		if !dirty {
			logger.Debug("[Delegate] Skipping stale ConfigUpdate version=%v from %s",
				message.ConfigUpdate.Version, message.Node)
			return
		}

		// Overwrite with effective local Lamport version
		updated := *message.ConfigUpdate
		updated.Version = d.stateManager.GetVersion()
		logger.Debug("[Delegate] NotifyOpConfigUpdate setting Version: %d", updated.Version.Counter)
		message.ConfigUpdate = &updated

		d.persistence.MarkDirty()
		d.hub.BroadcastToObservers(&message)

	case api.NotifyOpTimeMachineActivate:
		if message.SnapshotOperation == nil {
			logger.Error("SnapActivate message with nil payload from %s", message.Node)
			return
		}

		logger.Info("[Delegate] SnapActivate on %s for %s (from=%s)",
			d.appConfig.NodeName,
			message.SnapshotOperation.Name,
			message.Node,
		)

		if err := d.persistence.ActivateSnapshot(message.SnapshotOperation.Name); err != nil {
			logger.Error("Error activating snapshot: %v", err)
		}

	case api.NotifyOpTimeMachineCreate:
		if err := d.persistence.CreateSnapshot(message.SnapshotOperation.Name); err != nil {
			logger.Error("Error creating snapshot: %v", err)
		}

	case api.NotifyOpTimeMachineDelete:
		if err := d.persistence.DeleteSnapshot(message.SnapshotOperation.Name); err != nil {
			logger.Error("Error deleting snapshot: %v", err)
		}

	case api.NotifyOpTimeMachineSave:
		if err := d.persistence.SaveSnapshot(message.SnapshotOperation.Name); err != nil {
			logger.Error("Error saving snapshot: %v", err)
		}

	case api.NotifyOpSnapshotDefsUpsert:
		if len(message.SnapshotDefinitions) == 0 {
			logger.Error("SnapshotDefsUpsert message with empty payload from %s", message.Node)
			return
		}
		if err := d.persistence.UpsertSnapshotDefinitions(message.SnapshotDefinitions); err != nil {
			logger.Error("Error upserting snapshot definitions: %v", err)
		}

	case api.NotifyOpSnapshotDefsDeleteAll:
		if err := d.persistence.DeleteAllSnapshotDefinitions(); err != nil {
			logger.Error("Error deleting snapshot definitions: %v", err)
		}

	case api.NotifyOpSnapshotDefDelete:
		if message.SnapshotOperation == nil {
			logger.Error("SnapshotDefDelete message with nil payload from %s", message.Node)
			return
		}
		if err := d.persistence.DeleteSnapshotDefinition(message.SnapshotOperation.Name); err != nil {
			logger.Error("Error deleting snapshot definition '%s': %v", message.SnapshotOperation.Name, err)
		}

	case api.NotifyOpSceneSetsUpsert:
		if len(message.SceneSets) == 0 {
			logger.Error("SceneSetsUpsert message with empty payload from %s", message.Node)
			return
		}
		if err := d.persistence.UpsertSceneSets(message.SceneSets); err != nil {
			logger.Error("Error upserting scene sets: %v", err)
		}

	case api.NotifyOpSceneSetsDeleteAll:
		if err := d.persistence.DeleteAllSceneSets(); err != nil {
			logger.Error("Error deleting scene sets: %v", err)
		}

	case api.NotifyOpSceneSetDelete:
		if message.SceneSetOperation == nil {
			logger.Error("SceneSetDelete message with nil payload from %s", message.Node)
			return
		}
		if err := d.persistence.DeleteSceneSet(message.SceneSetOperation.SetID); err != nil {
			logger.Error("Error deleting scene set '%s': %v", message.SceneSetOperation.SetID, err)
		}

	case api.NotifyOpSceneDelete:
		if message.SceneOperation == nil {
			logger.Error("SceneDelete message with nil payload from %s", message.Node)
			return
		}
		if err := d.persistence.DeleteScene(message.SceneOperation.SceneID); err != nil {
			logger.Error("Error deleting scene '%s': %v", message.SceneOperation.SceneID, err)
		}

	case api.NotifyOpSnapshotV2Activate:
		if message.SnapshotActivation == nil {
			logger.Error("SnapshotV2Activate message with nil payload from %s", message.Node)
			return
		}

	case api.NotifyOpSceneActivate:
		if message.SceneActivation == nil {
			logger.Error("SceneActivate message with nil payload from %s", message.Node)
			return
		}
		if err := d.persistence.SetCurrentScene(message.SceneActivation.SetID, message.SceneActivation.SceneID); err != nil {
			logger.Error("Error setting current scene for set %s: %v", message.SceneActivation.SetID, err)
		}

	case api.NotifyOpTaskCreate:
		if err := d.taskManager.AddTask(message.Task); err != nil {
			logger.Error("Error creating task: %v", err)
		}

	case api.NotifyOpTaskDelete:
		if err := d.taskManager.RemoveTask(message.Task.ID); err != nil {
			logger.Error("Error deleting task: %v", err)
		}

	case api.NotifyOpTaskUpdate:
		if err := d.taskManager.UpdateTaskFromCluster(message.Task); err != nil {
			logger.Error("Error updating task: %v", err)
		}

	case api.NotifyOpDeviceUpdate:
		d.handleDeviceUpdate(&message)

	case api.NotifyOpVersionUpdate:
		d.handleVersionUpdate(&message)

	case api.NotifyOpSoftwareUpdate:
		logger.Info("[Delegate] Processing NotifyOpSoftwareUpdate from node %s", message.Node)
		d.handleSoftwareUpdate(&message)

	case api.NotifyOpSoftwareUpdateAvailable:
		d.handleSoftwareUpdateAvailable(&message)

	case api.NotifyOpSoftwareUpdateSyncAck:
		d.handleSoftwareUpdateSyncAck(&message)

	case api.NotifyOpSoftwareUpdateProgress:
		logger.Debug("[Delegate] Processing NotifyOpSoftwareUpdateProgress from node %s", message.Node)
		d.handleSoftwareUpdateProgress(&message)

	default:
		logger.Error("Unknown message type: %q", message.Operation)
	}
}

func (d *ClusterDelegate) GetBroadcasts(overhead, limit int) [][]byte {
	return nil
}

// handleDeviceUpdate processes device update notifications
func (d *ClusterDelegate) handleDeviceUpdate(message *api.NotifyMessage) {
	logger := logging.GetLogger()

	if message.DeviceInfo == nil {
		logger.Error("DeviceUpdate message with nil payload from %s", message.Node)
		return
	}

	logger.Info("[DeviceUpdate] Received device update from %s for device %s",
		message.Node, message.DeviceInfo.Id)

	d.hub.BroadcastToClusterObservers(message)
}

func (d *ClusterDelegate) handleVersionUpdate(message *api.NotifyMessage) {
	logger := logging.GetLogger()

	if message.VersionUpdate == nil {
		logger.Error("VersionUpdate message with nil payload from %s", message.Node)
		return
	}

	localMetadata, err := d.persistence.GetDatabaseMetadata()
	if err != nil {
		logger.Error("Failed to load local database metadata while handling version update from %s: %v", message.Node, err)
		return
	}

	remote := message.VersionUpdate
	localVersion := localMetadata.Version
	remoteVersion := remote.Version

	if localMetadata.Hash == remote.Hash {
		logger.Debug("[DATA] Ignoring version update from %s: hash already matches (%s)", message.Node, remote.Hash)
		return
	}

	d.versionState.mu.Lock()
	if d.versionState.seen == nil {
		d.versionState.seen = make(map[string]api.VersionUpdate)
	}
	if last, ok := d.versionState.seen[message.Node]; ok && last.Version == remote.Version && last.Hash == remote.Hash {
		d.versionState.mu.Unlock()
		logger.Debug("[DATA] Ignoring duplicate version update from %s (hash=%s version=%v)", message.Node, remote.Hash, remoteVersion)
		return
	}
	d.versionState.seen[message.Node] = *remote
	d.versionState.mu.Unlock()

	if !d.stateManager.TriggerDataRepair(fmt.Sprintf("gossip metadata update from %s", message.Node)) {
		logger.Debug("[DATA] Suppressing version update from %s while repair is already in flight or cooling down", message.Node)
		return
	}

	diffSummary := d.describeVersionUpdateDiff(message.Node)

	switch {
	case localVersion.Less(remoteVersion):
		logger.Warn("[DATA] Observed newer metadata from %s (local hash=%s version=%v, remote hash=%s version=%v); triggering repair. Diff: %s",
			message.Node, localMetadata.Hash, localVersion, remote.Hash, remoteVersion, diffSummary)
	case remoteVersion.Less(localVersion):
		logger.Warn("[DATA] Observed stale metadata from %s (local hash=%s version=%v, remote hash=%s version=%v); triggering repair. Diff: %s",
			message.Node, localMetadata.Hash, localVersion, remote.Hash, remoteVersion, diffSummary)
	default:
		logger.Warn("[DATA] Observed divergent metadata from %s at the same version %v (local hash=%s remote hash=%s); triggering repair. Diff: %s",
			message.Node, localVersion, localMetadata.Hash, remote.Hash, diffSummary)
	}
}

func (d *ClusterDelegate) describeVersionUpdateDiff(nodeName string) string {
	ml := d.stateManager.GetMemberList()
	if ml == nil {
		return "memberlist unavailable"
	}

	var targetAddr string
	for _, member := range ml.Members() {
		if member.Name == nodeName {
			targetAddr = member.Addr.String()
			break
		}
	}
	if targetAddr == "" {
		return fmt.Sprintf("member %s not found", nodeName)
	}

	url := utils.BuildInternalURL(targetAddr, api.AdminPort, routes.DataEndpoint)
	resp, err := d.stateManager.HTTPClient().Get(url)
	if err != nil {
		return fmt.Sprintf("failed to fetch remote data: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 1024))
		return fmt.Sprintf("remote data export returned %d: %s", resp.StatusCode, string(body))
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Sprintf("failed to read remote data body: %v", err)
	}

	var remoteData map[string]any
	if err := json.Unmarshal(body, &remoteData); err != nil {
		return fmt.Sprintf("failed to decode remote data export: %v", err)
	}

	return d.persistence.AntiEntropyDiffSummary(remoteData)
}

// handleSoftwareUpdate processes software update trigger notifications
func (d *ClusterDelegate) handleSoftwareUpdate(message *api.NotifyMessage) {
	logger := logging.GetLogger()

	logger.Info("[SoftwareUpdate] Received software update trigger from %s on node %s",
		message.Node, d.appConfig.NodeName)

	if out, err := exec.Command("systemctl", "reset-failed", "swupdate-ota-install.service").CombinedOutput(); err != nil {
		logger.Debug("[SoftwareUpdate] reset-failed (ignored): %v — %s", err, string(out))
	}

	cmd := exec.Command("systemctl", "start", "--no-block", "swupdate-ota-install.service")
	out, err := cmd.CombinedOutput()
	if err != nil {
		logger.Error("[SoftwareUpdate] Failed to start swupdate-ota-install.service on node %s: %v — %s",
			d.appConfig.NodeName, err, string(out))

		if d.hub != nil {
			d.hub.GossipSWUpdateFailure(d.appConfig.NodeName,
				fmt.Sprintf("failed to start swupdate-ota-install.service: %v — %s", err, string(out)))
		}
		return
	}

	logger.Info("[SoftwareUpdate] Successfully queued swupdate-ota-install.service on node %s",
		d.appConfig.NodeName)

	// Each node monitors its own /tmp/swupdateprog socket, stops any previous monitor, and resets progress for a clean start.
	if d.hub != nil {
		d.hub.StopSWUpdateProgressMonitoring()
		d.hub.StartSWUpdateProgressMonitoring()
		logger.Info("[SoftwareUpdate] Started local progress monitoring on node %s",
			d.appConfig.NodeName)
	}
}

// handleSoftwareUpdateAvailable processes bundle availability notifications from any node
func (d *ClusterDelegate) handleSoftwareUpdateAvailable(message *api.NotifyMessage) {
	logger := logging.GetLogger()

	logger.Info("[SoftwareUpdateAvailable] Processing software update notification from %s", message.Node)
	logger.Info("[SoftwareUpdateAvailable] Local node: %s, Message from: %s", d.appConfig.NodeName, message.Node)

	if message.SoftwareUpdate == nil {
		logger.Error("SoftwareUpdateAvailable message with nil payload from %s", message.Node)
		return
	}

	// Clean up any stale .swu files whose checksum differs from the incoming bundle.
	utils.CleanupStaleSwuFiles(api.SoftwareUpdateOTAPath, message.SoftwareUpdate.Checksum, logging.GetLogger())

	// Skip self-originated messages (uploader already has the file)
	if d.appConfig.NodeName == message.Node {
		logger.Info("[SoftwareUpdateAvailable] Ignoring self-originated software update notification from %s", message.Node)
		return
	}

	// Check if we already have this file
	finalPath := filepath.Join(api.SoftwareUpdateOTAPath, message.SoftwareUpdate.Filename)
	if _, err := os.Stat(finalPath); err == nil {
		// File exists, but we need to check if it's the same version
		logger.Info("[SoftwareUpdateAvailable] File %s exists locally, checking checksum", message.SoftwareUpdate.Filename)

		// Calculate checksum of existing file
		if existingChecksum, csErr := d.calculateFileChecksum(finalPath); csErr != nil {
			logger.Warn("[SoftwareUpdateAvailable] Could not checksum existing file %s: %v — proceeding with download", finalPath, csErr)
		} else if strings.EqualFold(existingChecksum, message.SoftwareUpdate.Checksum) {
			// Checksums match - we already have the correct file
			logger.Info("[SoftwareUpdateAvailable] File %s already up-to-date (checksum: %s), skipping download",
				message.SoftwareUpdate.Filename, existingChecksum)

			// Send acknowledgment if sync ID is provided since we already have the correct file
			if message.SoftwareUpdate.SyncID != "" {
				go func() {
					d.sendSyncAck(message.SoftwareUpdate.SyncID, message.SoftwareUpdate.Filename,
						message.SoftwareUpdate.Checksum, true, "")
				}()
			}
			return
		} else {
			// Checksums differ - need to download the new version
			logger.Info("[SoftwareUpdateAvailable] File %s exists but checksum differs (local: %s, remote: %s) — downloading update",
				message.SoftwareUpdate.Filename, existingChecksum, message.SoftwareUpdate.Checksum)
		}
	}

	// Trigger Software Update sync in background
	go func() {
		logger.Info("[SoftwareUpdateSync] Starting background sync for %s from %s",
			message.SoftwareUpdate.Filename, message.SoftwareUpdate.SourceIP)

		// // Add 10-second delay for testing
		// logger.Info("[SoftwareUpdateSync] Adding 30-second delay for testing purposes")
		// time.Sleep(30 * time.Second)
		// logger.Info("[SoftwareUpdateSync] Delay complete, starting actual sync")

		if err := d.persistence.SyncSoftwareUpdateFile(message.SoftwareUpdate); err != nil {
			logger.Error("[SoftwareUpdateSync] Failed to sync %s from %s: %v",
				message.SoftwareUpdate.Filename, message.SoftwareUpdate.SourceIP, err)

			// Send failure acknowledgment if sync ID is provided
			if message.SoftwareUpdate.SyncID != "" {
				d.sendSyncAck(message.SoftwareUpdate.SyncID, message.SoftwareUpdate.Filename,
					message.SoftwareUpdate.Checksum, false, err.Error())
			}
		} else {
			logger.Info("[SoftwareUpdateSync] Successfully synced %s from %s",
				message.SoftwareUpdate.Filename, message.SoftwareUpdate.SourceIP)

			// Send success acknowledgment if sync ID is provided
			if message.SoftwareUpdate.SyncID != "" {
				d.sendSyncAck(message.SoftwareUpdate.SyncID, message.SoftwareUpdate.Filename,
					message.SoftwareUpdate.Checksum, true, "")
			}
		}
	}()
}

func (d *ClusterDelegate) LocalState(join bool) []byte {

	logger := logging.GetLogger()
	logger.Debug("[DELEGATE] LocalState requested (join=%v)", join)

	state := d.stateManager.GetFullState()
	snapshot := struct {
		Version api.Version                `json:"version"`
		NodeID  string                     `json:"node_id"`
		State   map[string]*api.StateEntry `json:"state"`
	}{
		Version: d.stateManager.GetVersion(),
		NodeID:  d.appConfig.NodeName,
		State:   state.State,
	}

	data, err := json.Marshal(snapshot)
	if err != nil {
		logger.Error("Error marshaling local state: %v", err)
		return nil
	}

	logger.Debug("Providing local state with %d entries (version: %v)",
		len(state.State), snapshot.Version)

	if join {
		logger.Debug("[DELEGATE] LocalState provided with join true, size=%d", len(data))
	}
	return data
}

// MergeRemoteState merges remote state data
func (d *ClusterDelegate) MergeRemoteState(buf []byte, join bool) {
	if len(buf) == 0 {
		return
	}

	logger := logging.GetLogger()
	logger.Debug("[DELEGATE] MergeRemoteState called (join=%v, size=%d)", join, len(buf))

	var snapshot api.RemoteStateSnapshot
	if err := json.Unmarshal(buf, &snapshot); err != nil {
		logger.Error("[DELEGATE] Error unmarshaling remote state: %v", err)
		return
	}

	logger.Debug("[DELEGATE] Merging remote state from node %s with %d entries (version: %v)",
		snapshot.NodeID, len(snapshot.State), snapshot.Version)

	localVersion := d.stateManager.GetVersion()
	remoteVersion := snapshot.Version

	// Reject older epoch outright
	if remoteVersion.Epoch < localVersion.Epoch {
		logger.Debug("[DELEGATE] Ignoring remote state from older epoch %d (local=%d)", remoteVersion.Epoch, localVersion.Epoch)
		return
	}

	// Adopt newer epoch as authoritative
	if remoteVersion.Epoch > localVersion.Epoch {
		logger.Debug("[DELEGATE] Adopting newer epoch %d (local=%d)", remoteVersion.Epoch, localVersion.Epoch)
		d.stateManager.ReplaceFullState(snapshot.State, remoteVersion)
		d.persistence.MarkDirty()
		return
	}

	// Same epoch, do normal merge
	if d.stateManager.MergeRemoteState(snapshot.State) {
		d.persistence.MarkDirty()
	}

	if join {
		logger.Debug("[DELEGATE] MergeRemoteState completed during join")
	}
}

func (d *ClusterDelegate) handleAudioRemove(update *api.AudioRemoveUpdate) error {
	return d.persistence.RemoveAudioFile(update.ID)
}

func (d *ClusterDelegate) handleAudioSync(update *api.AudioSyncUpdate) error {
	return d.persistence.SyncAudioFile(update)
}

func (d *ClusterDelegate) startSkewPruner() {

	go func() {
		ticker := time.NewTicker(skewPruneInterval)
		defer ticker.Stop()
		d.skewStore.Prune(ticker, skewPruneAge)
	}()
}

// handleSoftwareUpdateSyncAck processes software update sync acknowledgments
func (d *ClusterDelegate) handleSoftwareUpdateSyncAck(message *api.NotifyMessage) {
	logger := logging.GetLogger()

	if message.SoftwareUpdateAck == nil {
		logger.Error("SoftwareUpdateSyncAck message with nil payload from %s", message.Node)
		return
	}

	logger.Info("[SoftwareUpdateSyncAck] Received sync acknowledgment from %s for file %s (sync ID: %s)",
		message.Node, message.SoftwareUpdateAck.Filename, message.SoftwareUpdateAck.SyncID)

	if d.handler != nil {
		d.handler.HandleSyncAck(message.Node, message.SoftwareUpdateAck)
	} else {
		logger.Warn("[SoftwareUpdateSyncAck] No sync handler configured - ignoring acknowledgment")
	}
}

// handleSoftwareUpdateProgress processes software update progress messages
func (d *ClusterDelegate) handleSoftwareUpdateProgress(message *api.NotifyMessage) {
	logger := logging.GetLogger()

	if message.SoftwareUpdateProgress == nil {
		logger.Error("SoftwareUpdateProgress message with nil payload from %s", message.Node)
		return
	}

	logger.Debug("[SoftwareUpdateProgress] Received progress from %s: %s %d%% (step %d/%d)",
		message.Node,
		message.SoftwareUpdateProgress.Status,
		message.SoftwareUpdateProgress.CurPercent,
		message.SoftwareUpdateProgress.CurStep,
		message.SoftwareUpdateProgress.NSteps)

	// Forward to Hub for aggregation and WebSocket broadcasting
	if d.hub != nil {
		if err := d.hub.BroadcastToNodes(message); err != nil {
			logger.Error("Failed to forward progress message to Hub: %v", err)
		}
	} else {
		logger.Warn("[SoftwareUpdateProgress] No Hub configured - ignoring progress message")
	}
}

// sendSyncAck sends an acknowledgment message back to the cluster after sync completion
func (d *ClusterDelegate) sendSyncAck(syncID, filename, checksum string, success bool, errorMsg string) {
	logger := logging.GetLogger()

	ack := &api.SoftwareUpdateSyncAck{
		Filename: filename,
		Checksum: checksum,
		SyncedAt: time.Now().UTC(),
		SyncID:   syncID,
		Success:  success,
		ErrorMsg: errorMsg,
	}

	msg := api.NewNotifyMessage(
		api.NotifyOpSoftwareUpdateSyncAck,
		d.appConfig.NodeName,
		api.WithSoftwareUpdateAck(ack),
	)

	if err := d.hub.BroadcastToNodes(msg); err != nil {
		logger.Error("[SoftwareUpdateSyncAck] Failed to broadcast sync acknowledgment: %v", err)
	} else {
		logger.Info("[SoftwareUpdateSyncAck] Sent acknowledgment for %s (success: %v, sync ID: %s)",
			filename, success, syncID)
	}
}

// calculateFileChecksum calculates the SHA256 checksum of a file
func (d *ClusterDelegate) calculateFileChecksum(filePath string) (string, error) {
	return utils.FileChecksum(filePath)
}
