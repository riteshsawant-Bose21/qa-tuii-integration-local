package cluster

import (
	"bytes"
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/network"
	"fusion/internal/utils"
	"os"
)

func (c *Cluster) getModelName() string {
	return modelUnknown
}

func (c *Cluster) getFirmwareVersion() string {
	data, err := os.ReadFile(firmwarePath)
	if err != nil {
		logging.GetLogger().Warn("%s not found.", firmwarePath)
		return firmwareUnknown
	} else {
		return string(bytes.TrimRight(data, "\x00\n"))
	}
}

func (c *Cluster) getSerialNumber() string {
	data, err := os.ReadFile(serialPath)
	if err != nil {
		logging.GetLogger().Warn("%s not found.", serialPath)
		return serialUnknown
	} else {
		return string(bytes.TrimRight(data, "\x00\n"))
	}
}

func (c *Cluster) getMacAddress() string {
	macAddr, err := network.GetMacAddress()
	if err != nil {
		logging.GetLogger().Warn("Unable to read MAC address: %v", err)
		return macUnknown
	}
	return macAddr
}

func (c *Cluster) isCertificateValid() bool {
	certContent, err := os.ReadFile(fmt.Sprintf("%s%s", utils.DefaultIdentityFilePath, utils.DefaultCertFileName))
	if err != nil {
		if os.IsNotExist(err) {
			logging.GetLogger().Warn("Certificate file not found.")
			return false
		}
		logging.GetLogger().Error("Error reading certificate file: %v", err)
		return false
	}

	isExpired, err := isCertificateContentExpiredOrNearExpiry(certContent, 0) // Check if cert is expired
	if err != nil {
		logging.GetLogger().Error("Error checking certificate expiry: %v", err)
		return false
	}

	return !isExpired
}
