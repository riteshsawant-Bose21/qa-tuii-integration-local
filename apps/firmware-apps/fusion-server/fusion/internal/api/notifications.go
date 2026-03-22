package api

import (
	"errors"
	"time"

	"github.com/oklog/ulid/v2"
)

// NotifyOp is a custom type representing notification message operations.
type NotifyOp string

const (
	NotifyOpAck               NotifyOp = "ack"
	NotifyOpAudioRemove       NotifyOp = "audio_remove"
	NotifyOpAudioSync         NotifyOp = "audio_sync"
	NotifyOpConfigUpdate      NotifyOp = "config_update"
	NotifyOpDeviceUpdate      NotifyOp = "device_update"
	NotifyOpNoop              NotifyOp = "no_op"
	NotifyOpSnapActivate      NotifyOp = "snapshot_activate"
	NotifyOpSnapCreate        NotifyOp = "snapshot_create"
	NotifyOpSnapDelete        NotifyOp = "snapshot_delete"
	NotifyOpSnapSave          NotifyOp = "snapshot_save"
	NotifyOpTaskCreate        NotifyOp = "task_create"
	NotifyOpTaskDelete        NotifyOp = "task_delete"
	NotifyOpTaskUpdate        NotifyOp = "task_update"
	NotifyOpFirmwareAvailable NotifyOp = "firmware_available"
	NotifyOpVIPStatus         NotifyOp = "vip_status"
	NotifyOpValueGet          NotifyOp = "get"
	NotifyOpValueSet          NotifyOp = "set"
)

// NotifyMessage holds information about a cross-node message
type NotifyMessage struct {
	ID                string   `json:"id"`
	Operation         NotifyOp `json:"operation"`
	Node              string
	SentAt            time.Time
	AudioRemove       *AudioRemoveUpdate
	AudioSync         *AudioSyncUpdate
	ConfigUpdate      *ConfigUpdate
	ConfigValue       *ConfigValue
	DeviceInfo        *DeviceInfo
	FirmwareUpdate    *FirmwareSyncUpdate
	SnapshotOperation *SnapshotOperation
	Task              *Task
	VersionUpdate     *VersionUpdate
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

func validateTask(m *NotifyMessage) error {
	if m.Task == nil {
		return errors.New("Task required for operation")
	}
	return nil
}

func validateSnapshot(m *NotifyMessage) error {
	if m.SnapshotOperation == nil {
		return errors.New("SnapshotOperation required for operation")
	}
	return nil
}

func validateConfigValue(m *NotifyMessage) error {
	if m.ConfigValue == nil {
		return errors.New("ConfigValue required for operation")
	}
	return nil
}

func (m *NotifyMessage) Validate() error {
	if validate, ok := validators[m.Operation]; ok {
		return validate(m)
	}
	return nil // ops with no validation required
}

var validators = map[NotifyOp]func(*NotifyMessage) error{
	NotifyOpAudioRemove: func(m *NotifyMessage) error {
		if m.AudioRemove == nil {
			return errors.New("AudioRemove required for operation")
		}
		return nil
	},
	NotifyOpAudioSync: func(m *NotifyMessage) error {
		if m.AudioSync == nil {
			return errors.New("AudioSync required for operation")
		}
		return nil
	},
	NotifyOpTaskCreate: validateTask,
	NotifyOpTaskUpdate: validateTask,
	NotifyOpTaskDelete: validateTask,

	NotifyOpSnapActivate: validateSnapshot,
	NotifyOpSnapCreate:   validateSnapshot,
	NotifyOpSnapDelete:   validateSnapshot,

	NotifyOpValueGet: validateConfigValue,
	NotifyOpValueSet: validateConfigValue,
}

func (msg *NotifyMessage) IsPublic() bool {
	return msg.Operation == NotifyOpConfigUpdate ||
		msg.Operation == NotifyOpSnapActivate ||
		msg.Operation == NotifyOpAck ||
		msg.Operation == NotifyOpVIPStatus
}

func WithAudioRemove(update *AudioRemoveUpdate) func(*NotifyMessage) {
	return func(m *NotifyMessage) {
		m.AudioRemove = update
	}
}

func WithAudioSync(update *AudioSyncUpdate) func(*NotifyMessage) {
	return func(m *NotifyMessage) {
		m.AudioSync = update
	}
}

func WithConfigUpdate(update *ConfigUpdate) func(*NotifyMessage) {
	return func(m *NotifyMessage) {
		m.ConfigUpdate = update
	}
}

func WithSnapshotOperation(operation *SnapshotOperation) func(*NotifyMessage) {
	return func(m *NotifyMessage) {
		m.SnapshotOperation = operation
	}
}

func WithTask(task *Task) func(*NotifyMessage) {
	return func(m *NotifyMessage) {
		m.Task = task
	}
}

func WithFirmwareUpdate(update *FirmwareSyncUpdate) func(*NotifyMessage) {
	return func(m *NotifyMessage) {
		m.FirmwareUpdate = update
	}
}

func WithVersionUpdate(update *VersionUpdate) func(*NotifyMessage) {
	return func(m *NotifyMessage) {
		m.VersionUpdate = update
	}
}
