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

// MeterDataMessage is the telemetry payload routed from the telemetry core to
// WebSocket subscribers. Filtering is based on each sample's block_name.
type MeterDataMessage struct {
	MessageName string              `json:"message_name"`
	Parameters  MeterDataParameters `json:"parameters"`
}

type MeterDataParameters struct {
	Value []MeterDataSample `json:"value"`
}

type MeterDataSample struct {
	BlockName string         `json:"block_name"`
	Value     map[string]any `json:"value,omitempty"`
}

type MessageTrigger struct {
	ID        string   `json:"id"`
	Path      string   `json:"path"`
	Priority  int      `json:"priority,omitempty"`
	Zones     []string `json:"zones"`
	Timestamp int64    `json:"timestamp"`
}
