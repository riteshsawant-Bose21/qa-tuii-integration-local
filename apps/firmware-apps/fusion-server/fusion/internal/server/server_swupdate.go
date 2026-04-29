package server

import (
	"fmt"
	"net/http"
	"os"
	"time"

	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/utils"

	json "github.com/goccy/go-json"
)

// GetLocalSwUpdateInfo handles GET requests for the local /etc/swupdate contents.
func (s *FusionServer) GetLocalSwUpdateInfo(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	var info api.SwUpdateInfo
	data, err := os.ReadFile(api.SwUpdateInfoPath)
	if err != nil {
		logging.GetLogger().Error("Failed to read %s: %v", api.SwUpdateInfoPath, err)
	} else if err := json.Unmarshal(data, &info); err != nil {
		logging.GetLogger().Error("Failed to parse %s: %v", api.SwUpdateInfoPath, err)
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	if err := json.NewEncoder(w).Encode(info); err != nil {
		logging.GetLogger().Error("Error encoding sw update info: %v", err)
	}
}

func (s *FusionServer) broadcastSoftwareUpdateProgress(message *api.NotifyMessage) error {
	if message.SoftwareUpdateProgressAll == nil && message.SoftwareUpdateProgress == nil {
		return nil
	}

	broadcastMessage := &api.WebSocketResponse{
		ID:        nil,
		Version:   api.WSCurrentVersion,
		Type:      api.WSMsgTypeUpdateProgress,
		Code:      api.WSCodeDeviceUpdated,
		Status:    api.WSStatusEvent,
		Message:   fmt.Sprintf("System notification: %s", message.Operation),
		Data:      formatSoftwareUpdateProgress(message),
		Timestamp: time.Now(),
	}
	return s.broadcastToAllClients(broadcastMessage)
}

func formatSoftwareUpdateProgress(message *api.NotifyMessage) map[string]api.SoftwareUpdateProgressResponse {
	nodesProgress := make(map[string]api.SoftwareUpdateProgressResponse)
	if message.SoftwareUpdateProgressAll != nil {
		for nodeName, progress := range message.SoftwareUpdateProgressAll {
			nodesProgress[nodeName] = softwareUpdateProgressResponse(progress)
		}
		return nodesProgress
	}

	// Fallback: single node (e.g. local-only, no cluster)
	progress := message.SoftwareUpdateProgress
	nodesProgress[progress.NodeName] = softwareUpdateProgressResponse(progress)
	return nodesProgress
}

func softwareUpdateProgressResponse(progress *api.SoftwareUpdateProgress) api.SoftwareUpdateProgressResponse {
	return api.SoftwareUpdateProgressResponse{
		UpdateState:  progress.Status.String(),
		Step:         fmt.Sprintf("%d/%d", progress.CurStep, progress.NSteps),
		CurrentTask:  progress.CurImage,
		Progress:     fmt.Sprintf("%d", progress.CurPercent),
		Node:         progress.NodeName,
		Handler:      progress.HndName,
		Timestamp:    progress.Timestamp.Format(time.RFC3339),
		SerialNumber: progress.SerialNumber,
	}
}
