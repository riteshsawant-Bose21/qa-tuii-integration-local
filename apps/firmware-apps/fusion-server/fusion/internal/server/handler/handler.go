package handler

import (
	"fmt"
	"fusion/internal/api"
	"fusion/internal/persistence"
	"fusion/internal/utils"
	"fusion/internal/version"

	"github.com/hashicorp/memberlist"
)

// Handler is the container for server implimentations.
type Handler struct {
	broadcasters []Broadcaster
	updater      *Updater
	endpoints    []string
	Memberlist   *memberlist.Memberlist
	persistence  *persistence.Persistence
	StateManager *persistence.StateManager
}

func NewHandler(memberlist *memberlist.Memberlist, persistence *persistence.Persistence, stateManager *persistence.StateManager, updater *Updater) *Handler {
	return &Handler{
		Memberlist:   memberlist,
		persistence:  persistence,
		StateManager: stateManager,
		updater:      updater,
	}
}

func (h *Handler) SetEndpoints(endpoints []string) {
	h.endpoints = endpoints
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
	// Clear all existing data before applying the update.
	h.HandleClearAllData()

	if err := h.handleConfigUpdate(update); err != nil {
		return nil, fmt.Errorf("failed to handle update: %w", err)
	}

	return map[string]any{
		"status":  "success",
		"updates": update,
	}, nil
}

// HandleHTTPPatch updates only the specified fields.
func (h *Handler) HandleHTTPPatch(value map[string]any) (any, error) {
	existingData := h.StateManager.GetStateMap()
	if err := utils.ApplyPatch(existingData, value); err != nil {
		return nil, fmt.Errorf("failed to apply patch: %w", err)
	}

	if err := h.handleConfigUpdate(existingData); err != nil {
		return nil, fmt.Errorf("failed to handle update after patch: %w", err)
	}

	return existingData, nil
}

func (h *Handler) HandleClearAllData() error {
	configUpdate, err := api.NewConfigUpdate(map[string]any{})
	if err != nil {
		return err
	}
	configUpdate.Clear = true

	message := api.NewNotifyMessage(api.NotifyOpConfigUpdate, h.StateManager.GetNode(),
		api.WithConfigUpdate(configUpdate),
	)

	if err := h.broadcastUpdate(message); err != nil {
		return fmt.Errorf("failed to clear all data: %w", err)
	}

	if err := h.persistence.SaveState(); err != nil {
		return fmt.Errorf("failed to persist cleared state: %w", err)
	}
	return nil
}

func (h *Handler) GetServerInfo() (map[string]any, error) {
	info := map[string]any{
		"name":       "Fusion Server",
		"version":    version.Version,
		"commit":     version.Commit,
		"build_time": version.BuildTime, "node_id": h.Memberlist.LocalNode().Name,
		"endpoints":          h.endpoints,
		"cluster_size":       len(h.Memberlist.Members()),
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

func (h *Handler) handleConfigUpdate(data map[string]any) error {

	configUpdate, err := api.NewConfigUpdate(data)
	if err != nil {
		return err
	}

	message := api.NewNotifyMessage(api.NotifyOpConfigUpdate, h.StateManager.GetNode(),
		api.WithConfigUpdate(configUpdate),
	)

	return h.broadcastUpdate(message)
}
