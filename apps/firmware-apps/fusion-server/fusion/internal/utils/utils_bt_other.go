//go:build !linux

package utils

import "fusion/internal/api"

func GetBluetoothMacAddress() string {
	return api.Unknown
}
