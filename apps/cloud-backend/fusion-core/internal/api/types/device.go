package types

// DeviceCreateRequest represents the request payload for creating a new device.
type DeviceCreateRequest struct {
	DeviceID        string `json:"device_id" binding:"required"`
	DeviceName      string `json:"device_name" binding:"required"`
	ModelName       string `json:"model_name" binding:"required"`
	FirmwareVersion string `json:"firmware_version" binding:"required"`
	SerialNumber    string `json:"serial_number" binding:"required"`
	MacAddress      string `json:"mac_address" binding:"required"`
	DeviceZone      string `json:"device_zone" binding:"required"`
	DeviceLocation  string `json:"device_location" binding:"required"`
	ProjectID       string `json:"project_id" binding:"required"`
	IsPrimary       bool   `json:"is_primary"`
	CSR             string `json:"csr" binding:"required"`
}

// DeviceCreateResponse represents the response payload after successfully creating a device.
type DeviceCreateResponse struct {
	Certificate string `json:"certificate"`
}

// DeviceUpdateRequest represents the request payload for updating an existing device.
type DeviceUpdateRequest struct {
	DeviceName      string `json:"device_name"`
	FirmwareVersion string `json:"firmware_version"`
	DeviceZone      string `json:"device_zone"`
	DeviceLocation  string `json:"device_location"`
	ProjectID       string `json:"project_id"`
	IsPrimary       *bool  `json:"is_primary"`
}

// CertificateInfo contains IoT certificate details for a device.
type CertificateInfo struct {
	ID  string // Certificate ID from AWS IoT
	Arn string // Certificate ARN from AWS IoT
}
