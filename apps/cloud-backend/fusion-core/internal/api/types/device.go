package types

type DeviceCreateRequest struct {
	DeviceID        string `json:"device_id" binding:"required"`
	DeviceName      string `json:"device_name" binding:"required"`
	ModelName       string `json:"model_name" binding:"required"`
	FirmwareVersion string `json:"firmware_version" binding:"required"`
	SerialNumber    string `json:"serial_number" binding:"required"`
	MacAddress      string `json:"mac_address" binding:"required"`
	DeviceZone      string `json:"device_zone" binding:"required"`
	DeviceLocation  string `json:"device_location" binding:"required"`
	Timezone        string `json:"timezone" binding:"required"`
	DstEnabled      bool   `json:"dst_enabled" binding:"required"`
	NtpEnabled      bool   `json:"ntp_enabled" binding:"required"`
	NtpServer       string `json:"ntp_server" binding:"required"`
	ProjectID       string `json:"project_id" binding:"required"`
	CSR             string `json:"csr" binding:"required"`
}

type DeviceCreateResponse struct {
	Certificate string `json:"certificate"`
}

type DeviceUpdateRequest struct {
	DeviceName      string `json:"device_name"`
	FirmwareVersion string `json:"firmware_version"`
	DeviceZone      string `json:"device_zone"`
	DeviceLocation  string `json:"device_location"`
	Timezone        string `json:"timezone"`
	DstEnabled      *bool  `json:"dst_enabled"`
	NtpEnabled      *bool  `json:"ntp_enabled"`
	NtpServer       string `json:"ntp_server"`
	ProjectID       string `json:"project_id"`
}
