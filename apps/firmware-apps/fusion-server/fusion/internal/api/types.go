package api

import (
	"encoding/json"
	"time"

	"github.com/hashicorp/memberlist"
)

// ConfigUpdate represents a data update in the system
type ConfigUpdate struct {
	Data    map[string]any `json:"data"`
	Version int64          `json:"version"`
	Time    time.Time      `json:"timestamp"`
	Clear   bool
}

// Endpoints contains the REST API endpoint information
type Endpoints struct {
	API       string   `json:"api"`
	Telemetry []string `json:"telemetry"`
	Metrics   string   `json:"metrics"`
}

// SnapshotMetadata holds metadata information from the database.
type SnapshotMetadata struct {
	ActiveSnapshot string    `json:"active_snapshot"`
	Timestamp      time.Time `json:"timestamp"`
	DBHash         string    `json:"hash"`
	Valid          bool      `json:"valid"`
}

// SnapshotMemberMetadata tie a member to its snapshot metadata.
type SnapshotMemberMetadata struct {
	Member   *memberlist.Node
	Metadata SnapshotMetadata
}

// SnapshotUpdate represents a snapshot update operation broadcast across the cluster.
type SnapshotUpdate struct {
	Name      string         `json:"name"`
	Data      map[string]any `json:"data,omitempty"`
	Timestamp time.Time      `json:"timestamp"`
}

// RawState represents raw state data element
type RawState struct {
	State map[string]*StateEntry `json:"state"`
}

// StateEntry represents a single entry in the state
type StateEntry struct {
	Data      any       `json:"data"`
	Version   int64     `json:"version"`
	Timestamp time.Time `json:"timestamp"`
}

type VersionMessage struct {
	Type    string          `json:"type"`
	Payload json.RawMessage `json:"payload"`
}

// NotifyOp is a custom type representing notification message operations.
type NotifyOp string

const (
	NotifyOpConfigUpdate  NotifyOp = "config_update"
	NotifyOpSnapActivate  NotifyOp = "snapshot_activate"
	NotifyOpSnapCreate    NotifyOp = "snapshot_create"
	NotifyOpSnapDelete    NotifyOp = "snapshot_delete"
	NotifyOpSnapImport    NotifyOp = "snapshot_import"
	NotifyOpVersionUpdate NotifyOp = "version_update"
)

// NotifyMessage holds information about a cross-node message
type NotifyMessage struct {
	Operation      NotifyOp
	Node           string
	ConfigUpdate   *ConfigUpdate
	SnapshotUpdate *SnapshotUpdate
	VersionMessage *VersionMessage
}
