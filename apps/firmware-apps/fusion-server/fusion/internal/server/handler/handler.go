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
	"reflect"
	"sync"

	"github.com/hashicorp/memberlist"
)

// DeviceInfoProvider defines interface for getting and updating device information
type DeviceInfoProvider interface {
	GetAllDeviceInfos() []persistence.DeviceInfo
	UpdateDeviceInfoForWebSocket(deviceID string, patch *persistence.DevicePatch) error
}

// Handler is the container for server implementations.
type Handler struct {
	appConfig        *api.AppConfig
	clusterTransport transport.ClusterTransport

	persistence    *persistence.Persistence
	StateManager   *persistence.StateManager
	hub            *pubsub.Hub
	endpoints      []string
	deviceProvider DeviceInfoProvider // Provides device info using same logic as REST API

	sessions     map[string]*SAPSession
	sessionsLock sync.RWMutex

	controllerManager controllers.ControllerManagerInterface
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
	clusterTransport transport.ClusterTransport,
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
	}
}

func (h *Handler) SetEndpoints(endpoints []string) {
	h.endpoints = endpoints
}

func (h *Handler) GetInitialState() (map[string]any, error) {
	data := h.StateManager.GetStateMap()
	return data, nil
}

func (h *Handler) SetClusterTransport(clusterTransport transport.ClusterTransport) {
	h.clusterTransport = clusterTransport
}

func (h *Handler) HandleHTTPGet(key string) (any, error) {
	type keyLookupResponse struct {
		Exists bool `json:"exists"`
		Value  any  `json:"value,omitempty"`
		Error  any  `json:"error,omitempty"`
	}

	if key != "" {
		value, exists := h.StateManager.Get(key)
		if !exists {
			return keyLookupResponse{
				Exists: false,
				Error:  "key not found",
			}, nil
		}
		return keyLookupResponse{
			Exists: true,
			Value:  value,
		}, nil
	}

	state := h.StateManager.GetStateMap()
	return state, nil
}

// HandleHTTPSet replaces the entire configuration state with the new data.
func (h *Handler) HandleHTTPSet(update map[string]any) (any, error) {
	type setResponse struct {
		Status  string         `json:"status"`
		Updates map[string]any `json:"updates"`
	}

	existing := h.StateManager.GetStateMap()

	if reflect.DeepEqual(existing, update) {
		return setResponse{
			Status:  "noop",
			Updates: nil,
		}, nil
	}

	if err := h.handleConfigUpdate(update, true); err != nil {
		return nil, err
	}

	return setResponse{
		Status:  "success",
		Updates: update,
	}, nil
}

// HandleHTTPPatch updates only the specified fields.
func (h *Handler) HandleHTTPPatch(patch map[string]any) (map[string]any, error) {

	// Get full state before PATCH
	before := h.StateManager.GetStateMap()

	// Apply internal patch
	afterPtr, err := h.StateManager.Patch(patch)
	if err != nil {
		return nil, err
	}

	// No changes
	if afterPtr == nil {
		return nil, nil
	}

	after := *afterPtr

	diff := utils.CalculateDiff(before, after)

	if err := h.handleConfigUpdate(after, false); err != nil {
		return nil, err
	}

	return diff, nil
}

func (h *Handler) HandleClearAllData() error {

	if err := h.handleConfigUpdate(map[string]any{}, true); err != nil {
		return err
	}

	return nil
}

func (h *Handler) GetMembers() []*memberlist.Node {
	return h.clusterTransport.Members()
}

func (h *Handler) GetServerInfo() (any, error) {
	info := serverInfoResponse{
		Name:        "Fusion Server",
		Version:     version.Version,
		Commit:      version.Commit,
		BuildTime:   version.BuildTime,
		NodeID:      h.clusterTransport.LocalNode().Name,
		Endpoints:   h.endpoints,
		ClusterSize: len(h.clusterTransport.Members()),
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

// SetDeviceProvider sets the device info provider
func (h *Handler) SetDeviceProvider(provider DeviceInfoProvider) {
	h.deviceProvider = provider
}
