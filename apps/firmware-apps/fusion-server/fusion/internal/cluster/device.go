package cluster

import (
	"bytes"
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/routes"
	"fusion/internal/utils"
	"io"
	"net"
	"net/http"

	json "github.com/goccy/go-json"
)

func (c *Cluster) GetAllDevicesInfo() []api.DeviceInfo {
	return c.fetchAllDeviceInfos()
}

func (c *Cluster) GetDeviceInfoLocal() api.DeviceInfo {
	return c.getDeviceInfoLocal()
}

func (c *Cluster) UpdateDeviceInfo(device_id string, patch *api.DevicePatch) error {

	localInfo, err := c.findAndValidateDevice(device_id, patch)
	if err != nil {
		return err
	}

	if c.hostIsLocal(localInfo.Address) {
		return c.UpdateDeviceInfoLocal(patch)
	}
	return c.updateRemoteDevice(device_id, localInfo, patch)

}

func (c *Cluster) UpdateDeviceInfoLocal(patch *api.DevicePatch) error {

	stored, err := c.delegate.persistence.GetStoredDeviceInfo()
	if err != nil {
		return err
	}

	c.applyPatch(patch, stored)

	if err := c.delegate.persistence.SetDeviceInfo(stored); err != nil {
		return fmt.Errorf("Failed to set device info: %v", err)
	}
	info := c.getDeviceInfoLocal()
	c.broadcastDeviceUpdate(&info)
	return nil
}

// findAndValidateDevice finds the device and validates the patch
func (c *Cluster) findAndValidateDevice(device_id string, patch *api.DevicePatch) (*api.DeviceInfo, error) {
	deviceInfos := c.fetchAllDeviceInfos()

	var localInfo *api.DeviceInfo
	for i := range deviceInfos {
		if deviceInfos[i].Id == device_id {
			localInfo = &deviceInfos[i]
			break
		}
	}

	if localInfo == nil {
		return nil, fmt.Errorf("Device %s not found", device_id)
	}

	if err := validateNoDuplication(deviceInfos, *patch, localInfo.Id); err != nil {
		return nil, err
	}

	return localInfo, nil
}

func (c *Cluster) fetchAllDeviceInfos() []api.DeviceInfo {
	return fetchFromAdmin(
		c,
		c.getDeviceInfoLocal,
		routes.DeviceEndpoint,
	)
}

func (c *Cluster) getDeviceInfoLocal() api.DeviceInfo {

	savedInfo, err := c.delegate.persistence.GetStoredDeviceInfo()
	if err != nil {
		//This doesnt return error as this fuction is called from fetchGenericFromAdmin which cant return partial errors
		logging.GetLogger().Error("Failed to get local device info: %v", err)
		return api.DeviceInfo{}
	}

	id := ""
	if savedInfo.Id != nil {
		id = *savedInfo.Id
	}
	name := ""
	if savedInfo.Name != nil {
		name = *savedInfo.Name
	}
	location := ""
	if savedInfo.Location != nil {
		location = *savedInfo.Location
	}

	deviceInfo := api.DeviceInfo{
		Id:                       id,
		Name:                     name,
		Location:                 location,
		Address:                  c.appConfig.BindAddr,
		ModelName:                utils.GetModelName(),
		SerialNumber:             utils.GetSerialNumber(),
		SoftwareVersion:          utils.GetSoftwareUpdateVersion(),
		MacAddress:               utils.GetMacAddress(),
		IsPrimaryNode:            c.isLocalNodePrimary(),
		IsDeviceCertificateValid: utils.IsCertificateValid(),
		FusionMonorepoBranch:     utils.GetBranchName(),
		FusionMonorepoCommitHash: utils.GetCommitHash(),
		JenkinsBuildNumber:       utils.GetJenkinsBuildNumber(),
	}

	return deviceInfo
}

// updateRemoteDevice updates a device that is hosted on a remote node
func (c *Cluster) updateRemoteDevice(deviceID string, localInfo *api.DeviceInfo, patch *api.DevicePatch) error {
	jsonBody, err := json.Marshal(patch)
	if err != nil {
		return fmt.Errorf("Failed to encode patch: %v", err)
	}

	localPatchAddress := net.JoinHostPort(localInfo.Address, api.AdminPort)
	url := utils.GetLocalURL(localPatchAddress, routes.DeviceEndpoint)

	req, err := http.NewRequest(http.MethodPatch, url, bytes.NewReader(jsonBody))
	if err != nil {
		return fmt.Errorf("Failed to create PATCH request: %v", err)
	}
	req.Header.Set(api.ContentType, api.JsonMIMEType)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("PATCH request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		logging.GetLogger().Error("Remote patch to %s failed with body=%s", url, string(body))
		return fmt.Errorf("PATCH failed: %s", string(body))
	}

	return nil
}

// broadcastDeviceUpdate sends device updates via gossip protocol
func (c *Cluster) broadcastDeviceUpdate(deviceData *api.DeviceInfo) {
	if c.delegate.hub == nil {
		return
	}

	notifyMsg := api.NewNotifyMessage(
		api.NotifyOpDeviceUpdate,
		c.delegate.appConfig.NodeName,
		api.WithDeviceInfo(deviceData))

	if err := c.delegate.hub.BroadcastToNodes(notifyMsg); err != nil {
		logging.GetLogger().Error("Failed to broadcast device update for device %s: %v", deviceData.Id, err)
	} else {
		logging.GetLogger().Info("[DeviceUpdate] Broadcasted device update for device %s via gossip", deviceData.Id)
	}

	c.delegate.hub.BroadcastToObservers(notifyMsg)

}

func (c *Cluster) applyPatch(patch *api.DevicePatch, storedInfo *api.DevicePatch) {

	if patch.Location != nil {
		storedInfo.Location = patch.Location
	}

	if patch.Name != nil {
		storedInfo.Name = patch.Name
	}

	if patch.Id != nil {
		storedInfo.Id = patch.Id
	}

}

// validateNoDuplication returns an error if any of the non‐nil fields in patch
// would collide with another DeviceInfo other than the one with ID == currentID.
func validateNoDuplication(
	allInfos []api.DeviceInfo,
	patch api.DevicePatch,
	currentID string,
) error {
	for _, info := range allInfos {
		// Skip the device we are updating
		if info.Id == currentID {
			continue
		}

		// Check ID uniqueness (only if patch.Id was provided)
		if patch.Id != nil && *patch.Id == info.Id {
			return fmt.Errorf("duplicate id: %q is already in use", *patch.Id)
		}

		// Check Name uniqueness (only if patch.Name was provided)
		if patch.Name != nil && *patch.Name == info.Name {
			return fmt.Errorf("duplicate name: %q is already in use", *patch.Name)
		}
		// Location is not required to be unique
	}

	return nil
}

// refreshDeviceDefaults seeds default Id and Name into persistence on startup if not already set.
// Called by NewCluster and JoinMemberlist
func (c *Cluster) refreshDeviceDefaultsIfRequired() {
	stored, err := c.delegate.persistence.GetStoredDeviceInfo()
	if err != nil {
		stored = &api.DevicePatch{}
	}

	changed := false
	if stored.Id == nil || *stored.Id == "" {
		id := c.appConfig.NodeName + "_instance"
		stored.Id = &id
		changed = true
	}
	if stored.Name == nil || *stored.Name == "" {
		name := c.appConfig.NodeName
		stored.Name = &name
		changed = true
	}

	if !changed {
		return
	}

	if err := c.delegate.persistence.SetDeviceInfo(stored); err != nil {
		logging.GetLogger().Error("Unable to save device defaults: %v", err)
	}
}
