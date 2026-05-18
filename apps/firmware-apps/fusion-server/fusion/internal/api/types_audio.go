package api

import (
	model "fusion/internal/gen/proto/fusion"

	json "github.com/goccy/go-json"
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

// MeterDataMessage is the JSON envelope published by the telemetry core over ZMQ.
type MeterDataMessage struct {
	MessageName string              `json:"message_name"`
	DeviceID    string              `json:"device_id"`
	PacketID    uint64              `json:"packet_id"`
	Parameters  MeterDataParameters `json:"parameters"`
}

// MeterDataParameters holds the parameters section of a meter_data message.
type MeterDataParameters struct {
	Name   string            `json:"name"`
	Type   string            `json:"type"`
	Length int               `json:"length"`
	Value  []MeterDataSample `json:"value"`
}

// MeterDataSample represents a single meter measurement from the telemetry core.
type MeterDataSample struct {
	BlockName  string          `json:"block_name"`
	MeterName  string          `json:"meter_name"`
	ValueType  string          `json:"value_type"`
	Dimensions string          `json:"dimensions"`
	Value      json.RawMessage `json:"value"`
}

type MessageTrigger struct {
	ID        string   `json:"id"`
	Path      string   `json:"path"`
	Priority  int      `json:"priority,omitempty"`
	Zones     []string `json:"zones"`
	Timestamp int64    `json:"timestamp"`
}
