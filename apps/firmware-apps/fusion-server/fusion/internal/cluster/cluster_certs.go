package cluster

import (
	"bytes"
	"crypto/x509"
	"encoding/pem"
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/persistence"
	"fusion/internal/routes"
	"fusion/internal/utils"
	"io"
	"net"
	"net/http"
	"os"
	"strings"
	"time"

	json "github.com/goccy/go-json"
)

// GetCSR returns the local device's CSR content.
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

// SetDeviceCertificate sets or updates the certificate for a device.
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

// GetDeviceCSR retrieves the CSR for a specific device by ID.
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

// ResetDevice performs a reset on the specified device. If the device is local, it resets the local system. If the device is remote, it sends a reset request to that device.
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

	w.WriteHeader(http.StatusNoContent)
}

// resetLocalDevice performs the necessary steps to reset the local device, such as removing certificates and updating device info.
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