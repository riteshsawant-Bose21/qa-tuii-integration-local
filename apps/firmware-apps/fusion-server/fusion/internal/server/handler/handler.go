package handler

import (
	"fmt"
	"fusion/internal/api"
	"fusion/internal/controllers"
	"fusion/internal/persistence"
	"fusion/internal/pubsub"
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
	updater      *Updater
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
	updater *Updater,
	hub *pubsub.Hub,
	controllerManager controllers.ControllerManagerInterface,
) *Handler {
	return &Handler{
		appConfig:         appConfig,
		memberlist:        memberlist,
		persistence:       persistence,
		StateManager:      stateManager,
		updater:           updater,
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
func (h *Handler) HandleHTTPPatch(update map[string]any) (any, error) {

	patched, err := h.StateManager.Patch(update)
	if err != nil {
		return nil, err
	}

	if patched == nil {
		return nil, nil
	}

	configUpdate, err := h.StateManager.NewConfigUpdate(*patched)
	if err != nil {
		return nil, fmt.Errorf("failed to create config update: %w", err)
	}

	message := api.NewNotifyMessage(
		api.NotifyOpConfigUpdate,
		h.memberlist.LocalNode().Name,
		api.WithConfigUpdate(configUpdate),
	)

	if err := h.broadcastMessage(message); err != nil {
		return nil, fmt.Errorf("failed to broadcast patch update: %w", err)
	}

	return patched, nil
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
		"endpoints":          h.endpoints,
		"cluster_size":       len(h.memberlist.Members()),
		"update_in_progress": h.updater.currentUpdate != nil,
	}

	if h.updater.currentUpdate != nil {
		info["update_status"] = map[string]any{
			"source_node": h.updater.currentUpdate.NodeID,
			"time":        h.updater.currentUpdate.Time,
			"progress":    float64(h.updater.currentAssembler.received) / float64(h.updater.currentAssembler.size) * 100,
		}
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

	message := api.NewNotifyMessage(
		api.NotifyOpConfigUpdate,
		h.memberlist.LocalNode().Name,
		api.WithConfigUpdate(configUpdate),
	)

	return h.broadcastMessage(message)
}
