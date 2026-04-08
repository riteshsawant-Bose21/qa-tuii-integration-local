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

// AudioRemoveUpdate represents an audio file to remove across nodes
type AudioRemoveUpdate struct {
	ID string `json:"id"`
}

// AudioSyncUpdate represents an audio file to sync across nodes
type AudioSyncUpdate struct {
	Metadata AudioMetadata `json:"metadata"`
	URL      string        `json:"url"`
}

// SoftwareUpdateSync carries the metadata for a bundle that is
// available for followers to pull from the VIP node.
type SoftwareUpdateSync struct {
	Filename  string    `json:"filename"`
	Checksum  string    `json:"checksum"`
	SizeBytes int64     `json:"size_bytes"`
	Uploaded  time.Time `json:"uploaded"`
	SourceIP  string    `json:"source_ip"`
	SyncID    string    `json:"sync_id,omitempty"` // For tracking cluster-wide sync
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

// DeviceInfo represents device configuration data.
type DeviceInfo struct {
	Address                  string `json:"address"`
	Id                       string `json:"id"`
	Location                 string `json:"location"`
	Name                     string `json:"name"`
	ModelName                string `json:"model_name"`
	MacAddress               string `json:"mac_address"`
	SerialNumber             string `json:"serial_number"`
	IsPrimaryNode            bool   `json:"is_primary"`
	SoftwareUpdateVersion    string `json:"software_update_version"`
	IsDeviceCertificateValid bool   `json:"is_device_certificate_valid"`
	FusionMonorepoBranch     string `json:"fusion_monorepo_branch,omitempty"`
	FusionMonorepoCommitHash string `json:"fusion_monorepo_commit_hash,omitempty"`
	JenkinsBuildNumber       string `json:"jenkins_build_number,omitempty"`
}

// DevicePatch represents patchable device configuration data.
// When modifying this struct, please ensure to update validateNoDuplication, applyPatch
type DevicePatch struct {
	Id       *string `json:"id,omitempty"`
	Location *string `json:"location,omitempty"`
	Name     *string `json:"name,omitempty"`
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

// TaskType represents scheduled task
type TaskType string

const (
	TaskTypeMessage  TaskType = "message"
	TaskTypeSnapshot TaskType = "snapshot"
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

// TaskMessage represents a message playback task
type TaskMessage struct {
	ID          string           `json:"id"`
	Description string           `json:"description"`
	CronExpr    string           `json:"cron_expr"`
	StartAt     time.Time        `json:"start_at"`
	EndAt       time.Time        `json:"end_at"`
	Recurrence  *RecurringWindow `json:"recurrence,omitempty"`
	MessageID   string           `json:"message_id"`
	Priority    int64            `json:"priority"`
	Zones       string           `json:"zones"`
}

// TaskMessagePatch represents a patchable message task
type TaskMessagePatch struct {
	Description *string          `json:"description,omitempty"`
	CronExpr    *string          `json:"cron_expr,omitempty"`
	StartAt     *time.Time       `json:"start_at,omitempty"`
	EndAt       *time.Time       `json:"end_at,omitempty"`
	Recurrence  *RecurringWindow `json:"recurrence,omitempty"`
	MessageID   *string          `json:"message_id,omitempty"`
	Priority    *int64           `json:"priority"`
	Zones       *string          `json:"zones"`
}

// TaskSnapshopPatch represents a patchable snapshot task
type TaskSnapshopPatch struct {
	Description *string          `json:"description,omitempty"`
	CronExpr    *string          `json:"cron_expr,omitempty"`
	StartAt     *time.Time       `json:"start_at,omitempty"`
	EndAt       *time.Time       `json:"end_at,omitempty"`
	Recurrence  *RecurringWindow `json:"recurrence,omitempty"`
	Snapshot    *string          `json:"snapshot,omitempty"`
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

type ControllerTCPMessage struct {
	Action  string          `json:"action"`
	Payload json.RawMessage `json:"payload"`
}

type ControllerIdentifyResponse struct {
	ID              string `json:"id"`
	DeviceType      string `json:"deviceType"`
	FirmwareVersion string `json:"firmwareVersion"`
}

type ControllerWinkResponse struct {
	Status string `json:"status"`
}

// WebSocketRequest represents an incoming WebSocket request message
type WebSocketRequest struct {
	ID      string          `json:"id"`             // Unique request ID for response correlation
	Version int             `json:"version"`        // Protocol version (currently 1)
	Type    string          `json:"type"`           // Message type (devices, device_by_id, etc.)
	Data    json.RawMessage `json:"data,omitempty"` // Request payload
}

// WebSocketResponse represents an outgoing WebSocket response message
type WebSocketResponse struct {
	ID        *string   `json:"id"`        // Request ID for correlation (null for server push)
	Version   int       `json:"version"`   // Protocol version
	Type      string    `json:"type"`      // Response type
	Code      int       `json:"code"`      // Status code
	Status    string    `json:"status"`    // Status (success, error, event)
	Message   string    `json:"message"`   // Human-readable message
	Data      any       `json:"data"`      // Response payload (can be null)
	Timestamp time.Time `json:"timestamp"` // ISO 8601 timestamp
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

// SoftwareUpdateUploadResponse is the JSON body returned after a successful bundle upload.
type SoftwareUpdateUploadResponse struct {
	Filename  string    `json:"filename"`
	Checksum  string    `json:"checksum"`
	SizeBytes int64     `json:"size_bytes"`
	Uploaded  time.Time `json:"uploaded"`
}

// softwareUpdateErrorResponse is the JSON body returned on bundle upload errors.
type SoftwareUpdateErrorResponse struct {
	Error   string `json:"error"`
	Message string `json:"message,omitempty"`
}

type SoftwareUpdateInfo struct {
	BuildConfiguration struct {
		SoftwareUpdateBundleVersion string `json:"FIRMWARE_BUNDLE_VERSION"`
		FusionMonorepoBranch        string `json:"FUSION_MONOREPO_BRANCH"`
		FusionMonorepoCommitHash    string `json:"FUSION_MONOREPO_COMMIT_HASH"`
		JenkinsBuildNumber          string `json:"JENKINS_BUILD_NUMBER"`
	} `json:"build_configuration"`
}
