package cluster

import (
	"bytes"
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/persistence"
	"fusion/internal/routes"
	"fusion/internal/utils"
	"io"
	"net"
	"net/http"
	"net/url"
	"strings"
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
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
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

		resp, err := http.DefaultClient.Do(req)
		if err != nil {
			http.Error(w, fmt.Sprintf("PATCH request failed: %v", err), http.StatusBadGateway)
			return
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusNoContent {
			body, _ := io.ReadAll(resp.Body)
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

func (c *Cluster) GetVIP(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)

	vips, err := c.getVIPFromConfig()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	for _, vip := range vips {
		if isVip := c.isLocalVIP(vip); isVip {

			local, vip, ok := c.getLocalForVIP(vip)
			if !ok {
				w.WriteHeader(http.StatusNotFound)
				return
			}

			json.NewEncoder(w).Encode(map[string]string{
				"local": local.String(),
				"vip":   vip.String(),
			})
			return
		}
	}

	w.WriteHeader(http.StatusNotFound)
}

func (c *Cluster) SetVIP(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	defer r.Body.Close()

	vip, err := utils.ExtractValue(r, "vip")
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := validateVIP(vip); err != nil {
		http.Error(w, "invalid VIP format", http.StatusBadRequest)
		return
	}

	endpoint := routes.DevicesVIPEndpoint + "/" + url.QueryEscape(vip)

	// Wrap c.updateVIP(vip) in a zero argument func() returning an error
	// so we can use it with postGenericToAdmin
	localFn := func() error {
		return c.updateVIP(vip)
	}

	if err := postGenericToAdmin(c, endpoint, localFn); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Reload keepalived after updating all the nodes
	if err := postGenericToAdmin(c, routes.DeviceReloadVIPEndpoint, c.reloadVIP); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (c *Cluster) UpdateVIPLocal(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	defer r.Body.Close()

	vip, err := utils.ExtractValue(r, "vip")
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := c.updateVIP(vip); err != nil {
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

	if err := postGenericToAdmin(c, routes.DeviceReloadVIPEndpoint, c.reloadVIP); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
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

// updateVIP updates keepalived.conf with the new VIP but DOES NOT restart keepalived.
func (c *Cluster) updateVIP(vip string) error {

	if err := validateVIP(vip); err != nil {
		return err
	}

	if err := c.setVIPInConfig(vip); err != nil {
		return err
	}

	logging.GetLogger().Debug("Updated VIP: %s", vip)

	return nil
}

// reloadVIP reloads the keepalived configuration
func (c *Cluster) reloadVIP() error {

	if err := c.restartKeepalived(); err != nil {
		return err
	}

	logging.GetLogger().Debug("Reloaded VIP")

	return nil
}

// validateVIP checks that the string is a valid IP address
func validateVIP(vip string) error {
	vip = strings.TrimSpace(vip)

	// Try parsing as CIDR (IP/prefix)
	if _, _, err := net.ParseCIDR(vip); err == nil {
		return nil
	}
	// If that fails, try parsing as plain IP
	if ip := net.ParseIP(vip); ip != nil {
		return nil
	}

	return fmt.Errorf("invalid VIP format: %q", vip)
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
	return *info
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
