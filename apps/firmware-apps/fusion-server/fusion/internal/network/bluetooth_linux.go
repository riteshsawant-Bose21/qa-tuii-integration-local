//go:build linux

package network

import (
	"github.com/go-ble/ble"
	"github.com/go-ble/ble/linux"
)

func newBLEDevice(name string) (ble.Device, error) {
	d, err := linux.NewDeviceWithName(name, ble.OptDeviceID(0))
	if err != nil {
		return nil, err
	}
	return d, nil
}
