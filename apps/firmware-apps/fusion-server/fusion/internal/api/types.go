package api

import (
	"fmt"
	model "fusion/internal/gen/proto/fusion"
	"time"

	json "github.com/goccy/go-json"

	"github.com/hashicorp/memberlist"
	"github.com/robfig/cron/v3"
)

// AppConfig represents application configuration data
type AppConfig struct {
	NodeName       string
	BindAddr       string
	BindPort       int
	NetIface       string
	Local          bool
	Profile        bool
	UDPDiagnostics bool
	Verbose        bool
}

func (a *AppConfig) SelfUrl() string {
	return fmt.Sprintf("http://%s:%s", a.BindAddr, HTTPPort)
}

// Version encodes a Lamport counter plus the origin node's ID.
// https://en.wikipedia.org/wiki/Lamport_timestamp
type Version struct {
	Epoch   uint64 `json:"epoch"`
	Counter uint64 `json:"counter"`
	NodeID  string `json:"node_id"`
}

// Compare returns true if v is less than the other.
func (v Version) Less(other Version) bool {
	if v.Epoch != other.Epoch {
		return v.Epoch < other.Epoch
	}

	if v.Counter != other.Counter {
		return v.Counter < other.Counter
	}

	return v.NodeID < other.NodeID
}

// AudioRemoveUpdate represents an audio file to remove across nodes
type AudioRemoveUpdate struct {
	ID string `json:"id"`
}

// AudioSyncUpdate represents an audio file to sync across nodes
type AudioSyncUpdate struct {
	Metadata *model.AudioMetadata `json:"metadata"`
	URL      string               `json:"url"`
}

// SoftwareUpdateSyncAck carries acknowledgment information when a node
// successfully completes syncing a software update bundle.
type SoftwareUpdateSyncAck struct {
	Filename string    `json:"filename"`
	Checksum string    `json:"checksum"`
	SyncedAt time.Time `json:"synced_at"`
	SyncID   string    `json:"sync_id"` // Unique ID to track this sync operation
	Success  bool      `json:"success"`
	ErrorMsg string    `json:"error_msg,omitempty"`
}

// SoftwareUpdateSyncTracker tracks the status of a cluster-wide software update sync
type SoftwareUpdateSyncTracker struct {
	SyncID        string          `json:"sync_id"`
	Filename      string          `json:"filename"`
	Checksum      string          `json:"checksum"`
	StartedAt     time.Time       `json:"started_at"`
	ExpectedNodes map[string]bool `json:"expected_nodes"` // node_name -> acknowledged
	CompletedCh   chan bool       `json:"-"`              // Channel to signal completion
	TimeoutCh     chan bool       `json:"-"`              // Channel for timeout
}

// SWUpdateStatus represents the RECOVERY_STATUS enum values from SWUpdate.
type SWUpdateStatus int32

// SoftwareUpdateProgress represents real-time progress information from SWUpdate
type SoftwareUpdateProgress struct {
	NodeName     string         `json:"node_name"`
	APIVersion   uint32         `json:"api_version"`
	Status       SWUpdateStatus `json:"status"`                  // RECOVERY_STATUS enum
	Source       int32          `json:"source"`                  // sourcetype enum
	DwlPercent   uint32         `json:"dwl_percent"`             // Download percentage
	DwlBytes     uint64         `json:"dwl_bytes"`               // Download bytes
	NSteps       uint32         `json:"n_steps"`                 // Total number of steps
	CurStep      uint32         `json:"cur_step"`                // Current step number
	CurPercent   uint32         `json:"cur_percent"`             // Current step percentage
	CurImage     string         `json:"cur_image"`               // Current image name
	HndName      string         `json:"hnd_name"`                // Handler name
	Info         string         `json:"info,omitempty"`          // Optional info message
	SerialNumber string         `json:"serial_number,omitempty"` // API v2.1.0+ (string to preserve uint64 precision)
	Timestamp    time.Time      `json:"timestamp"`               // When this progress was captured
}

// VersionUpdate represents version information to sync across nodes
type VersionUpdate struct {
	Version Version `json:"version"`
	Hash    string  `json:"hash"`
	NodeID  string  `json:"node_id"`
}

// ConfigUpdate represents a full or partial snapshot of state for a top-level key.
//
//   - ConfigUpdate is a replication primitive used by memberlist to achieve
//     eventual consistency with Lamport ordering.
//
//   - ConfigUpdate.Data does not behave like a PATCH. It is not a partial,
//     deep-merge update. Instead:
//
//     Each top-level entry in Data is considered a complete authoritative
//     snapshot for that key.
//
//     That means:
//
//     ConfigUpdate{Data: {"config": {"param2": "updated"}}}
//
//     replaces the entire "config" entry on receivers.
//
//   - Partial/deep/nested updates must use the HTTP PATCH system, which applies
//     rich semantics (array index updates, nested map merges, deletes, diffs).
//
// In short:
//
//	PATCH  = mutating local configuration with nested semantics
//	POST/PUT = full replacement
//	ConfigUpdate = replication of authoritative state snapshots across nodes.
//
// This separation keeps replication simple and Lamport-correct, while PATCH
// provides advanced local update semantics.
type ConfigUpdate struct {
	Hash         string         `json:"hash"`
	Data         map[string]any `json:"data"`
	ObserverData map[string]any `json:"observer_data,omitempty"`
	Version      Version        `json:"version"`
	Clear        bool           `json:"clear,omitempty"`
}

// ConfigValue represents a key/value pair
type ConfigValue struct {
	Key   string          `json:"key"`
	Value json.RawMessage `json:"value,omitempty"`
}

