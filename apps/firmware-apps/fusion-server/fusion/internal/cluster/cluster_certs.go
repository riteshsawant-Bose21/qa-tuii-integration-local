package cluster

import (
	"bytes"
	"crypto/x509"
	"encoding/pem"
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/routes"
	"fusion/internal/utils"
	"io"
	"net"
	"net/http"
	"os"
	"strings"
	"time"
)

// GetLocalCSR returns the local device's CSR content.
func (c *Cluster) GetLocalCSR() ([]byte, error) {
	csrContent, err := os.ReadFile(fmt.Sprintf("%s%s", utils.DefaultIdentityFilePath, utils.DefaultCSRFileName))
	if err != nil {
		if os.IsNotExist(err) {
			return nil, fmt.Errorf("CSR file not found")
		}
		logging.GetLogger().Error("Error reading CSR file: %v", err)
		return nil, fmt.Errorf("Error reading CSR file: %v", err)
	}
	return csrContent, nil
}

// SetDeviceCertificate sets or updates the certificate for a device.
func (c *Cluster) SetDeviceCertificate(deviceID string, certPEM []byte) error {

	deviceInfos := c.fetchAllDeviceInfos()

	var targetDevice *api.DeviceInfo
	for idx, info := range deviceInfos {
		if info.Id == deviceID {
			targetDevice = &deviceInfos[idx]
			break
		}
	}

	if targetDevice == nil {
		return fmt.Errorf("Device %s not found", deviceID)
	}

	if len(certPEM) == 0 {
		return fmt.Errorf("Certificate data is empty")
	}

	if c.hostIsLocal(targetDevice.Address) {

		// Check if we should replace the certificate
		shouldReplace, err := shouldReplaceCertificate(fmt.Sprintf("%s%s", utils.DefaultIdentityFilePath, utils.DefaultCertFileName), certPEM)
		if err != nil {
			logging.GetLogger().Error("Error checking certificate replacement: %v", err)
			return err
		}

		if !shouldReplace {
			logging.GetLogger().Info("Certificate is still valid and not near expiry, skipping replacement")
			return nil
		}

		// If this is the local device, write certificate locally
		if err := os.WriteFile(fmt.Sprintf("%s%s", utils.DefaultIdentityFilePath, utils.DefaultCertFileName), certPEM, 0644); err != nil {
			logging.GetLogger().Error("Error writing certificate file: %v", err)
			return err
		}

		logging.GetLogger().Info("Certificate replaced successfully")

	} else {
		// Make HTTP POST request to the remote device's admin certificate endpoint
		deviceAddress := net.JoinHostPort(targetDevice.Address, api.AdminPort)
		endpoint := strings.Replace(routes.DevicesIDCertificateEndpoint, "{id}", deviceID, 1)
		url := getLocalURL(deviceAddress, endpoint)

		req, err := http.NewRequest(http.MethodPost, url, bytes.NewReader(certPEM))
		if err != nil {
			logging.GetLogger().Error("Error creating certificate request: %v", err)
			return err
		}
		req.Header.Set(api.ContentType, "text/plain")

		resp, err := c.httpClient.Do(req)
		if err != nil {
			logging.GetLogger().Error("Error sending certificate request: %v", err)
			return err
		}
		defer resp.Body.Close()

		body, _ := io.ReadAll(resp.Body)
		if resp.StatusCode != http.StatusNoContent {

			logging.GetLogger().Error("Remote certificate request to %s failed with status %d: %s", url, resp.StatusCode, string(body))
			return fmt.Errorf("remote certificate request failed with status %d: %s", resp.StatusCode, string(body))
		}

		logging.GetLogger().Info("Certificate replaced successfully on remote device")
	}

	return nil
}

