package api

import (
	model "fusion/internal/gen/proto/fusion"
)

// AudioRemoveUpdate represents an audio file to remove across nodes.
type AudioRemoveUpdate struct {
	ID string `json:"id"`
}

// AudioSyncUpdate represents an audio file to sync across nodes.
type AudioSyncUpdate struct {
	Metadata *model.AudioMetadata `json:"metadata"`
	URL      string               `json:"url"`
}

type MessageTrigger struct {
	ID        string   `json:"id"`
	Path      string   `json:"path"`
	Priority  int      `json:"priority,omitempty"`
	Zones     []string `json:"zones"`
	Timestamp int64    `json:"timestamp"`
}
