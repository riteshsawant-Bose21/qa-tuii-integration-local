//go:build linux

package utils

import (
	"fusion-services-core/logging"
	"fusion/internal/api"

	"github.com/godbus/dbus/v5"
)

func GetBluetoothMacAddress() string {
	conn, err := dbus.ConnectSystemBus()
	if err != nil {
		logging.GetLogger().Warn("Unable to connect to D-Bus for BT MAC: %v", err)
		return api.Unknown
	}
	defer conn.Close()

	var managed map[dbus.ObjectPath]map[string]map[string]dbus.Variant
	obj := conn.Object("org.bluez", "/")
	if err := obj.Call("org.freedesktop.DBus.ObjectManager.GetManagedObjects", 0).Store(&managed); err != nil {
		logging.GetLogger().Warn("Unable to get BlueZ managed objects: %v", err)
		return api.Unknown
	}

	for _, ifaces := range managed {
		adapter, ok := ifaces["org.bluez.Adapter1"]
		if !ok {
			continue
		}
		if addrVariant, ok := adapter["Address"]; ok {
			if addr, ok := addrVariant.Value().(string); ok && addr != "" {
				return addr
			}
		}
	}
	logging.GetLogger().Warn("No Bluetooth adapter found via D-Bus")
	return api.Unknown
}
