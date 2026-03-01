package persistence

import (
	"fusion/internal/api"
	"time"
)

// DeviceInfo represents device configuration data.
type DeviceInfo struct {
	Address         string `json:"address"`
	Id              string `json:"id"`
	Location        string `json:"location"`
	Name            string `json:"name"`
	ModelName       string `json:"model_name"`
	MacAddress      string `json:"mac_address"`
	IsClaimed       bool   `json:"is_claimed"`
	SerialNumber    string `json:"serial_number"`
	IsPrimaryNode   bool   `json:"is_primary"`
	FirmwareVersion string `json:"firmware_version"`
}

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
