package persistence

import (
	"fusion/internal/api"
	"time"
)

// DeviceInfo represents device configuration data.
type DeviceInfo struct {
	Address     string `json:"address"`
	Id          string `json:"id"`
	Location    string `json:"location"`
	Name        string `json:"name"`
	XYTECloudID string `json:"xyte_cloud_id"`
	IsClaimed   bool   `json:"is_claimed"`
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
