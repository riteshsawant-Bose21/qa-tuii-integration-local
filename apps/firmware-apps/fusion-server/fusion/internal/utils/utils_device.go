package utils

import (
	"bytes"
	"crypto/x509"
	"encoding/pem"
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/api"
	"net"
	"os"
	"time"
)

func GetModelName() string {
	return api.ModelUnknown
}

func GetFirmwareVersion() string {
	data, err := os.ReadFile(api.FirmwarePath)
	if err != nil {
		logging.GetLogger().Warn("%s not found.", api.FirmwarePath)
		return api.FirmwareUnknown
	} else {
		return string(bytes.TrimRight(data, "\x00\n"))
	}
}

func GetSerialNumber() string {
	data, err := os.ReadFile(api.SerialPath)
	if err != nil {
		logging.GetLogger().Warn("%s not found.", api.SerialPath)
		return api.SerialUnknown
	} else {
		return string(bytes.TrimRight(data, "\x00\n"))
	}
}

func GetMacAddress() string {
	macAddr, err := getMacAddress()
	if err != nil {
		logging.GetLogger().Warn("Unable to read MAC address: %v", err)
		return api.MacUnknown
	}
	return macAddr
}

func IsCertificateValid() bool {
	certContent, err := os.ReadFile(fmt.Sprintf("%s%s", api.DefaultIdentityFilePath, api.DefaultCertFileName))
	if err != nil {
		if os.IsNotExist(err) {
			logging.GetLogger().Warn("Certificate file not found.")
			return false
		}
		logging.GetLogger().Error("Error reading certificate file: %v", err)
		return false
	}

	isExpired, err := IsCertificateContentExpiredOrNearExpiry(certContent, 0) // Check if cert is expired
	if err != nil {
		logging.GetLogger().Error("Error checking certificate expiry: %v", err)
		return false
	}

	return !isExpired
}

// IsCertificateContentExpiredOrNearExpiry checks if certificate content is expired or near expiry
func IsCertificateContentExpiredOrNearExpiry(certContent []byte, monthsThreshold int) (bool, error) {
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

// getMacAddress returns the MAC address of the primary network interface
func getMacAddress() (string, error) {
	logger := logging.GetLogger()

	// Get the local IP to identify which interface is primary
	localIP, err := GetLocalIP()
	if err != nil {
		logger.Info("GetMacAddress: failed to get local IP: %v", err)
		return "", err
	}
	logger.Info("GetMacAddress: local IP is %s", localIP)

	// Get all network interfaces
	interfaces, err := net.Interfaces()
	if err != nil {
		logger.Info("GetMacAddress: failed to get network interfaces: %v", err)
		return "", err
	}
	logger.Info("GetMacAddress: found %d network interfaces", len(interfaces))

	// Find the interface with the matching IP
	for _, iface := range interfaces {
		addrs, err := iface.Addrs()
		if err != nil {
			continue
		}

		for _, addr := range addrs {
			ipNet, ok := addr.(*net.IPNet)
			if !ok {
				continue
			}

			// Check if this interface has our local IP
			if ipNet.IP.String() == localIP {
				// Return the hardware address (MAC)
				if len(iface.HardwareAddr) > 0 {
					macAddr := iface.HardwareAddr.String()
					logger.Info("GetMacAddress: found MAC address %s for interface %s", macAddr, iface.Name)
					return macAddr, nil
				}
			}
		}
	}

	logger.Info("GetMacAddress: no MAC address found for IP %s", localIP)
	return "", fmt.Errorf("no MAC address found for IP %s", localIP)
}
