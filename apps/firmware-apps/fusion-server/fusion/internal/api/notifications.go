package api

import (
	"errors"
	"time"

	"github.com/oklog/ulid/v2"
)

// NotifyOp is a custom type representing notification message operations.
type NotifyOp string

const (
	NotifyOpAck           NotifyOp = "ack"
	NotifyOpAudioRemove   NotifyOp = "audio_remove"
	NotifyOpAudioSync     NotifyOp = "audio_sync"
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
	AudioRemove    *AudioRemoveUpdate
	AudioSync      *AudioSyncUpdate
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

func validateTask(m *NotifyMessage) error {
	if m.Task == nil {
		return errors.New("Task required for operation")
	}
	return nil
}

func validateSnapshot(m *NotifyMessage) error {
	if m.SnapshotUpdate == nil {
		return errors.New("SnapshotUpdate required for operation")
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

	NotifyOpVersionUpdate: func(m *NotifyMessage) error {
		if m.VersionUpdate == nil {
			return errors.New("VersionUpdate required for operation")
		}
		return nil
	},
}

func (msg *NotifyMessage) IsPublic() bool {
	return msg.Operation == NotifyOpConfigUpdate ||
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

func WithSnapshotUpdate(update *SnapshotUpdate) func(*NotifyMessage) {
	return func(m *NotifyMessage) {
		m.SnapshotUpdate = update
	}
}

func WithTask(task *Task) func(*NotifyMessage) {
	return func(m *NotifyMessage) {
		m.Task = task
	}
}

func WithVersionUpdate(update *VersionUpdate) func(*NotifyMessage) {
	return func(m *NotifyMessage) {
		m.VersionUpdate = update
	}
}