// GetDeviceCSR retrieves the CSR for a specific device by ID.
func (c *Cluster) GetDeviceCSR(deviceID string) ([]byte, error) {

	deviceInfos := c.fetchAllDeviceInfos()

	var targetDevice *api.DeviceInfo
	for idx, info := range deviceInfos {
		if info.Id == deviceID {
			targetDevice = &deviceInfos[idx]
			break
		}
	}

	if targetDevice == nil {
		return nil, fmt.Errorf("Device %s not found", deviceID)
	}

	if c.hostIsLocal(targetDevice.Address) {
		// If this is the local device, call the local GetCSR function
		return c.GetLocalCSR()
	} else {
		// Make HTTP request to the remote device's admin CSR endpoint
		deviceAddress := net.JoinHostPort(targetDevice.Address, api.AdminPort)
		endpoint := strings.Replace(routes.DevicesGetCSREndpoint, "{id}", deviceID, 1)
		url := getLocalURL(deviceAddress, endpoint)

		resp, err := c.httpClient.Get(url)
		if err != nil {
			return nil, fmt.Errorf("failed to get CSR from device: %v", err)
		}
		defer resp.Body.Close()
		body, _ := io.ReadAll(resp.Body)

		if resp.StatusCode != http.StatusOK {
			logging.GetLogger().Error("Remote CSR request to %s failed with status %d: %s", url, resp.StatusCode, string(body))
			return nil, fmt.Errorf("device returned error: %s", string(body))
		}

		return body, nil
	}
}

// ResetDevice performs a reset on the specified device. If the device is local, it resets the local system. If the device is remote, it sends a reset request to that device.
func (c *Cluster) ResetDeviceCertificate(deviceID string) error {

	deviceInfos := c.fetchAllDeviceInfos()

	var targetDevice *api.DeviceInfo
	for idx, info := range deviceInfos {
		if info.Id == deviceID {
			targetDevice = &deviceInfos[idx]
			break
		}
	}

	if targetDevice == nil {
		return fmt.Errorf("device %s not found", deviceID)
	}

	if c.hostIsLocal(targetDevice.Address) {
		// If this is the local device, perform reset locally
		if err := resetLocalDevice(); err != nil {
			return fmt.Errorf("failed to reset device: %v", err)
		}
		return nil
	} else {
		// Make HTTP DELETE request to the remote device's admin reset endpoint
		deviceAddress := net.JoinHostPort(targetDevice.Address, api.AdminPort)
		endpoint := strings.Replace(routes.DevicesIDResetEndpoint, "{id}", deviceID, 1)
		url := getLocalURL(deviceAddress, endpoint)

		req, err := http.NewRequest(http.MethodDelete, url, nil)
		if err != nil {
			return fmt.Errorf("failed to create DELETE request: %v", err)
		}

		resp, err := c.httpClient.Do(req)
		if err != nil {
			return fmt.Errorf("failed to send reset request to device: %v", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusNoContent {
			body, _ := io.ReadAll(resp.Body)
			logging.GetLogger().Error("Remote reset request to %s failed with status %d: %s", url, resp.StatusCode, string(body))
			return fmt.Errorf("device returned error: %s", string(body))
		}
	}

	return nil
}

// resetLocalDevice performs the necessary steps to reset the local device, such as removing certificates
func resetLocalDevice() error {
	err := os.Remove(fmt.Sprintf("%s%s", utils.DefaultIdentityFilePath, utils.DefaultCertFileName))
	if err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("error removing certificate file: %v", err)
	}

	return nil
}

// shouldReplaceCertificate determines if a certificate should be replaced
// Returns true if:
// - The file doesn't exist
// - The existing certificate is expired
// - The existing certificate is near expiry (within 3 months)
// - The new certificate content is different from existing
func shouldReplaceCertificate(certPath string, newCertContent []byte) (bool, error) {
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
	isExpiredOrNear, err := isCertificateContentExpiredOrNearExpiry(existingContent, 3) // 3 months threshold
	if err != nil {
		logging.GetLogger().Warn("Failed to check certificate expiry, will replace: %v", err)
		return true, nil
	}

	if isExpiredOrNear {
		logging.GetLogger().Info("Certificate is expired or near expiry, will replace")
		return true, nil
	}

	// Validate the new certificate to ensure it's not expired
	newCertExpired, err := isCertificateContentExpiredOrNearExpiry(newCertContent, 0) // Check if new cert is already expired
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

// isCertificateContentExpiredOrNearExpiry checks if certificate content is expired or near expiry
func isCertificateContentExpiredOrNearExpiry(certContent []byte, monthsThreshold int) (bool, error) {
	// Decode PEM block
	block, _ := pem.Decode(certContent)
	if block == nil {
		return true, fmt.Errorf("failed to decode PEM block")
	}

	// Parse certificate
	cert, err := x509.ParseCertificate(block.Bytes)
	if err != nil {
		return true, fmt.Errorf("failed to parse certificate: %v", err)
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
