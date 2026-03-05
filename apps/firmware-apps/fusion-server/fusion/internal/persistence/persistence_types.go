package persistence

import (
	"fusion/internal/api"
	"time"
)

// DeviceInfo represents device configuration data.
type DeviceInfo struct {
	Address       string `json:"address"`
	Id            string `json:"id"`
	Location      string `json:"location"`
	Name          string `json:"name"`
	XYTECloudID   string `json:"xyte_cloud_id"`
	IsClaimed     bool   `json:"is_claimed"`
	SerialNumber  string `json:"serial_number"`
	IsPrimaryNode bool   `json:"is_primary"`
}

// DevicePatch represents patchable device configuration data.
type DevicePatch struct {
	Id          *string `json:"id,omitempty"`
	Location    *string `json:"location,omitempty"`
	Name        *string `json:"name,omitempty"`
	XYTECloudID *string `json:"xyte_cloud_id,omitempty"`
	IsClaimed   *bool   `json:"is_claimed,omitempty"`
}

// PersistentState represents the saved state structure.
type PersistentState struct {
	Version   api.Version                `json:"version"`
	Timestamp time.Time                  `json:"timestamp"`
	Checksum  string                     `json:"checksum"`
	State     map[string]*api.StateEntry `json:"state"`
}

// RebootSource indicates how a reboot was initiated.
type RebootSource string

const (
	// RebootSourceLocal indicates reboot was triggered locally (e.g., via API or manual).
	RebootSourceLocal RebootSource = "LOCAL"
	// RebootSourceRemoteCommand indicates reboot was triggered via MQTT command.
	RebootSourceRemoteCommand RebootSource = "REMOTE_COMMAND"
)

// PendingCommandStatus represents the status of a pending command.
type PendingCommandStatus string

const (
	// PendingCommandStatusPending indicates the command is pending execution.
	PendingCommandStatusPending PendingCommandStatus = "PENDING"
	// PendingCommandStatusCompleted indicates the command has been completed.
	PendingCommandStatusCompleted PendingCommandStatus = "COMPLETED"
	// PendingCommandStatusFailed indicates the command failed.
	PendingCommandStatusFailed PendingCommandStatus = "FAILED"
)

// PendingCommand represents a command that is pending completion (e.g., after reboot).
type PendingCommand struct {
	ID          string               `json:"id"`
	CommandType string               `json:"command_type"`
	Status      PendingCommandStatus `json:"status"`
	Source      RebootSource         `json:"source"`
	ProjectID   string               `json:"project_id"`
	DeviceID    string               `json:"device_id"`
	CreatedAt   time.Time            `json:"created_at"`
	CompletedAt *time.Time           `json:"completed_at,omitempty"`
	ErrorMsg    string               `json:"error_msg,omitempty"`
}
