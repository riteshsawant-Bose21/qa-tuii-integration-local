package handler

import (
	"fmt"
	"fusion/internal/api"
	"fusion/internal/cluster/transport"
	"fusion/internal/controllers"
	"fusion/internal/persistence"
	"fusion/internal/pubsub"
	"fusion/internal/utils"
	"fusion/internal/version"
	"net/http"
	"sync"
	"time"

	"github.com/hashicorp/memberlist"
)

// Handler is the container for server implementations.
type Handler struct {
	appConfig        *api.AppConfig
	clusterTransport transport.ClusterInterface

	persistence  *persistence.Persistence
	StateManager *persistence.StateManager
	hub          *pubsub.Hub
	endpoints    []string

	sessions     map[string]*SAPSession
	sessionsLock sync.RWMutex

	controllerManager controllers.ControllerManagerInterface
	httpClient        *http.Client

	// Software update sync tracking
	syncTrackers     map[string]*api.SoftwareUpdateSyncTracker
	syncTrackersLock sync.RWMutex
}

type serverInfoResponse struct {
	Name        string   `json:"name"`
	Version     string   `json:"version"`
	Commit      string   `json:"commit"`
	BuildTime   string   `json:"build_time"`
	NodeID      string   `json:"node_id"`
	Endpoints   []string `json:"endpoints"`
	ClusterSize int      `json:"cluster_size"`
}

func NewHandler(
	appConfig *api.AppConfig,
	clusterTransport transport.ClusterInterface,
	persistence *persistence.Persistence,
	stateManager *persistence.StateManager,
	hub *pubsub.Hub,
	controllerManager controllers.ControllerManagerInterface,
) *Handler {
	return &Handler{
		appConfig:         appConfig,
		clusterTransport:  clusterTransport,
		persistence:       persistence,
		StateManager:      stateManager,
		hub:               hub,
		controllerManager: controllerManager,
		sessions:          make(map[string]*SAPSession),
		httpClient:        &http.Client{Timeout: api.HTTPTimeout},
		syncTrackers:      make(map[string]*api.SoftwareUpdateSyncTracker),
	}
}

func (h *Handler) SetEndpoints(endpoints []string) {
	h.endpoints = endpoints
}

func (h *Handler) GetInitialState() (map[string]any, error) {
	data := h.StateManager.GetStateMap()
	return data, nil
}

func (h *Handler) SetClusterTransport(clusterTransport transport.ClusterInterface) {
	h.clusterTransport = clusterTransport
}

// HandleHTTPPatch updates only the specified fields.
func (h *Handler) HandleHTTPPatch(patch map[string]any) (map[string]any, error) {

	// Get full state before PATCH
	before := h.StateManager.GetStateMap()
	after, ok := utils.DeepCopy(before).(map[string]any)
	if !ok {
		return nil, fmt.Errorf("failed to copy state for patch")
	}

	// Apply the patch to a copy, then replicate the resulting authoritative snapshot once.
	if err := utils.ApplyPatch(after, patch); err != nil {
		return nil, err
	}

	diff := utils.CalculateDiff(before, after)
	if diff == nil {
		return nil, nil
	}

	if err := h.handleConfigUpdate(after, false); err != nil {
		return nil, err
	}

	return diff, nil
}

func (h *Handler) GetMembers() []*memberlist.Node {
	return h.clusterTransport.MemberListMembers()
}

func (h *Handler) GetServerInfo() (any, error) {
	info := serverInfoResponse{
		Name:        "Fusion Server",
		Version:     version.Version,
		Commit:      version.Commit,
		BuildTime:   version.BuildTime,
		NodeID:      h.clusterTransport.LocalNode().Name,
		Endpoints:   h.endpoints,
		ClusterSize: len(h.clusterTransport.MemberListMembers()),
	}

	return info, nil
}

// HandleImportData imports a batch of data
func (h *Handler) HandleImportData(data map[string]any) error {
	if err := h.persistence.ImportData(data); err != nil {
		return fmt.Errorf("failed to import data: %w", err)
	}
	return nil
}

// HandleExportData exports all data
func (h *Handler) HandleExportData() (any, error) {
	return h.persistence.ExportData()
}

func (h *Handler) handleConfigUpdate(data map[string]any, clear bool) error {

	configUpdate, err := h.StateManager.NewConfigUpdate(data)
	if err != nil {
		return err
	}
	configUpdate.Clear = clear

	if _, err := h.StateManager.ApplyUpdate(*configUpdate); err != nil {
		return fmt.Errorf("failed to apply local config update: %w", err)
	}

	message := api.NewNotifyMessage(
		api.NotifyOpConfigUpdate,
		h.clusterTransport.LocalNode().Name,
		api.WithConfigUpdate(configUpdate),
	)

	if err := h.hub.BroadcastToNodes(message); err != nil {
		return fmt.Errorf("failed to broadcast config update: %w", err)
	}

	return nil
}

// Software Update Sync Tracking Methods

// StartSyncTracking creates a new sync tracker for a software update operation
func (h *Handler) StartSyncTracking(syncID, filename, checksum string, expectedNodes []string, timeout time.Duration) *api.SoftwareUpdateSyncTracker {
	h.syncTrackersLock.Lock()
	defer h.syncTrackersLock.Unlock()

	// Create expected nodes map
	expectedNodesMap := make(map[string]bool)
	for _, node := range expectedNodes {
		expectedNodesMap[node] = false
	}

	tracker := &api.SoftwareUpdateSyncTracker{
		SyncID:        syncID,
		Filename:      filename,
		Checksum:      checksum,
		StartedAt:     time.Now(),
		ExpectedNodes: expectedNodesMap,
		CompletedCh:   make(chan bool, 1),
		TimeoutCh:     make(chan bool, 1),
	}

	h.syncTrackers[syncID] = tracker

	// Start timeout timer
	go func() {
		time.Sleep(timeout)
		select {
		case tracker.TimeoutCh <- true:
		default:
		}
	}()

	return tracker
}

// HandleSyncAck processes a sync acknowledgment from a cluster node
func (h *Handler) HandleSyncAck(nodeName string, ack *api.SoftwareUpdateSyncAck) {
	h.syncTrackersLock.Lock()
	defer h.syncTrackersLock.Unlock()

	tracker, exists := h.syncTrackers[ack.SyncID]
	if !exists {
		return // Tracker not found or already completed
	}

	// Mark this node as acknowledged
	if _, expected := tracker.ExpectedNodes[nodeName]; expected {
		tracker.ExpectedNodes[nodeName] = true
	}

	// Check if all nodes have acknowledged
	allAcked := true
	for _, acked := range tracker.ExpectedNodes {
		if !acked {
			allAcked = false
			break
		}
	}

	if allAcked {
		select {
		case tracker.CompletedCh <- true:
		default:
		}
		delete(h.syncTrackers, ack.SyncID)
	}
}

// WaitForSyncCompletion waits for either all nodes to acknowledge or timeout
func (h *Handler) WaitForSyncCompletion(syncID string) (bool, error) {
	h.syncTrackersLock.RLock()
	tracker, exists := h.syncTrackers[syncID]
	h.syncTrackersLock.RUnlock()

	if !exists {
		return false, fmt.Errorf("sync tracker not found for ID: %s", syncID)
	}

	select {
	case <-tracker.CompletedCh:
		return true, nil // All nodes acknowledged
	case <-tracker.TimeoutCh:
		// Clean up the tracker on timeout
		h.syncTrackersLock.Lock()
		delete(h.syncTrackers, syncID)
		h.syncTrackersLock.Unlock()
		return false, fmt.Errorf("sync operation timed out")
	}
}
