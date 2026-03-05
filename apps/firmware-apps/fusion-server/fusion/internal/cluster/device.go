package cluster

import (
	"bytes"
	"crypto/x509"
	"encoding/pem"
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
	"strings"
	"time"

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
	if err := json.NewEncoder(w).Encode(c.fetchAllDeviceInfos()); err != nil {
		logging.GetLogger().Error("Error encoding devices info: %v", err)
	}
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

		if err := json.NewEncoder(w).Encode(map[string]string{
			"local": local.String(),
			"vip":   vipAddr.String(),
		}); err != nil {
			logging.GetLogger().Error("Error encoding VIP response: %v", err)
		}
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

func (c *Cluster) GetCSR(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	csrContent, err := os.ReadFile(fmt.Sprintf("%s%s", utils.DefaultIdentityFilePath, utils.DefaultCSRFileName))
	if err != nil {
		if os.IsNotExist(err) {
			http.Error(w, "CSR file not found", http.StatusNotFound)
			return
		}
		logging.GetLogger().Error("Error reading CSR file: %v", err)
		http.Error(w, fmt.Sprintf("Error reading CSR file: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set(api.ContentType, "text/plain")
	w.Write(csrContent)
}

func (c *Cluster) resetLocalDevice() error {
	info, err := c.delegate.persistence.GetDeviceInfo()
	if err != nil {
		return fmt.Errorf("error loading device info: %v", err)
	}
	err = os.Remove(fmt.Sprintf("%s%s", utils.DefaultIdentityFilePath, utils.DefaultCertFileName))
	if err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("error removing certificate file: %v", err)
	}

	info.IsClaimed = false

	if err := c.delegate.persistence.SetDeviceInfo(info); err != nil {
		return fmt.Errorf("failed to set device info: %v", err)
	}

	return nil
}

func (c *Cluster) SetDeviceCertificate(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	defer r.Body.Close()

	deviceId, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	deviceInfos := c.fetchAllDeviceInfos()

	var targetDevice *persistence.DeviceInfo
	for _, info := range deviceInfos {
		if info.Id == deviceId {
			targetDevice = &info
			break
		}
	}

	if targetDevice == nil {
		http.Error(w, fmt.Sprintf("Device %s not found", deviceId), http.StatusNotFound)
		return
	}

	certContent, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading certificate data: %v", err), http.StatusBadRequest)
		return
	}

	if c.hostIsLocal(targetDevice.Address) {

		// Check if we should replace the certificate
		shouldReplace, err := c.shouldReplaceCertificate(fmt.Sprintf("%s%s", utils.DefaultIdentityFilePath, utils.DefaultCertFileName), certContent)
		if err != nil {
			logging.GetLogger().Error("Error checking certificate replacement: %v", err)
			http.Error(w, fmt.Sprintf("Error checking certificate: %v", err), http.StatusInternalServerError)
			return
		}

		if !shouldReplace {
			logging.GetLogger().Info("Certificate is still valid and not near expiry, skipping replacement")
			w.Header().Set(api.ContentType, api.JsonMIMEType)
			w.WriteHeader(http.StatusOK)
			if err := json.NewEncoder(w).Encode(map[string]string{
				"message": "Certificate not updated - existing certificate is still valid",
				"action":  "skipped",
				"reason":  "certificate_still_valid",
			}); err != nil {
				logging.GetLogger().Error("Error encoding certificate response: %v", err)
			}
			return
		}

		// If this is the local device, write certificate locally
		if err := os.WriteFile(fmt.Sprintf("%s%s", utils.DefaultIdentityFilePath, utils.DefaultCertFileName), certContent, 0644); err != nil {
			logging.GetLogger().Error("Error writing certificate file: %v", err)
			http.Error(w, fmt.Sprintf("Error writing certificate file: %v", err), http.StatusInternalServerError)
			return
		}

		info, err := c.delegate.persistence.GetDeviceInfo()

		info.IsClaimed = true

		if err := c.delegate.persistence.SetDeviceInfo(info); err != nil {
			http.Error(w, fmt.Sprintf("Failed to set device info: %v", err), http.StatusInternalServerError)
			return
		}

		logging.GetLogger().Info("Certificate replaced successfully")
		w.WriteHeader(http.StatusNoContent)
	} else {
		// Make HTTP POST request to the remote device's admin certificate endpoint
		deviceAddress := net.JoinHostPort(targetDevice.Address, api.AdminPort)
		endpoint := strings.Replace(routes.DevicesIDCertificateEndpoint, "{id}", deviceId, 1)
		url := getLocalURL(deviceAddress, endpoint)

		req, err := http.NewRequest(http.MethodPost, url, bytes.NewReader(certContent))
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to create POST request: %v", err), http.StatusInternalServerError)
			return
		}
		req.Header.Set(api.ContentType, "text/plain")

		resp, err := c.httpClient.Do(req)
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to send certificate to device: %v", err), http.StatusBadGateway)
			return
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusNoContent {
			body, _ := io.ReadAll(resp.Body)
			logging.GetLogger().Error("Remote certificate request to %s failed with status %d: %s", url, resp.StatusCode, string(body))
			http.Error(w, fmt.Sprintf("Device returned error: %s", string(body)), resp.StatusCode)
			return
		}

		w.WriteHeader(http.StatusNoContent)
	}
}

func (c *Cluster) GetDeviceCSR(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	deviceId, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	deviceInfos := c.fetchAllDeviceInfos()

	var targetDevice *persistence.DeviceInfo
	for _, info := range deviceInfos {
		if info.Id == deviceId {
			targetDevice = &info
			break
		}
	}

	if targetDevice == nil {
		http.Error(w, fmt.Sprintf("Device %s not found", deviceId), http.StatusNotFound)
		return
	}

	if c.hostIsLocal(targetDevice.Address) {
		// If this is the local device, call the local GetCSR function
		c.GetCSR(w, r)
		return
	} else {
		// Make HTTP request to the remote device's admin CSR endpoint
		deviceAddress := net.JoinHostPort(targetDevice.Address, api.AdminPort)
		url := getLocalURL(deviceAddress, routes.DevicesGetCSREndpoint)

		resp, err := c.httpClient.Get(url)
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to get CSR from device: %v", err), http.StatusBadGateway)
			return
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			body, _ := io.ReadAll(resp.Body)
			logging.GetLogger().Error("Remote CSR request to %s failed with status %d: %s", url, resp.StatusCode, string(body))
			http.Error(w, fmt.Sprintf("Device returned error: %s", string(body)), resp.StatusCode)
			return
		}

		// Copy the response headers and body
		w.Header().Set(api.ContentType, "text/plain")
		io.Copy(w, resp.Body)
	}
}

