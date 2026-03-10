package cluster

import (
	"bytes"
	"errors"
	"fmt"
	"fusion-services-core/logging"
	"fusion-services-core/vip"
	"fusion/internal/api"
	"fusion/internal/persistence"
	"fusion/internal/routes"
	"fusion/internal/utils"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"

	json "github.com/goccy/go-json"
)

const (
	serverPrefix = "fusion"
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

func (c *Cluster) GetVIP(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	if c.appConfig.Local {
		c.getVIPInLocalConfig(w)
		return
	}

	vipValue, multiple, err := vip.ReadFromKeepalivedConfig(c.configPath)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if multiple {
		logging.GetLogger().Warn("More than one VIP found.")
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)

	isVip, err := vip.IsLocalVIP(vipValue)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if isVip {

		local, vipAddr, ok := vip.LocalForVIP(vipValue)
		if !ok {
			w.WriteHeader(http.StatusNotFound)
			return
		}

		json.NewEncoder(w).Encode(map[string]string{
			"local": local.String(),
			"vip":   vipAddr.String(),
		})
		return
	}

	w.WriteHeader(http.StatusNotFound)
}

func (c *Cluster) SetVIP(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	defer r.Body.Close()

	vipValue, err := utils.ExtractValue(r, "vip")
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := vip.Validate(vipValue); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	endpoint := routes.DevicesVIPEndpoint + "/" + url.QueryEscape(vipValue)

	// Wrap c.updateVIP(vip) in a zero argument func() returning an error
	// so we can use it with postGenericToAdmin
	localFn := func() error {
		return c.updateVIP(vipValue)
	}

	if err := postGenericToAdmin(c, endpoint, localFn); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if !c.appConfig.Local {
		go func() {
			// Reload keepalived outside of request after updating all the nodes
			if err := postGenericToAdmin(c, routes.DeviceReloadVIPEndpoint, c.reloadVIP); err != nil {
				// Log the error — don't respond to client because it's async
				logging.GetLogger().Error("Failed to reload VIP: %v", err)
			}
		}()
	}

	w.WriteHeader(http.StatusAccepted)
}

func (c *Cluster) UpdateVIPLocal(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	defer r.Body.Close()

	vipValue, err := utils.ExtractValue(r, "vip")
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := c.updateVIP(vipValue); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (c *Cluster) ReloadVIP(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	defer r.Body.Close()

	go func() {
		// Reload keepalived outside of request after updating all the nodes
		if err := postGenericToAdmin(c, routes.DeviceReloadVIPEndpoint, c.reloadVIP); err != nil {
			// Log the error. Don't respond to client because it's async
			logging.GetLogger().Error("Failed to reload VIP: %v", err)
		}
	}()

	w.WriteHeader(http.StatusAccepted)
}

func (c *Cluster) ReloadVIPLocal(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	defer r.Body.Close()

	if err := c.reloadVIP(); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

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

// updateVIP updates keepalived configuration with the new VIP but DOES NOT restart keepalived.
func (c *Cluster) updateVIP(vipValue string) error {

	if err := vip.Validate(vipValue); err != nil {
		return err
	}

	if err := c.setVIPInConfig(vipValue); err != nil {
		return err
	}

	logging.GetLogger().Debug("Updated VIP: %s", vipValue)

	return nil
}

// reloadVIP reloads the keepalived configuration
func (c *Cluster) reloadVIP() error {

	if err := c.restartKeepalived(); err != nil {
		return err
	}

	return nil
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

func (c *Cluster) isLocalNodePrimary() bool {

	vipValue, multiple, err := vip.ReadFromKeepalivedConfig(c.configPath)
	if err != nil {
		logging.GetLogger().Error("Failed to get VIP from config: %v", err)
		return false
	}
	if multiple {
		logging.GetLogger().Warn("More than one VIP found.")
	}

	_, _, isLocal := vip.LocalForVIP(vipValue)
	return isLocal
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

	if patch.IsClaimed != nil {
		info.IsClaimed = *patch.IsClaimed
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

// setVIPInConfig update the VIP value in keepalived.conf
func (c *Cluster) setVIPInConfig(newVIP string) error {
	logger := logging.GetLogger()

	if c.appConfig.Local {
		return vip.WriteToLocalConfig(serverPrefix, vip.DefaultConfFile, newVIP)
	}

	newVIP = vip.Canonicalize(newVIP)
	logger.Debug("Updating virtual_ipaddress in %s → %s", c.configPath, newVIP)

	// Ensure only one goroutine updates keepalived.conf at a time
	c.vipMu.Lock()
	defer c.vipMu.Unlock()

	if err := vip.WriteToKeepalivedConfig(c.configPath, newVIP); err != nil {
		return err
	}

	logger.Debug("VIP updated successfully: %s", newVIP)
	return nil
}

// getVIPInLocalConfig is for use in "local" development mode only
func (c *Cluster) getVIPInLocalConfig(w http.ResponseWriter) {
	vipValue, err := vip.ReadFromLocalConfig(serverPrefix, vip.DefaultConfFile)
	if err != nil {
		if os.IsNotExist(err) || errors.Is(err, vip.ErrLocalConfigEmpty) {
			http.Error(w, err.Error(), http.StatusNotFound)
			return
		}
		http.Error(w, fmt.Sprintf("error reading local config: %v", err),
			http.StatusInternalServerError)
		return
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(map[string]string{
		"local": vipValue,
		"vip":   vipValue,
	})
}
