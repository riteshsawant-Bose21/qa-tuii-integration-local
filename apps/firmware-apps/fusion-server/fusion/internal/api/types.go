package api

import "time"

// DataUpdate represents a data update in the system
type ConfigUpdate struct {
	Data    map[string]interface{} `json:"data"`
	Version int64                  `json:"version"`
	NodeID  string                 `json:"node_id"`
	Time    time.Time              `json:"timestamp"`
	Clear   bool
}

// VolumeUpdate represents a volume change update
type VolumeUpdate struct {
	Channel int     `json:"channel"`
	Volume  float64 `json:"volume"`
}

// StateEntry represents a single entry in the state
type StateEntry struct {
	Data      interface{} `json:"data"`
	Version   int64       `json:"version"`
	Timestamp time.Time   `json:"timestamp"`
}
