package handler

import (
	"bytes"
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/routes"
	"fusion/internal/utils"
	"io"
	"net/http"
	"os"
)

func (h *Handler) HandleGetDevicesInfo() []api.DeviceInfo {
	return h.clusterTransport.GetAllDevicesInfo()
}

func (h *Handler) HandleGetDeviceInfo() api.DeviceInfo {
	return h.clusterTransport.GetDeviceInfoLocal()
}

func (h *Handler) HandleUpdateDeviceInfo(deviceID string, patch api.DevicePatch) error {
	return h.clusterTransport.UpdateDeviceInfo(deviceID, &patch)
}

func (h *Handler) HandleUpdateDeviceInfoLocal(patch api.DevicePatch) error {
	return h.clusterTransport.UpdateDeviceInfoLocal(&patch)
}

// HandleGetCSR retrieves the CSR for the specified device ID. If the target device ID is the local device, it will read the CSR from the local file system. If the target device is remote, it will send a request to the remote device to fetch its CSR.
func (h *Handler) HandleGetCSR(deviceID string) ([]byte, error) {
	return h.clusterTransport.FetchGenericWithTargetDevice(
		deviceID,
		routes.DevicesGetCSREndpoint,
		h.getLocalCSR,
		h.getRemoteCSR,
	)
}

// HandleSetDeviceCertificate sets the device certificate for the specified device ID. If the target device ID is the local device, it will write the certificate to the local file system. If the target device is remote, it will send a request to the remote device to set its certificate.
func (h *Handler) HandleSetDeviceCertificate(deviceID string, certPEM []byte) error {
	return h.clusterTransport.DoGenericToTargetDevice(
		deviceID,
		routes.DevicesIDCertificateEndpoint,
		certPEM,
		h.setLocalCertificate,
		h.setRemoteCertificate,
	)
}

// ResetDeviceCertificate resets the device certificate for the specified device ID. If the target device ID is the local device, it will remove the certificate file from the local file system. If the target device is remote, it will send a request to the remote device to reset its certificate.
func (h *Handler) ResetDeviceCertificate(deviceID string) error {
	return h.clusterTransport.DoGenericToTargetDevice(
		deviceID,
		routes.DevicesIDResetEndpoint,
		nil,
		h.resetLocalDeviceCertificate,
		h.resetRemoteDeviceCertificate,
	)
}

// GetLocalCSR returns the local device's CSR content.
func (h *Handler) getLocalCSR() ([]byte, error) {
	csrContent, err := os.ReadFile(fmt.Sprintf("%s%s", api.DefaultIdentityFilePath, api.DefaultCSRFileName))
	if err != nil {
		if os.IsNotExist(err) {
			return nil, err
		}
		logging.GetLogger().Error("Error reading CSR file: %v", err)
		return nil, fmt.Errorf("Error reading CSR file: %v", err)
	}
	return csrContent, nil
}

// getRemoteCSR sends a request to the remote device to fetch its CSR content
func (h *Handler) getRemoteCSR(url string) ([]byte, error) {
	resp, err := h.httpClient.Get(url)
	if err != nil {
		return nil, fmt.Errorf("failed to get CSR from device: %v", err)
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		logging.GetLogger().Error("Error reading response body: %v", err)
		return nil, fmt.Errorf("error reading response body: %v", err)
	}

	if resp.StatusCode != http.StatusOK {
		logging.GetLogger().Error("Remote CSR request to %s failed with status %d: %s", url, resp.StatusCode, string(body))
		return nil, fmt.Errorf("device returned error: %s", string(body))
	}

	return body, nil
}

// setLocalCertificate writes the provided certificate content to the local file system, replacing the existing certificate if necessary
func (h *Handler) setLocalCertificate(certPEM []byte) error {

	// Check if we should replace the certificate
	shouldReplace, err := shouldReplaceCertificate(fmt.Sprintf("%s%s", api.DefaultIdentityFilePath, api.DefaultCertFileName), certPEM)
	if err != nil {
		logging.GetLogger().Error("Error checking certificate replacement: %v", err)
		return err
	}

	if !shouldReplace {
		logging.GetLogger().Info("Certificate is still valid and not near expiry, skipping replacement")
		return nil
	}

	// If this is the local device, write certificate locally
	if err := os.WriteFile(fmt.Sprintf("%s%s", api.DefaultIdentityFilePath, api.DefaultCertFileName), certPEM, 0644); err != nil {
		logging.GetLogger().Error("Error writing certificate file: %v", err)
		return err
	}

	logging.GetLogger().Info("Certificate replaced successfully")
	return nil
}

// setRemoteCertificate sends the provided certificate content to the remote device to replace its certificate
func (h *Handler) setRemoteCertificate(certPEM []byte, url string) error {
	req, err := http.NewRequest(http.MethodPost, url, bytes.NewReader(certPEM))
	if err != nil {
		logging.GetLogger().Error("Error creating certificate request: %v", err)
		return err
	}
	req.Header.Set(api.ContentType, "text/plain")

	resp, err := h.httpClient.Do(req)
	if err != nil {
		logging.GetLogger().Error("Error sending certificate request: %v", err)
		return err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		logging.GetLogger().Error("Error reading response body: %v", err)
		return fmt.Errorf("error reading response body: %v", err)
	}

	if resp.StatusCode != http.StatusNoContent {

		logging.GetLogger().Error("Remote certificate request to %s failed with status %d: %s", url, resp.StatusCode, string(body))
		return fmt.Errorf("remote certificate request failed with status %d: %s", resp.StatusCode, string(body))
	}

	logging.GetLogger().Info("Certificate replaced successfully on remote device")

	return nil
}

// resetLocalDeviceCertificate removes device certificate file from local file system
func (h *Handler) resetLocalDeviceCertificate(payload []byte) error {
	err := os.Remove(fmt.Sprintf("%s%s", api.DefaultIdentityFilePath, api.DefaultCertFileName))
	if err != nil {
		if os.IsNotExist(err) {
			logging.GetLogger().Info("Certificate file already does not exist, nothing to remove")
			return nil
		}
		return fmt.Errorf("error removing certificate file: %v", err)
	}

	return nil
}

// resetRemoteDeviceCertificate sends a request to the remote device to reset/remove its certificate
func (h *Handler) resetRemoteDeviceCertificate(payload []byte, url string) error {
	req, err := http.NewRequest(http.MethodDelete, url, nil)
	if err != nil {
		return fmt.Errorf("failed to create DELETE request: %v", err)
	}

	resp, err := h.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send reset request to device: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusNoContent {
		body, err := io.ReadAll(resp.Body)
		if err != nil {
			logging.GetLogger().Error("Error reading response body: %v", err)
			return fmt.Errorf("error reading response body: %v", err)
		}
		logging.GetLogger().Error("Remote reset request to %s failed with status %d: %s", url, resp.StatusCode, string(body))
		return fmt.Errorf("device returned error: %s", string(body))
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
	isExpiredOrNear, err := utils.IsCertificateContentExpiredOrNearExpiry(existingContent, 3) // 3 months threshold
	if err != nil {
		logging.GetLogger().Warn("Failed to check certificate expiry, will replace: %v", err)
		return true, nil
	}

	if isExpiredOrNear {
		logging.GetLogger().Info("Certificate is expired or near expiry, will replace")
		return true, nil
	}

	// Validate the new certificate to ensure it's not expired
	newCertExpired, err := utils.IsCertificateContentExpiredOrNearExpiry(newCertContent, 0) // Check if new cert is already expired
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
