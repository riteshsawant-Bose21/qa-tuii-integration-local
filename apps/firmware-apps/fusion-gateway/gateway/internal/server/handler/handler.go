package handler

import (
	"gateway/internal/api"
)

// Handler is the container for server implimentations.
type Handler struct {
	appConfig *api.AppConfig
	endpoints []string
}

func NewHandler(appConfig *api.AppConfig) *Handler {
	return &Handler{
		appConfig: appConfig,
	}
}

func (h *Handler) SetEndpoints(endpoints []string) {
	h.endpoints = endpoints
}

func (h *Handler) HandleHTTPGet(key string) (any, error) {
	return nil, nil
}

func (h *Handler) HandleHTTPSet(update map[string]any) (any, error) {
	return nil, nil
}

func (h *Handler) HandleHTTPPatch(patch map[string]any) (map[string]any, error) {
	return nil, nil
}

func (h *Handler) HandleClearAllData() error {
	return nil
}
