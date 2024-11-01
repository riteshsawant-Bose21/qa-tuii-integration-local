package api

import (
	"time"
)

// ConfigUpdate represents a configuration update in the system
type ConfigUpdate struct {
	Key     string      `json:"key"`
	Value   interface{} `json:"value"`
	Version int64       `json:"version"`
	NodeID  string      `json:"node_id"`
	Time    time.Time   `json:"timestamp"`
}

// VolumeUpdate represents a volume change update
type VolumeUpdate struct {
	Channel int     `json:"channel"`
	Volume  float64 `json:"volume"`
}

// StateEntry represents a single entry in the state
type StateEntry struct {
	Value     interface{} `json:"value"`
	Version   int64       `json:"version"`
	NodeID    string      `json:"node_id"`
	Timestamp time.Time   `json:"timestamp"`
}

// ClusterState represents the complete state of the cluster
type ClusterState struct {
	Version int64                 `json:"version"`
	Entries map[string]StateEntry `json:"entries"`
}
