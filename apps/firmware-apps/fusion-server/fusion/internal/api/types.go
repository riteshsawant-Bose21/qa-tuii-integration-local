package api

import (
	"errors"
	"time"

	json "github.com/goccy/go-json"

	"github.com/hashicorp/memberlist"
	"github.com/oklog/ulid/v2"
	"github.com/robfig/cron/v3"
)

// AppConfig represents application configuration data
type AppConfig struct {
	NodeName string
	BindAddr string
	BindPort int
	NetIface string
	Local    bool
	Profile  bool
	Verbose  bool
}

// Version encodes a Lamport counter plus the origin node's ID.
// https://en.wikipedia.org/wiki/Lamport_timestamp
type Version struct {
	Counter int64  `json:"counter"`
	NodeID  string `json:"node_id"`
}

// Compare returns true if v is less than the other.
func (v Version) Less(other Version) bool {
	if v.Counter != other.Counter {
		return v.Counter < other.Counter
	}
	return v.NodeID < other.NodeID
}

// ConfigUpdate represents a data update in the system
type ConfigUpdate struct {
	Hash    string         `json:"hash"`
	Data    map[string]any `json:"data"`
	Version Version        `json:"version"`
	Clear   bool           `json:"clear,omitempty"`
}

// ConfigValue represents a key/value pair
type ConfigValue struct {
	Key   string          `json:"key"`
	Value json.RawMessage `json:"value,omitempty"`
}

// DatabaseMetadata holds metadata information from the database.
type DatabaseMetadata struct {
	Version        Version `json:"version"`
	ActiveSnapshot string  `json:"active_snapshot"`
	Hash           string  `json:"hash"`
	Valid          bool    `json:"valid"`
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

// TaskType represents scheduled task
type TaskType string

const (
	TaskTypeSnapshot      TaskType = "snapshot"
	TaskTypeAudioPlayback TaskType = "audio_playback"
)

// Task represents a task
type Task struct {
	ID          string            `json:"id"`
	Description string            `json:"description"`
	CronExpr    string            `json:"cron_expr"`
	Enabled     bool              `json:"active"`
	Type        TaskType          `json:"type"`
	Params      map[string]string `json:"params"`
	CronEntryID cron.EntryID      `json:"-"`
}

// RemoteStateSnapshot is what we send/receive during anti-entropy.
type RemoteStateSnapshot struct {
	Version Version                `json:"version"`
	NodeID  string                 `json:"node_id"`
	State   map[string]*StateEntry `json:"state"`
}

// StateEntry represents a single entry in the state
type StateEntry struct {
	Data    any     `json:"data"`
	Version Version `json:"version"`
}

// StatusMessage contains fusion status information
type StatusMessage struct {
	VIP string `json:"vip"`
}

// VersionUpdate contains the version update type and data
type VersionUpdate struct {
	Type    string          `json:"type"`
	Payload json.RawMessage `json:"payload"`
}

// NotifyOp is a custom type representing notification message operations.
type NotifyOp string

const (
	NotifyOpAck           NotifyOp = "ack"
	NotifyOpConfigUpdate  NotifyOp = "config_update"
	NotifyOpSnapActivate  NotifyOp = "snapshot_activate"
	NotifyOpSnapCreate    NotifyOp = "snapshot_create"
	NotifyOpSnapDelete    NotifyOp = "snapshot_delete"
	NotifyOpTaskCreate    NotifyOp = "task_create"
	NotifyOpTaskDelete    NotifyOp = "task_delete"
	NotifyOpTaskUpdate    NotifyOp = "task_update"
	NotifyOpVIPStatus     NotifyOp = "vip_status"
	NotifyOpValueGet      NotifyOp = "get"
	NotifyOpValueSet      NotifyOp = "set"
	NotifyOpVersionUpdate NotifyOp = "version_update"
)

// NotifyMessage holds information about a cross-node message
type NotifyMessage struct {
	ID             string   `json:"id"`
	Operation      NotifyOp `json:"operation"`
	Node           string
	SentAt         time.Time
	ConfigUpdate   *ConfigUpdate
	ConfigValue    *ConfigValue
	SnapshotUpdate *SnapshotUpdate
	Task           *Task
	VersionUpdate  *VersionUpdate
}

func NewNotifyMessage(op NotifyOp, node string, builder func(*NotifyMessage)) *NotifyMessage {
	msg := &NotifyMessage{
		ID:        ulid.Make().String(),
		Operation: op,
		Node:      node,
		SentAt:    time.Now().UTC(),
	}

	builder(msg)

	return msg
}

func (m *NotifyMessage) Validate() error {
	switch m.Operation {

	case NotifyOpConfigUpdate:
		if m.ConfigUpdate == nil {
			return errors.New("ConfigUpdate required for update operation")
		}

	case NotifyOpTaskCreate, NotifyOpTaskDelete, NotifyOpTaskUpdate:
		if m.Task == nil {
			return errors.New("Task required for task operation")
		}

	case NotifyOpSnapActivate, NotifyOpSnapCreate, NotifyOpSnapDelete:
		if m.SnapshotUpdate == nil {
			return errors.New("SnapshotUpdate required for snapshot operation")
		}

	case NotifyOpValueGet, NotifyOpValueSet:
		if m.ConfigValue == nil {
			return errors.New("ConfigValue required for value operation")
		}

	case NotifyOpVersionUpdate:
		if m.VersionUpdate == nil {
			return errors.New("VersionUpdate required for update operation")
		}
	}

	// NotifyOpAck           NotifyOp = "ack"
	// NotifyOpVIPStatus     NotifyOp = "vip_status"

	return nil
}

func (msg *NotifyMessage) IsPublic() bool {
	return msg.Operation == NotifyOpConfigUpdate ||
		msg.Operation == NotifyOpAck ||
		msg.Operation == NotifyOpVIPStatus
}

func WithConfigUpdate(cfg *ConfigUpdate) func(*NotifyMessage) {
	return func(m *NotifyMessage) {
		m.ConfigUpdate = cfg
	}
}

func WithSnapshotUpdate(snap *SnapshotUpdate) func(*NotifyMessage) {
	return func(m *NotifyMessage) {
		m.SnapshotUpdate = snap
	}
}

func WithTask(task *Task) func(*NotifyMessage) {
	return func(m *NotifyMessage) {
		m.Task = task
	}
}

func WithVersionUpdate(ver *VersionUpdate) func(*NotifyMessage) {
	return func(m *NotifyMessage) {
		m.VersionUpdate = ver
	}
}
