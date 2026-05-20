package api

import (
	"time"
)

// String implements fmt.Stringer for SWUpdateStatus.
func (s SWUpdateStatus) String() string {
	switch s {
	case SWUpdateStatusIdle:
		return "IDLE"
	case SWUpdateStatusStart:
		return "STARTING"
	case SWUpdateStatusRun:
		return "IN_PROGRESS"
	case SWUpdateStatusSuccess:
		return "SUCCESS"
	case SWUpdateStatusFailure:
		return "FAILED"
	case SWUpdateStatusDownload:
		return "DOWNLOADING"
	case SWUpdateStatusDone:
		return "COMPLETED"
	case SWUpdateStatusSubprocess:
		return "SUBPROCESS"
	case SWUpdateStatusProgress:
		return "PROGRESS"
	default:
		return "UNKNOWN"
	}
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

// SoftwareUpdateSyncTracker tracks the status of a cluster-wide software update sync.
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

// SoftwareUpdateProgress represents real-time progress information from SWUpdate.
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
		BuildNumber                 string `json:"JENKINS_BUILD_NUMBER"`
		PreReleaseTag               string `json:"PRE_RELEASE_TAG"`
	} `json:"build_configuration"`
}
