//go:build darwin

package network

import (
	"github.com/go-ble/ble"
	"github.com/go-ble/ble/darwin"
)

func newBLEDevice(name string) (ble.Device, error) {
	// Name is applied when advertising.
	d, err := darwin.NewDevice()
	if err != nil {
		return nil, err
	}
	return d, nil
}
