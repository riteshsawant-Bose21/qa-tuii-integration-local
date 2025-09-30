package persistence

import (
	"fusion/internal/api"
	"time"
)

// AudioMetadata represents the persisted audio metadata.
type AudioMetadata struct {
	Id          string        `json:"id"`
	OrigName    string        `json:"orig_name"`
	DisplayName string        `json:"display_name"`
	Filename    string        `json:"filename"` // the on-disk name (ID + ext)
	MimeType    string        `json:"mime_type"`
	Uploaded    time.Time     `json:"uploaded"`
	Duration    time.Duration `json:"duration,omitempty"`
	SizeBytes   int64         `json:"size_bytes"`
	Tags        []string      `json:"tags"`
}

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
