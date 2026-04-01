//go:build darwin

package network

import (
	"github.com/go-ble/ble"
	"github.com/go-ble/ble/darwin"
)

func newPlatformBLETransport(name string, serviceUUID string, characterUUID string, bridge *bluetoothBridge) (bluetoothTransport, error) {
	return newGoBLETransport(name, serviceUUID, characterUUID, bridge)
}

func newBLEDevice(_ string) (ble.Device, error) {
	// Name is applied when advertising.
	d, err := darwin.NewDevice()
	if err != nil {
		return nil, err
	}
	return d, nil
}
