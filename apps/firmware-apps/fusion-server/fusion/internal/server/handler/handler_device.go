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
