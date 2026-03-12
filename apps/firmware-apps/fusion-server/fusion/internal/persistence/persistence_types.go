package persistence

import (
	"fusion/internal/api"
	"time"
)

type DeviceInfo = api.DeviceInfo

// DevicePatch represents patchable device configuration data.
type DevicePatch struct {
	Id        *string `json:"id,omitempty"`
	Location  *string `json:"location,omitempty"`
	Name      *string `json:"name,omitempty"`
	ModelName *string `json:"model_name,omitempty"`
	IsClaimed *bool   `json:"is_claimed,omitempty"`
}

// PersistentState represents the saved state structure.
type PersistentState struct {
	Version   api.Version                `json:"version"`
	Timestamp time.Time                  `json:"timestamp"`
	Checksum  string                     `json:"checksum"`
	State     map[string]*api.StateEntry `json:"state"`
}

// CommandSource indicates how a command was initiated.
type CommandSource string

const (
	// CommandSourceLocal indicates command was triggered locally (e.g., via API locally or manual).
	CommandSourceLocal CommandSource = "LOCAL"
	// CommandSourceRemoteCommand indicates command was triggered via MQTT command.
	CommandSourceRemoteCommand CommandSource = "REMOTE_COMMAND"
)

// CommandStatus represents the status of a command.
type CommandStatus string

const (
	// CommandStatusPending indicates the command is pending execution.
	CommandStatusPending CommandStatus = "PENDING"
	// CommandStatusCompleted indicates the command has been completed.
	CommandStatusCompleted CommandStatus = "COMPLETED"
	// CommandStatusFailed indicates the command failed.
	CommandStatusFailed CommandStatus = "FAILED"
)

// Command represents a command that can be executed on devices
type Command struct {
	ID            string        `json:"id"`
	CommandType   string        `json:"command_type"`
	Status        CommandStatus `json:"status"`
	Source        CommandSource `json:"source"`
	DeviceIDArray []string      `json:"device_id_array"`
	CreatedAt     time.Time     `json:"created_at"`
	CompletedAt   *time.Time    `json:"completed_at,omitempty"`
	ErrorMsg      string        `json:"error_msg,omitempty"`
}
