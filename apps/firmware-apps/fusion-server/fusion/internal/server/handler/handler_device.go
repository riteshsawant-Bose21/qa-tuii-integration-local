package handler

import "fusion/internal/api"

func (h *Handler) HandleGetDevicesInfo() []api.DeviceInfo {
	return h.clusterTransport.GetAllDevicesInfo()
}

func (h *Handler) HandleGetDeviceInfo() api.DeviceInfo {
	return h.clusterTransport.GetDeviceInfoLocal()
}

func (h *Handler) HandleUpdateDeviceInfo(device_id string, patch api.DevicePatch) error {
	return h.clusterTransport.UpdateDeviceInfo(device_id, &patch)
}

func (h *Handler) HandleUpdateDeviceInfoLocal(patch api.DevicePatch) error {
	return h.clusterTransport.UpdateDeviceInfoLocal(&patch)
}

func (h *Handler) HandleGetCSR(deviceID string) ([]byte, error) {
	return h.clusterTransport.GetDeviceCSR(deviceID)
}

func (h *Handler) HandleSetDeviceCertificate(deviceID string, certPEM []byte) error {
	return h.clusterTransport.SetDeviceCertificate(deviceID, certPEM)
}

func (h *Handler) ResetDeviceCertificate(deviceID string) error {
	return h.clusterTransport.ResetDeviceCertificate(deviceID)
}
