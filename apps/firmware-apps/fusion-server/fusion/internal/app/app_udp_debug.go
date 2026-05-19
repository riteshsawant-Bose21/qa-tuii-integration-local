package app

import (
	"net/http"

	model "fusion/internal/gen/proto/fusion"
	"fusion/internal/utils"
)

func (app *App) HandleUDPStatus(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}
	if !app.config.UDPDiagnostics {
		http.NotFound(w, r)
		return
	}

	stats := app.UDPServer.Stats()
	resp := &model.UDPDebugStats{
		QueueDepth:            uint32(stats.QueueDepth),
		QueueCapacity:         uint32(stats.QueueCapacity),
		MaxQueueDepth:         stats.MaxQueueDepth,
		RegisteredClients:     uint32(stats.RegisteredClients),
		PendingBroadcasts:     uint32(stats.PendingBroadcasts),
		OldestPendingAgeMs:    stats.OldestPendingAgeMs,
		EnqueuedPackets:       stats.EnqueuedPackets,
		DroppedPackets:        stats.DroppedPackets,
		HandledPackets:        stats.HandledPackets,
		AckPackets:            stats.AckPackets,
		ResponsesSent:         stats.ResponsesSent,
		BroadcastMessages:     stats.BroadcastMessages,
		BroadcastDatagrams:    stats.BroadcastDatagrams,
		LastBroadcastEpoch:    stats.LastBroadcastEpoch,
		LastBroadcastVersion:  stats.LastBroadcastVersion,
		LastBroadcastSentAtNs: stats.LastBroadcastSentAt,
		MaintenanceEnabled:    stats.MaintenanceEnabled,
	}
	if err := writeProtoJSON(w, resp); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}
