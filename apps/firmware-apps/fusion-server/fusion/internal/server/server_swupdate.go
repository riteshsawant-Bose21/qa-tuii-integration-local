package server

import (
	"fmt"
	"net/http"
	"os"
	"time"

	"fusion-services-core/logging"
	"fusion/internal/api"
	model "fusion/internal/gen/proto/fusion"
	"fusion/internal/utils"

	json "github.com/goccy/go-json"
)

// GetLocalSwUpdateInfo handles GET requests for the local /etc/swupdate contents.
func (s *FusionServer) GetLocalSwUpdateInfo(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	var info model.SwUpdateInfo
	data, err := os.ReadFile(api.SwUpdateInfoPath)
	if err != nil {
		logging.GetLogger().Error("Failed to read %s: %v", api.SwUpdateInfoPath, err)
	} else if err := json.Unmarshal(data, &info); err != nil {
		logging.GetLogger().Error("Failed to parse %s: %v", api.SwUpdateInfoPath, err)
	}

<<<<<<< HEAD
	if err := writeProtoJSON(w, swUpdateInfoToProto(info)); err != nil {
=======
	if err := writeProtoJSON(w, &info); err != nil {
>>>>>>> gene/value
		logging.GetLogger().Error("Error encoding sw update info: %v", err)
	}
}

func swUpdateInfoToProto(info api.SwUpdateInfo) *model.SwUpdateInfo {
	return &model.SwUpdateInfo{
		SerialNumber:          info.SerialNumber,
		CurrentBundleVersion:  info.CurrentBundleVersion,
		PreviousBundleVersion: info.PreviousBundleVersion,
		Mount:                 info.Mount,
		PreviousMount:         info.PreviousMount,
		Status:                info.Status,
		CurrentState:          info.CurrentState,
		BootPartition:         info.BootPartition,
		PreviousBootPartition: info.PreviousBootPartition,
		Error:                 info.Error,
		UpdatedAt:             info.UpdatedAt,
	}
}

func (s *FusionServer) broadcastSoftwareUpdateProgress(message *api.NotifyMessage) error {
	if message.SoftwareUpdateProgressAll == nil && message.SoftwareUpdateProgress == nil {
		return nil
	}

	broadcastMessage := websocketResponse(nil, api.WSMsgTypeUpdateProgress, api.WSCodeDeviceUpdated, api.WSStatusEvent, fmt.Sprintf("System notification: %s", message.Operation), formatSoftwareUpdateProgress(message))
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
