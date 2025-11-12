package api

import (
	"fmt"
	"time"

	json "github.com/goccy/go-json"

	"github.com/hashicorp/memberlist"
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

func (a *AppConfig) SelfUrl() string {
	return fmt.Sprintf("http://%s:%s", a.BindAddr, HTTPPort)
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

// AudioMetadata represents the persisted audio metadata.
type AudioMetadata struct {
	Id          string        `json:"id"`
	OrigName    string        `json:"orig_name"`
	DisplayName string        `json:"display_name"`
	Filename    string        `json:"filename"`
	MimeType    string        `json:"mime_type"`
	Uploaded    time.Time     `json:"uploaded"`
	Duration    time.Duration `json:"duration,omitempty"`
	SizeBytes   int64         `json:"size_bytes"`
	Tags        []string      `json:"tags"`
	Checksum    string        `json:"checksum"`
}

// AudioSyncUpdate represents an audio file to remove across nodes
type AudioRemoveUpdate struct {
	ID string `json:"id"`
}

// AudioSyncUpdate represents an audio file to sync across nodes
type AudioSyncUpdate struct {
	Metadata AudioMetadata `json:"metadata"`
	URL      string        `json:"url"`
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

// ControllerInfo represents a generic hardware controller
type ControllerInfo struct {
	ID      string `json:"id"`
	Name    string `json:"name"`
	Address string `json:"address"`
	Version string `json:"version,omitempty"`
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

// RemoteStateSnapshot is what we send/receive during anti-entropy.
type RemoteStateSnapshot struct {
	Version Version                `json:"version"`
	NodeID  string                 `json:"node_id"`
	State   map[string]*StateEntry `json:"state"`
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
	TaskTypeMessage  TaskType = "message"
	TaskTypeSnapshot TaskType = "snapshot"
)

// Task represents a task
type Task struct {
	ID          string         `json:"id"`
	Description string         `json:"description"`
	CronExpr    string         `json:"cron_expr"`
	Enabled     bool           `json:"active"`
	Type        TaskType       `json:"type"`
	Params      map[string]any `json:"params"`
	CronEntryID cron.EntryID   `json:"-"`
}

// TaskMessage represents a message playback task
type TaskMessage struct {
	ID          string `json:"id"`
	MessageID   string `json:"message_id"`
	Description string `json:"description"`
	CronExpr    string `json:"cron_expr"`
}

// TaskSnapshopPatch represents a patchable snapshot task
type TaskSnapshopPatch struct {
	Description *string `json:"description,omitempty"`
	CronExpr    *string `json:"cron_expr,omitempty"`
	Snapshot    *string `json:"snapshot,omitempty"`
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
