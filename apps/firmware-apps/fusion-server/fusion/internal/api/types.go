package api

import "time"

// ConfigUpdate represents a data update in the system
type ConfigUpdate struct {
	Data    map[string]any `json:"data"`
	Version int64          `json:"version"`
	NodeID  string         `json:"node_id"`
	Time    time.Time      `json:"timestamp"`
	Clear   bool
}

// VolumeUpdate represents a volume change update
type VolumeUpdate struct {
	Channel int     `json:"channel"`
	Volume  float64 `json:"volume"`
}

// StateEntry represents a single entry in the state
type StateEntry struct {
	Data      any       `json:"data"`
	Version   int64     `json:"version"`
	Timestamp time.Time `json:"timestamp"`
}

// RawState represents raw state data element
type RawState struct {
	State map[string]*StateEntry `json:"state"`
}
