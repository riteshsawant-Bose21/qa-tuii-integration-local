package cxd

import (
	"fmt"
	"net"
)

// NewDevice creates a new device instance
func NewDevice() *Device {
	return &Device{
		state: make(map[string]string),
	}
}

// SetValue sets a parameter value in device state
func (d *Device) SetValue(param, value string) {
	d.stateMux.Lock()
	defer d.stateMux.Unlock()
	d.state[param] = value
}

// GetValue gets a parameter value from device state
func (d *Device) GetValue(param string) (string, error) {
	d.stateMux.RLock()
	defer d.stateMux.RUnlock()

	value, exists := d.state[param]
	if !exists {
		return "", &DeviceError{
			Code:    "INVALID_PARAM",
			Message: fmt.Sprintf("parameter %s not found", param),
		}
	}
	return value, nil
}

// LoadConfig loads configuration into the device
func (d *Device) LoadConfig(cfg *Config) error {
	if cfg.Type != d.ModelID {
		return &DeviceError{
			Code:    "CONFIG_MISMATCH",
			Message: fmt.Sprintf("config type %s does not match device type %s", cfg.Type, d.ModelID),
		}
	}

	d.Name = cfg.Name
	d.StaticIP = cfg.IP
	d.SubnetMask = cfg.SubnetMask
	d.Gateway = cfg.Gateway
	d.DHCPEnabled = cfg.DHCPEnabled
	d.OperationMode = cfg.OperationMode

	return nil
}

// ToConfig creates a Config from the device
func (d *Device) ToConfig() *Config {
	return &Config{
		Type:          d.ModelID,
		Name:          d.Name,
		IP:            d.StaticIP,
		SubnetMask:    d.SubnetMask,
		Gateway:       d.Gateway,
		DHCPEnabled:   d.DHCPEnabled,
		OperationMode: d.OperationMode,
	}
}

// ClearConfig resets device configuration to defaults
func (d *Device) ClearConfig() {
	d.DHCPEnabled = true
	d.StaticIP = net.IPv4(0, 0, 0, 0)
	d.SubnetMask = net.IPv4Mask(255, 255, 255, 0)
	d.Gateway = net.IPv4(0, 0, 0, 0)
	d.OperationMode = OpModeCSP
}
