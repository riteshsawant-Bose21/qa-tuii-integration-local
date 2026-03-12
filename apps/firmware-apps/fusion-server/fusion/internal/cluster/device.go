package cluster

import (
	"bytes"
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/network"
	"fusion/internal/persistence"
	"fusion/internal/routes"
	"fusion/internal/utils"
	"io"
	"net"
	"net/http"
	"os"

	json "github.com/goccy/go-json"
)

func (c *Cluster) GetDevicesInfo(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(c.fetchAllDeviceInfos())
}

func (c *Cluster) GetDeviceInfo(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	info, err := c.delegate.persistence.GetDeviceInfo()
	if err != nil {
		http.Error(w, fmt.Sprintf("Error getting device info: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	if err := json.NewEncoder(w).Encode(info); err != nil {
		logging.GetLogger().Error("Error encoding device info: %v", err)
	}
}

func (c *Cluster) SetDeviceInfo(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	defer r.Body.Close()

	var info persistence.DeviceInfo
	if err := json.NewDecoder(r.Body).Decode(&info); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON: %v", err), http.StatusBadRequest)
		return
	}

	if err := c.delegate.persistence.SetDeviceInfo(&info); err != nil {
		http.Error(w, fmt.Sprintf("Failed to set device info: %v", err), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (c *Cluster) UpdateDeviceInfo(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePatch(w, r) {
		return
	}
	defer r.Body.Close()

	deviceId, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	var patch persistence.DevicePatch
	if err := json.NewDecoder(r.Body).Decode(&patch); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON: %v", err), http.StatusBadRequest)
		return
	}

	if err, statusCode := c.updateDeviceInfoCore(deviceId, &patch, false); err != nil {
		http.Error(w, err.Error(), statusCode)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (c *Cluster) UpdateDeviceInfoLocal(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePatch(w, r) {
		return
	}
	defer r.Body.Close()

	var patch persistence.DevicePatch
	if err := json.NewDecoder(r.Body).Decode(&patch); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON: %v", err), http.StatusBadRequest)
		return
	}

	info, err := c.delegate.persistence.GetDeviceInfo()
	if err != nil {
		http.Error(w, fmt.Sprintf("Error loading device info: %v", err), http.StatusInternalServerError)
		return
	}

	c.applyPatch(&patch, info)

	if err := c.delegate.persistence.SetDeviceInfo(info); err != nil {
		http.Error(w, fmt.Sprintf("Failed to set device info: %v", err), http.StatusInternalServerError)
		return
	}

	// Broadcast device update through Hub
	c.broadcastDeviceUpdate(info.Id, info)

	w.WriteHeader(http.StatusNoContent)
}

func (c *Cluster) RebootSystem(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	defer r.Body.Close()

	go func() {
		// Reboot system outside of request after updating all the nodes
		if err := postGenericToAdminLast(c, routes.ClusterRebootEndpoint, c.rebootSystem); err != nil {
			// Log the error. Don't respond to client because it's async
			logging.GetLogger().Error("Failed to reboot system: %v", err)
		}
	}()

	w.WriteHeader(http.StatusNoContent)

}

func (c *Cluster) RebootSystemLocal(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	defer r.Body.Close()

	if err := c.rebootSystem(); err != nil {
		logging.GetLogger().Error("Failed to reboot local system: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusAccepted)
}

func (c *Cluster) rebootSystem() error {
	if err := c.restartSystem(); err != nil {
		return err
	}

	return nil
}

func (c *Cluster) fetchAllDeviceInfos() []persistence.DeviceInfo {
	return fetchFromAdmin(
		c,
		c.getLocalDeviceInfo,
		routes.DeviceEndpoint,
	)
}

// GetAllDeviceInfos is the public interface for fetching all cluster device info
func (c *Cluster) GetAllDeviceInfos() []persistence.DeviceInfo {
	return c.fetchAllDeviceInfos()
}

// UpdateDeviceInfoForWebSocket updates device information cluster-wide
func (c *Cluster) UpdateDeviceInfoForWebSocket(deviceID string, patch *persistence.DevicePatch) error {
	err, _ := c.updateDeviceInfoCore(deviceID, patch, false)
	return err
}

// updateDeviceInfoCore contains the common logic for updating device information
func (c *Cluster) updateDeviceInfoCore(deviceID string, patch *persistence.DevicePatch, alwaysBroadcast bool) (error, int) {
	localInfo, err, statusCode := c.findAndValidateDevice(deviceID, patch)
	if err != nil {
		return err, statusCode
	}

	c.applyPatch(patch, localInfo)

	if c.hostIsLocal(localInfo.Address) {
		return c.updateLocalDevice(deviceID, localInfo)
	}
	return c.updateRemoteDevice(deviceID, localInfo, patch, alwaysBroadcast)
}

// findAndValidateDevice finds the device and validates the patch
func (c *Cluster) findAndValidateDevice(deviceID string, patch *persistence.DevicePatch) (*persistence.DeviceInfo, error, int) {
	deviceInfos := c.fetchAllDeviceInfos()

	var localInfo *persistence.DeviceInfo
	for _, info := range deviceInfos {
		if info.Id == deviceID {
			localInfo = &info
			break
		}
	}

	if localInfo == nil {
		return nil, fmt.Errorf("Device %s not found", deviceID), http.StatusNotFound
	}

	if err := validateNoDuplication(deviceInfos, *patch, localInfo.Id); err != nil {
		return nil, err, http.StatusConflict
	}

	return localInfo, nil, http.StatusOK
}

// updateLocalDevice updates a device that is hosted locally
func (c *Cluster) updateLocalDevice(deviceID string, localInfo *persistence.DeviceInfo) (error, int) {
	if err := c.delegate.persistence.SetDeviceInfo(localInfo); err != nil {
		return fmt.Errorf("Failed to set device info: %v", err), http.StatusInternalServerError
	}

	// Always broadcast for local devices
	c.broadcastDeviceUpdate(deviceID, localInfo)
	return nil, http.StatusOK
}

// updateRemoteDevice updates a device that is hosted on a remote node
func (c *Cluster) updateRemoteDevice(deviceID string, localInfo *persistence.DeviceInfo, patch *persistence.DevicePatch, alwaysBroadcast bool) (error, int) {
	jsonBody, err := json.Marshal(patch)
	if err != nil {
		return fmt.Errorf("Failed to encode patch: %v", err), http.StatusInternalServerError
	}

	localPatchAddress := net.JoinHostPort(localInfo.Address, api.AdminPort)
	url := getLocalURL(localPatchAddress, routes.DeviceEndpoint)

	req, err := http.NewRequest(http.MethodPatch, url, bytes.NewReader(jsonBody))
	if err != nil {
		return fmt.Errorf("Failed to create PATCH request: %v", err), http.StatusInternalServerError
	}
	req.Header.Set(api.ContentType, api.JsonMIMEType)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("PATCH request failed: %v", err), http.StatusBadGateway
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		logging.GetLogger().Error("Remote patch to %s failed with body=%s", url, string(body))
		return fmt.Errorf("PATCH failed: %s", string(body)), resp.StatusCode
	}

	// Broadcast for WebSocket updates only
	if alwaysBroadcast {
		c.broadcastDeviceUpdate(deviceID, localInfo)
	}

	return nil, http.StatusOK
}

// broadcastDeviceUpdate sends device updates via gossip protocol
func (c *Cluster) broadcastDeviceUpdate(deviceID string, deviceData *persistence.DeviceInfo) {
	if c.delegate.hub == nil {
		return
	}

	notifyMsg := api.NewNotifyMessage(api.NotifyOpDeviceUpdate, c.delegate.appConfig.NodeName, func(m *api.NotifyMessage) {
		m.DeviceInfo = deviceData
	})

	if err := c.delegate.hub.BroadcastToNodes(notifyMsg); err != nil {
		logging.GetLogger().Error("Failed to broadcast device update for device %s: %v", deviceID, err)
	} else {
		logging.GetLogger().Info("[DeviceUpdate] Broadcasted device update for device %s via gossip", deviceID)
	}
}

func (c *Cluster) getLocalDeviceInfo() persistence.DeviceInfo {
	info, err := c.delegate.persistence.GetDeviceInfo()
	if err != nil {
		return persistence.DeviceInfo{}
	}
	info.IsPrimaryNode = c.isLocalNodePrimary()

	return *info
}

// isLocalNodePrimary checks if this node is the primary (VIP holder)
func (c *Cluster) isLocalNodePrimary() bool {

	if c.vipMonitor != nil {
		return c.vipMonitor.IsLocalVIPHolder()
	}

	return false
}

func (c *Cluster) applyPatch(patch *persistence.DevicePatch, info *persistence.DeviceInfo) {

	if patch.Location != nil {
		info.Location = *patch.Location
	}

	if patch.Name != nil {
		info.Name = *patch.Name
	}

	if patch.Id != nil {
		info.Id = *patch.Id
	}

	if patch.ModelName != nil {
		info.ModelName = *patch.ModelName
	}

}

// validateNoDuplication returns an error if any of the non‐nil fields in patch
// would collide with another DeviceInfo other than the one with ID == currentID.
func validateNoDuplication(
	allInfos []persistence.DeviceInfo,
	patch persistence.DevicePatch,
	currentID string,
) error {
	for _, info := range allInfos {
		// Skip the device we are updating
		if info.Id == currentID {
			continue
		}

		// Check ID uniqueness (only if patch.Id was provided)
		if patch.Id != nil {
			// if they’re trying to set the ID to an empty string, you can decide
			// whether that’s “allowed” or counts as a collision with other empty IDs.
			newID := *patch.Id
			if newID == info.Id {
				return fmt.Errorf("duplicate id: %q is already in use", newID)
			}
		}

		// Check Name uniqueness (only if patch.Name was provided)
		if patch.Name != nil {
			newName := *patch.Name
			if newName == info.Name {
				return fmt.Errorf("duplicate name: %q is already in use", newName)
			}
		}

		// Location is not required to be unique
	}

	return nil
}

// updateDeviceInfo updates the persisted device info
func (c *Cluster) updateDeviceInfo() {

	var info persistence.DeviceInfo
	savedInfo, err := c.delegate.persistence.GetDeviceInfo()
	if err == nil {
		info = *savedInfo
	}

	info.Address = c.appConfig.BindAddr
	if info.Id == "" {
		info.Id = c.appConfig.NodeName + "_instance"
	}

	if info.Name == "" {
		info.Name = c.appConfig.NodeName
	}

	if info.SerialNumber == "" {
		data, err := os.ReadFile(serialPath)
		if err != nil {
			logging.GetLogger().Warn("%s not found.", serialPath)
			info.SerialNumber = serialUnknown
		} else {
			info.SerialNumber = string(bytes.TrimRight(data, "\x00\n"))
		}
	}

	if info.FirmwareVersion == "" {
		data, err := os.ReadFile(firmwarePath)
		if err != nil {
			logging.GetLogger().Warn("%s not found.", firmwarePath)
			info.FirmwareVersion = firmwareUnknown
		} else {
			info.FirmwareVersion = string(bytes.TrimRight(data, "\x00\n"))
		}
	}

	if info.MacAddress == "" {
		macAddr, err := network.GetMacAddress()
		if err != nil {
			logging.GetLogger().Warn("Unable to read MAC address: %v", err)
			info.MacAddress = macUnknown
		} else {
			info.MacAddress = macAddr
		}
	}

	if err := c.delegate.persistence.SetDeviceInfo(&info); err != nil {
		logging.GetLogger().Error("Unable to update device info: %v", err)
		return
	}
}