func (c *Cluster) ResetDevice(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireDelete(w, r) {
		return
	}

	deviceId, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	deviceInfos := c.fetchAllDeviceInfos()

	var targetDevice *persistence.DeviceInfo
	for _, info := range deviceInfos {
		if info.Id == deviceId {
			targetDevice = &info
			break
		}
	}

	if targetDevice == nil {
		http.Error(w, fmt.Sprintf("Device %s not found", deviceId), http.StatusNotFound)
		return
	}

	if c.hostIsLocal(targetDevice.Address) {
		// If this is the local device, perform reset locally
		if err := c.resetLocalDevice(); err != nil {
			http.Error(w, fmt.Sprintf("Failed to reset device: %v", err), http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusNoContent)
		return
	} else {
		// Make HTTP DELETE request to the remote device's admin reset endpoint
		deviceAddress := net.JoinHostPort(targetDevice.Address, api.AdminPort)
		endpoint := strings.Replace(routes.DevicesIDResetEndpoint, "{id}", deviceId, 1)
		url := getLocalURL(deviceAddress, endpoint)

		req, err := http.NewRequest(http.MethodDelete, url, nil)
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to create DELETE request: %v", err), http.StatusInternalServerError)
			return
		}

		resp, err := c.httpClient.Do(req)
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to send reset request to device: %v", err), http.StatusBadGateway)
			return
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusNoContent {
			body, _ := io.ReadAll(resp.Body)
			logging.GetLogger().Error("Remote reset request to %s failed with status %d: %s", url, resp.StatusCode, string(body))
			http.Error(w, fmt.Sprintf("Device returned error: %s", string(body)), resp.StatusCode)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
	go func() {
		// Reboot system outside of request after updating all the nodes
		if err := postGenericToAdminLast(c, routes.ClusterRebootEndpoint, c.rebootSystem); err != nil {
			// Log the error. Don't respond to client because it's async
			logging.GetLogger().Error("Failed to reboot system: %v", err)
		}
	}()

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

// TriggerReboot initiates a system reboot
func (c *Cluster) TriggerReboot() error {
	return c.rebootSystem()
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
	info.IsPrimaryNode = c.IsLocalNodePrimary()

	return *info
}

func (c *Cluster) IsLocalNodePrimary() bool {

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
	if err := json.NewEncoder(w).Encode(map[string]string{
		"local": vipValue,
		"vip":   vipValue,
	}); err != nil {
		logging.GetLogger().Error("Error encoding local VIP response: %v", err)
	}
}

// shouldReplaceCertificate determines if a certificate should be replaced
// Returns true if:
// - The file doesn't exist
// - The existing certificate is expired
// - The existing certificate is near expiry (within 3 months)
// - The new certificate content is different from existing
func (c *Cluster) shouldReplaceCertificate(certPath string, newCertContent []byte) (bool, error) {
	// Check if file exists
	if _, err := os.Stat(certPath); os.IsNotExist(err) {
		logging.GetLogger().Info("Certificate file does not exist, will create new one")
		return true, nil
	}

	// Read existing certificate
	existingContent, err := os.ReadFile(certPath)
	if err != nil {
		return false, fmt.Errorf("failed to read existing certificate: %v", err)
	}

	// Check if content is the same
	if bytes.Equal(existingContent, newCertContent) {
		logging.GetLogger().Debug("Certificate content is identical, no replacement needed")
		return false, nil
	}

	// Check if existing certificate is expired or near expiry
	isExpiredOrNear, err := c.isCertificateExpiredOrNearExpiry(certPath, 3) // 3 months threshold
	if err != nil {
		logging.GetLogger().Warn("Failed to check certificate expiry, will replace: %v", err)
		return true, nil
	}

	if isExpiredOrNear {
		logging.GetLogger().Info("Certificate is expired or near expiry, will replace")
		return true, nil
	}

	// Validate the new certificate to ensure it's not expired
	newCertExpired, err := c.isCertificateContentExpiredOrNearExpiry(newCertContent, 0) // Check if new cert is already expired
	if err != nil {
		return false, fmt.Errorf("failed to validate new certificate: %v", err)
	}

	if newCertExpired {
		return false, fmt.Errorf("new certificate is already expired or invalid")
	}

	// If existing cert is valid and new cert is different, replace it
	logging.GetLogger().Info("Certificate content differs and new certificate is valid, will replace")
	return true, nil
}

// isCertificateExpiredOrNearExpiry checks if a certificate file is expired or near expiry
func (c *Cluster) isCertificateExpiredOrNearExpiry(certPath string, monthsThreshold int) (bool, error) {
	certContent, err := os.ReadFile(certPath)
	if err != nil {
		return false, fmt.Errorf("failed to read certificate file: %v", err)
	}

	return c.isCertificateContentExpiredOrNearExpiry(certContent, monthsThreshold)
}

// isCertificateContentExpiredOrNearExpiry checks if certificate content is expired or near expiry
func (c *Cluster) isCertificateContentExpiredOrNearExpiry(certContent []byte, monthsThreshold int) (bool, error) {
	// Decode PEM block
	block, _ := pem.Decode(certContent)
	if block == nil {
		return false, fmt.Errorf("failed to decode PEM block")
	}

	// Parse certificate
	cert, err := x509.ParseCertificate(block.Bytes)
	if err != nil {
		return false, fmt.Errorf("failed to parse certificate: %v", err)
	}

	now := time.Now()

	// Check if certificate is expired
	if now.After(cert.NotAfter) {
		logging.GetLogger().Info("Certificate expired on %v", cert.NotAfter)
		return true, nil
	}

	// Check if certificate is near expiry (if monthsThreshold > 0)
	if monthsThreshold > 0 {
		thresholdDate := now.AddDate(0, monthsThreshold, 0)
		if thresholdDate.After(cert.NotAfter) {
			logging.GetLogger().Info("Certificate will expire on %v (within %d months)", cert.NotAfter, monthsThreshold)
			return true, nil
		}
	}

	logging.GetLogger().Debug("Certificate is valid until %v", cert.NotAfter)
	return false, nil
}