// DeviceRuntimeInfo extends the public device contract with internal build and
// VRRP metadata. Public API and cluster notification paths should prefer
// model.DeviceInfo directly.
type DeviceRuntimeInfo struct {
	model.DeviceInfo
	FusionMonorepoBranch     string `json:"fusion_monorepo_branch,omitempty"`
	FusionMonorepoCommitHash string `json:"fusion_monorepo_commit_hash,omitempty"`
	JenkinsBuildNumber       string `json:"jenkins_build_number,omitempty"`
	PreReleaseTag            string `json:"pre_release_tag,omitempty"`
	VrrpPriority             int    `json:"vrrp_priority"`
}

// MemberMetadata associates a member to its database metadata.
type MemberMetadata struct {
	Member   *memberlist.Node
	Metadata model.DatabaseMetadata
}

// RecurringWindow contains info to manage recurring tasks
type RecurringWindow struct {
	StartTime string `json:"start_time"` // HH:MM in local time
	EndTime   string `json:"end_time"`   // HH:MM in local time
	Days      []int  `json:"days"`       // 0=Sun ... 6=Sat
}

// RemoteStateSnapshot is what we send/receive during anti-entropy.
type RemoteStateSnapshot struct {
	Version Version                `json:"version"`
	NodeID  string                 `json:"node_id"`
	State   map[string]*StateEntry `json:"state"`
}

// SnapshotOperation represents a snapshot operation broadcast across the cluster.
type SnapshotOperation struct {
	Name      string    `json:"name"`
	Timestamp time.Time `json:"timestamp"`
}

// SceneSetOperation represents a scene-set operation broadcast across the cluster.
type SceneSetOperation struct {
	SetID     string    `json:"set_id"`
	Timestamp time.Time `json:"timestamp"`
}

// SceneOperation represents a scene operation broadcast across the cluster.
type SceneOperation struct {
	SceneID   string    `json:"scene_id"`
	Timestamp time.Time `json:"timestamp"`
}

// ActivateSnapshotRequest is the request body for snapshot activation.
type ActivateSnapshotRequest struct {
	ID string `json:"id"`
}

// ActivateSceneSetRequest is the request body for scene activation in a set.
type ActivateSceneSetRequest struct {
	SetID   string `json:"set_id"`
	SceneID string `json:"scene_id"`
}

// TaskType represents scheduled task
type TaskType string

const (
	TaskTypeMessage       TaskType = "message"
	TaskTypeSnapshot      TaskType = "snapshot"
	TaskTypeSceneSnapshot TaskType = "scene_snapshot"
	TaskTypeSceneActivate TaskType = "scene_activate"
)

// Task represents a task
type Task struct {
	ID          string           `json:"id"`
	Description string           `json:"description"`
	Type        TaskType         `json:"type"`
	CronExpr    string           `json:"cron_expr"`
	StartAt     time.Time        `json:"start_at"`
	EndAt       time.Time        `json:"end_at"`
	Recurrence  *RecurringWindow `json:"recurrence,omitempty"`
	Params      map[string]any   `json:"params"`
	Enabled     bool             `json:"enabled"`
	CronEntryID cron.EntryID     `json:"-"`
}

// StateEntry represents a single entry in the state
type StateEntry struct {
	Data    any     `json:"data"`
	Version Version `json:"version"`
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

// StatusMessage contains fusion status information
type StatusMessage struct {
	VIP string `json:"vip"`
}

// WebSocketStats represents connection and usage statistics
type WebSocketStats struct {
	Connections    int              `json:"connections"`                // Active connections
	Messages       int64            `json:"messages"`                   // Total messages processed
	Errors         int64            `json:"errors"`                     // Total errors
	Uptime         time.Duration    `json:"uptime"`                     // Server uptime
	LastReset      time.Time        `json:"last_reset"`                 // Stats last reset
	MessagesByType map[string]int64 `json:"messages_by_type,omitempty"` // Messages by type
}

// SoftwareUpdateProgressResponse is the JSON body for software update progress events.
type SoftwareUpdateProgressResponse struct {
	UpdateState  string `json:"update_state"`
	Step         string `json:"step"`
	CurrentTask  string `json:"current_task"`
	Progress     string `json:"progress"`
	Node         string `json:"node"`
	Handler      string `json:"handler"`
	Timestamp    string `json:"timestamp"`
	SerialNumber string `json:"serial_number,omitempty"`
}
type SoftwareUpdateInfo struct {
	BuildConfiguration struct {
		SoftwareUpdateBundleVersion string `json:"FIRMWARE_BUNDLE_VERSION"`
		FusionMonorepoBranch        string `json:"FUSION_MONOREPO_BRANCH"`
		FusionMonorepoCommitHash    string `json:"FUSION_MONOREPO_COMMIT_HASH"`
		JenkinsBuildNumber          string `json:"JENKINS_BUILD_NUMBER"`
		PreReleaseTag               string `json:"PRE_RELEASE_TAG"`
	} `json:"build_configuration"`
}

type MessageTrigger struct {
	ID        string   `json:"id"`
	Path      string   `json:"path"`
	Priority  int      `json:"priority,omitempty"`
	Zones     []string `json:"zones"`
	Timestamp int64    `json:"timestamp"`
}

// SetModelNameRequest is the request body for POST /manufacturing/model-name.
// ModelName must be one of the accepted values: c1-evk, powersmart, fm6, fm8y, xlr-pal, blue-pal, som.
type SetModelNameRequest struct {
	ModelName string `json:"model_name"`
}
