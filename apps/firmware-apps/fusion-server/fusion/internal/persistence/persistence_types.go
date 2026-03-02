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
