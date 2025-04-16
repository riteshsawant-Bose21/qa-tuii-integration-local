package api

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"time"

	"github.com/hashicorp/memberlist"
	"github.com/robfig/cron/v3"
)

// AppConfig represents application configuration data
type AppConfig struct {
	NodeName string
	BindAddr string
	BindPort int
	Verbose  bool
}

// ConfigUpdate represents a data update in the system
type ConfigUpdate struct {
	Hash    string         `json:"hash"`
	Data    map[string]any `json:"data"`
	Version int64          `json:"version"`
	Time    time.Time      `json:"timestamp"`
	Clear   bool
}

// NewConfigUpdate returns a configured ConfigUpdate
func NewConfigUpdate(data map[string]any) (*ConfigUpdate, error) {

	hash, err := hashConfigData(data)
	if err != nil {
		return nil, fmt.Errorf("failed to generate hash: %w", err)
	}

	return &ConfigUpdate{
		Hash:    hash,
		Data:    data,
		Version: time.Now().UnixNano(),
		Time:    time.Now().UTC(),
		Clear:   false,
	}, nil
}

// Endpoints contains the REST API endpoint information
type Endpoints struct {
	API       string   `json:"api"`
	Telemetry []string `json:"telemetry"`
}

// DatabaseMetadata holds metadata information from the database.
type DatabaseMetadata struct {
	Timestamp      time.Time `json:"timestamp"`
	ActiveSnapshot string    `json:"active_snapshot"`
	Hash           string    `json:"hash"`
	Valid          bool      `json:"valid"`
}

// MemberMetadata associates a member to its database metadata.
type MemberMetadata struct {
	Member   *memberlist.Node
	Metadata DatabaseMetadata
}

// SnapshotUpdate represents a snapshot update operation broadcast across the cluster.
type SnapshotUpdate struct {
	Name      string         `json:"name"`
	Data      map[string]any `json:"data,omitempty"`
	Timestamp time.Time      `json:"timestamp"`
}

// Task represents a task with a unique ID, a cron expression, and a function to execute.
type Task struct {
	ID          string `json:"id"`
	CronExpr    string `json:"cron_expr"`
	Description string `json:"description"`
	EntryID     cron.EntryID
	SnapshotID  string `json:"snapshot_id"`
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
	NotifyOpTaskCreate    NotifyOp = "task_create"
	NotifyOpTaskDelete    NotifyOp = "task_delete"
	NotifyOpTaskUpdate    NotifyOp = "task_update"
	NotifyOpVersionUpdate NotifyOp = "version_update"
)

// NotifyMessage holds information about a cross-node message
type NotifyMessage struct {
	Operation      NotifyOp
	Node           string
	ConfigUpdate   *ConfigUpdate
	SnapshotUpdate *SnapshotUpdate
	Task           *Task
	VersionMessage *VersionMessage
}

// hashConfigData generates a SHA-256 hash of the Data field of a ConfigUpdate
func hashConfigData(data map[string]any) (string, error) {
	// Marshal the map to JSON to ensure consistent hashing
	jsonData, err := json.Marshal(data)
	if err != nil {
		return "", err
	}

	hash := sha256.Sum256(jsonData)
	return hex.EncodeToString(hash[:]), nil
}
