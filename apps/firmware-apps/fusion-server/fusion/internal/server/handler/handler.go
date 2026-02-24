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

	"github.com/hashicorp/memberlist"
)

// Handler is the container for server implimentations.
type Handler struct {
	appConfig    *api.AppConfig
	memberlist   *memberlist.Memberlist
	persistence  *persistence.Persistence
	StateManager *persistence.StateManager
	hub          *pubsub.Hub
	endpoints    []string

	sessions     map[string]*SAPSession
	sessionsLock sync.RWMutex

	controllerManager controllers.ControllerManagerInterface
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

func (h *Handler) GetInitialState() (WebSocketResponse, error) {
	data := h.StateManager.GetStateMap()
	return WebSocketResponse{
		Type: "initial_state",
		Data: data,
	}, nil
}

func (h *Handler) HandleHTTPGet(key string) (any, error) {
	if key != "" {
		value, exists := h.StateManager.Get(key)
		if !exists {
			return map[string]any{
				"exists": false,
				"error":  "key not found",
			}, nil
		}
		return map[string]any{
			"exists": true,
			"value":  value,
		}, nil
	}

	state := h.StateManager.GetStateMap()
	return state, nil
}

// HandleHTTPSet replaces the entire configuration state with the new data.
func (h *Handler) HandleHTTPSet(update map[string]any) (any, error) {

	existing := h.StateManager.GetStateMap()

	if reflect.DeepEqual(existing, update) {
		return map[string]any{"status": "noop", "updates": nil}, nil
	}

	if err := h.handleConfigUpdate(update, true); err != nil {
		return nil, err
	}

	return map[string]any{"status": "success", "updates": update}, nil
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
	return h.memberlist.Members()
}

func (h *Handler) GetServerInfo() (map[string]any, error) {
	info := map[string]any{
		"name":       "Fusion Server",
		"version":    version.Version,
		"commit":     version.Commit,
		"build_time": version.BuildTime, "node_id": h.memberlist.LocalNode().Name,
		"endpoints":    h.endpoints,
		"cluster_size": len(h.memberlist.Members()),
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
