package cluster

import (
	"bytes"
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/persistence"
	"fusion/internal/routes"
	"fusion/internal/utils"
	"io"
	"net"
	"net/http"

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

	deviceInfos := c.fetchAllDeviceInfos()

	var localInfo *persistence.DeviceInfo
	for _, info := range deviceInfos {
		if info.Id == deviceId {
			localInfo = &info
			break
		}
	}

	if localInfo == nil {
		http.Error(w, fmt.Sprintf("Device %s not found", deviceId), http.StatusNotFound)
		return
	}

	var patch persistence.DevicePatch
	if err := json.NewDecoder(r.Body).Decode(&patch); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON: %v", err), http.StatusBadRequest)
		return
	}

	if err := validateNoDuplication(deviceInfos, patch, localInfo.Id); err != nil {
		http.Error(w, fmt.Sprintf("%v", err), http.StatusConflict)
		return

	}

	c.applyPatch(&patch, localInfo)

	if c.hostIsLocal(localInfo.Address) {
		if err := c.delegate.persistence.SetDeviceInfo(localInfo); err != nil {
			http.Error(w, fmt.Sprintf("Failed to set device info: %v", err), http.StatusInternalServerError)
			return
		}
	} else {

		jsonBody, err := json.Marshal(patch)
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to encode patch: %v", err), http.StatusInternalServerError)
			return
		}

		localPatchAddress := net.JoinHostPort(localInfo.Address, api.AdminPort)
		url := getLocalURL(localPatchAddress, routes.DeviceEndpoint)

		req, err := http.NewRequest(http.MethodPatch, url, bytes.NewReader(jsonBody))
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to create PATCH request: %v", err), http.StatusInternalServerError)
			return
		}
		req.Header.Set(api.ContentType, api.JsonMIMEType)

		resp, err := c.httpClient.Do(req)
		if err != nil {
			http.Error(w, fmt.Sprintf("PATCH request failed: %v", err), http.StatusBadGateway)
			return
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusNoContent {
			body, err := io.ReadAll(resp.Body)
			logging.GetLogger().Error("Remote patch to %s failed with body=%s %v", url, body, err)
			http.Error(w, fmt.Sprintf("PATCH failed: %s", string(body)), resp.StatusCode)
			return
		}
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

	w.WriteHeader(http.StatusNoContent)
}

func (c *Cluster) fetchAllDeviceInfos() []persistence.DeviceInfo {
	return fetchFromAdmin(
		c,
		c.getLocalDeviceInfo,
		routes.DeviceEndpoint,
	)
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

	if patch.XYTECloudID != nil {
		info.XYTECloudID = *patch.XYTECloudID
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
