package handler

import (
	"fmt"
	"fusion/internal/api"
	"fusion/internal/controllers"
	"fusion/internal/persistence"
	"fusion/internal/pubsub"
	"fusion/internal/utils"
	"fusion/internal/version"
	"reflect"
	"sync"

	json "github.com/goccy/go-json"

	"github.com/hashicorp/memberlist"
)

// DeviceInfoProvider defines interface for getting and updating device information
type DeviceInfoProvider interface {
	GetAllDeviceInfos() []persistence.DeviceInfo
	UpdateDeviceInfoForWebSocket(deviceID string, patch *persistence.DevicePatch) error
}

// Handler is the container for server implimentations.
type Handler struct {
	appConfig      *api.AppConfig
	memberlist     *memberlist.Memberlist
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
	memberlist *memberlist.Memberlist,
	persistence *persistence.Persistence,
	stateManager *persistence.StateManager,
	hub *pubsub.Hub,
	controllerManager controllers.ControllerManagerInterface,
) *Handler {
	return &Handler{
		appConfig:         appConfig,
		memberlist:        memberlist,
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

func (h *Handler) SetMemberlist(memberlist *memberlist.Memberlist) {
	h.memberlist = memberlist
}

func (h *Handler) GetInitialState() (map[string]any, error) {
	data := h.StateManager.GetStateMap()
	return data, nil
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

	configUpdate, snapshots, sceneSets, err := h.SplitFeaturePayload(update)
	if err != nil {
		return nil, err
	}

	if err := h.persistFeatureDefinitions(snapshots, sceneSets); err != nil {
		return nil, err
	}

	isSnapshotSceneDefProvided := len(snapshots) > 0 || len(sceneSets) > 0
	isConfigKeysAbsent := len(configUpdate) == 0

	if isConfigKeysAbsent {
		// Snapshot keys only in the json
		if isSnapshotSceneDefProvided {
			return setResponse{
				Status:  "success",
				Updates: nil,
			}, nil
		}
		// No keys at all in the json??
		return setResponse{
			Status:  "noop",
			Updates: nil,
		}, nil
	}

	existing := h.StateManager.GetStateMap()

	if reflect.DeepEqual(existing, configUpdate) {
		if isSnapshotSceneDefProvided {
			return setResponse{
				Status:  "success",
				Updates: nil,
			}, nil
		}
		return setResponse{
			Status:  "noop",
			Updates: nil,
		}, nil
	}

	if err := h.handleConfigUpdate(configUpdate, true); err != nil {
		return nil, err
	}

	return setResponse{
		Status:  "success",
		Updates: configUpdate,
	}, nil
}

// HandleHTTPPatch updates only the specified fields.
func (h *Handler) HandleHTTPPatch(patch map[string]any) (map[string]any, error) {
	configPatch, snapshots, sceneSets, err := h.SplitFeaturePayload(patch)
	if err != nil {
		return nil, err
	}

	if err := h.persistFeatureDefinitions(snapshots, sceneSets); err != nil {
		return nil, err
	}

	featureUpdated := len(snapshots) > 0 || len(sceneSets) > 0
	if len(configPatch) == 0 {
		if featureUpdated {
			return map[string]any{}, nil
		}
		return nil, nil
	}

	// Get full state before PATCH
	before := h.StateManager.GetStateMap()

	// Apply internal patch
	afterPtr, err := h.StateManager.Patch(configPatch)
	if err != nil {
		return nil, err
	}

	// No changes
	if afterPtr == nil {
		if featureUpdated {
			return map[string]any{}, nil
		}
		return nil, nil
	}

	after := *afterPtr

	diff := utils.CalculateDiff(before, after)

	if err := h.handleConfigUpdate(after, false); err != nil {
		return nil, err
	}

	return diff, nil
}

func (h *Handler) persistFeatureDefinitions(snapshots []api.SnapshotDefinition, sceneSets []api.SceneSet) error {
	if len(snapshots) > 0 {
		if err := h.persistence.UpsertSnapshotDefinitions(snapshots); err != nil {
			return err
		}
	}

	if len(sceneSets) > 0 {
		if err := h.persistence.UpsertSceneSets(sceneSets); err != nil {
			return err
		}
	}

	return nil
}

func (h *Handler) SplitFeaturePayload(update map[string]any) (
	config map[string]any,
	snapshots []api.SnapshotDefinition,
	sceneSets []api.SceneSet,
	err error,
) {
	config = make(map[string]any, len(update))

	for key, value := range update {
		switch key {
		case "snapshots":
			raw, marshalErr := json.Marshal(value)
			if marshalErr != nil {
				return nil, nil, nil, fmt.Errorf("invalid snapshots payload: %w", marshalErr)
			}
			if unmarshalErr := json.Unmarshal(raw, &snapshots); unmarshalErr != nil {
				return nil, nil, nil, fmt.Errorf("invalid snapshots payload: %w", unmarshalErr)
			}
		case "scene_sets":
			raw, marshalErr := json.Marshal(value)
			if marshalErr != nil {
				return nil, nil, nil, fmt.Errorf("invalid scene_sets payload: %w", marshalErr)
			}
			if unmarshalErr := json.Unmarshal(raw, &sceneSets); unmarshalErr != nil {
				return nil, nil, nil, fmt.Errorf("invalid scene_sets payload: %w", unmarshalErr)
			}
		default:
			config[key] = value
		}
	}

	return config, snapshots, sceneSets, nil
}

func (h *Handler) HandleClearAllData() error {

	if err := h.handleConfigUpdate(map[string]any{}, true); err != nil {
		return err
	}

	return nil
}

func (h *Handler) GetMembers() []*memberlist.Node {
	return h.memberlist.Members()
}

func (h *Handler) GetServerInfo() (any, error) {
	info := serverInfoResponse{
		Name:        "Fusion Server",
		Version:     version.Version,
		Commit:      version.Commit,
		BuildTime:   version.BuildTime,
		NodeID:      h.memberlist.LocalNode().Name,
		Endpoints:   h.endpoints,
		ClusterSize: len(h.memberlist.Members()),
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
		h.memberlist.LocalNode().Name,
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
