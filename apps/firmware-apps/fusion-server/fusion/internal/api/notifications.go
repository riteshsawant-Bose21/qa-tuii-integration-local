package api

import (
	"errors"
	"time"

	"github.com/oklog/ulid/v2"
)

// NotifyOp is a custom type representing notification message operations.
type NotifyOp string

const (
	NotifyOpAck                       NotifyOp = "ack"
	NotifyOpAudioRemove               NotifyOp = "audio_remove"
	NotifyOpAudioSync                 NotifyOp = "audio_sync"
	NotifyOpConfigUpdate              NotifyOp = "config_update"
	NotifyOpDeviceUpdate              NotifyOp = "device_update"
	NotifyOpGetLocalDeviceInformation NotifyOp = "get_local_device_information"
	NotifyOpNoop                      NotifyOp = "no_op"
	NotifyOpSnapActivate              NotifyOp = "snapshot_activate"
	NotifyOpSnapCreate                NotifyOp = "snapshot_create"
	NotifyOpSnapDelete                NotifyOp = "snapshot_delete"
	NotifyOpSnapSave                  NotifyOp = "snapshot_save"
	NotifyOpTaskCreate                NotifyOp = "task_create"
	NotifyOpTaskDelete                NotifyOp = "task_delete"
	NotifyOpTaskUpdate                NotifyOp = "task_update"
	NotifyOpVIPStatus                 NotifyOp = "vip_status"
	NotifyOpValueGet                  NotifyOp = "get"
	NotifyOpValueSet                  NotifyOp = "set"
	NotifyOpSoftwareUpdateAvailable   NotifyOp = "software_update_available"
	NotifyOpSoftwareUpdateSyncAck     NotifyOp = "software_update_sync_ack"
	NotifyOpSoftwareUpdate            NotifyOp = "software_update"
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
	SoftwareUpdate    *SoftwareUpdateSync
	SoftwareUpdateAck *SoftwareUpdateSyncAck
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
	NotifyOpSoftwareUpdateAvailable: func(m *NotifyMessage) error {
		if m.SoftwareUpdate == nil {
			return errors.New("SoftwareUpdate required for operation")
		}
		return nil
	},
	NotifyOpSoftwareUpdateSyncAck: func(m *NotifyMessage) error {
		if m.SoftwareUpdateAck == nil {
			return errors.New("SoftwareUpdateAck required for operation")
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
		msg.Operation == NotifyOpVIPStatus ||
		msg.Operation == NotifyOpDeviceUpdate ||
		msg.Operation == NotifyOpSoftwareUpdate ||
		msg.Operation == NotifyOpSoftwareUpdateAvailable ||
		msg.Operation == NotifyOpSoftwareUpdateSyncAck
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

func WithSoftwareUpdate(update *SoftwareUpdateSync) func(*NotifyMessage) {
	return func(m *NotifyMessage) {
		m.SoftwareUpdate = update
	}
}

func WithSoftwareUpdateAck(ack *SoftwareUpdateSyncAck) func(*NotifyMessage) {
	return func(m *NotifyMessage) {
		m.SoftwareUpdateAck = ack
	}
}

func WithVersionUpdate(update *VersionUpdate) func(*NotifyMessage) {
	return func(m *NotifyMessage) {
		m.VersionUpdate = update
	}
}

func WithDeviceInfo(info *DeviceInfo) func(*NotifyMessage) {
	return func(m *NotifyMessage) {
		m.DeviceInfo = info
	}
}
