package handler

import (
	"fusion/internal/api"
)

const (
	maxFormSize    = 32 << 20  // 32MB
	maxUploadBytes = 100 << 20 // 100MB
)

// handleAudioSync syncs an audio file binary between nodes
func (h *Handler) handleAudioSync(update *api.AudioSyncUpdate) error {
	return h.persistence.SyncAudioFile(update)
}
