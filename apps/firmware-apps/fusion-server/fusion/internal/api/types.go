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

// SnapshotOp is a custom type representing snapshot operations.
type SnapshotOp string

const (
	SnapshotOpCreate   SnapshotOp = "create"
	SnapshotOpDelete   SnapshotOp = "delete"
	SnapshotOpActivate SnapshotOp = "activate"
)

// SnapshotMetadata holds metadata information from the database.
type SnapshotMetadata struct {
	ActiveSnapshot string    `json:"active_snapshot"`
	Timestamp      time.Time `json:"timestamp"`
	DBHash         string    `json:"hash"`
}

// SnapshotUpdate represents a snapshot update operation broadcast across the cluster.
type SnapshotUpdate struct {
	Op        SnapshotOp     `json:"op"`
	Name      string         `json:"name"`
	Data      map[string]any `json:"data,omitempty"`
	Node      string         `json:"node"`
	Timestamp time.Time      `json:"timestamp"`
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
