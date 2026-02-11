package types

type DeviceCreateRequest struct {
	DeviceID        string `json:"deviceId" binding:"required"`
	DeviceName      string `json:"deviceName" binding:"required"`
	DeviceType      string `json:"deviceType" binding:"required"`
	FirmwareVersion string `json:"firmwareVersion" binding:"required"`
	CSR             string `json:"csr" binding:"required"`
}

type DeviceCreateResponse struct {
	Certificate string `json:"certificate"`
}

const (
	// Generic errors
	ErrMsgDeviceAlreadyExists = "Device already exists"
)