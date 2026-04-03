//go:build linux

package network

func newPlatformBLETransport(name string, serviceUUID string, characterUUID string, bridge *bluetoothBridge) (bluetoothTransport, error) {
	return newBlueZTransport(name, serviceUUID, characterUUID, bridge)
}
