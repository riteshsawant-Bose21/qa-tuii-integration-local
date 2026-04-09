package types

// DeviceCreateRequest represents the request payload for creating a new device.
type DeviceCreateRequest struct {
	ClientDeviceID  string `json:"client_device_id" binding:"required"`
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
	ClientDeviceID  string `json:"client_device_id"`
	FirmwareVersion string `json:"firmware_version"`
	DeviceZone      string `json:"device_zone"`
	DeviceLocation  string `json:"device_location"`
	ProjectID       string `json:"project_id"`
	IsPrimary       *bool  `json:"is_primary"`
}

// DeviceClaimRequest represents the request payload for claiming an unclaimed device.
type DeviceClaimRequest struct {
	CSR       string `json:"csr" binding:"required"`
	ProjectID string `json:"project_id" binding:"required"`
}

// DeviceClaimResponse represents the response payload after successfully claiming a device.
type DeviceClaimResponse struct {
	Certificate string `json:"certificate"`
}

// DeviceRotateCertRequest represents the request payload for rotating a device certificate.
type DeviceRotateCertRequest struct {
	CSR string `json:"csr" binding:"required"`
}

// DeviceRotateCertResponse represents the response payload after successfully rotating a certificate.
type DeviceRotateCertResponse struct {
	Certificate string `json:"certificate"`
}

// CertificateInfo contains IoT certificate details for a device.
type CertificateInfo struct {
	ID  string // Certificate ID from AWS IoT
	Arn string // Certificate ARN from AWS IoT
}

// CommandRequest represents the request payload for sending a command to the device cluster.
type CommandType string

const (
	CommandRestart CommandType = "REBOOT"
)

// CommandRequest represents the request payload for sending a command to the device cluster.
type CommandRequest struct {
	Command   CommandType `json:"command" binding:"required" example:"REBOOT" enums:"REBOOT" validate:"oneof=REBOOT"`
	ProjectID string      `json:"project_id" binding:"required"`
	DeviceIDs []string    `json:"device_ids"`
}

// CommandResponse represents the response payload after successfully sending a command to the device cluster.
type CommandResponse struct {
	CommandID string `json:"command_id"`
}

// CommandStatusResult represents the result payload for getting the status of a command.
type CommandStatusResult struct {
	CommandID   string `json:"command_id"`
	CommandName string `json:"command_name"`
	DeviceID    string `json:"device_id"`
	Status      string `json:"status"`
	IssuedAt    string `json:"issued_at"`
	UpdatedAt   string `json:"updated_at"`
}

// CommandStatusResponse represents the response payload for getting the status of a command.
type CommandStatusResponse struct {
	Results []CommandStatusResult `json:"results"`
}

// BulkDeviceCreateRequest is the request payload for bulk creating devices.
type BulkDeviceCreateRequest struct {
	Devices []DeviceCreateRequest `json:"devices" binding:"required,min=1"`
}

// BulkDeviceCreateResult represents the result for a single device in a bulk create operation.
type BulkDeviceCreateResult struct {
	DeviceID    string  `json:"device_id"`
	ProjectID   string  `json:"project_id,omitempty"`
	Certificate *string `json:"certificate,omitempty"`
	Error       *string `json:"error,omitempty"`
	Success     bool    `json:"success"`
}

// BulkDeviceCreateResponse is the response payload for a bulk device create operation.
type BulkDeviceCreateResponse struct {
	Results []BulkDeviceCreateResult `json:"results"`
}
