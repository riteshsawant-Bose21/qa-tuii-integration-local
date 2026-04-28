//go:build !linux

package network

import "net"

// sendBatch is a no-op on non-Linux platforms. Returns nil to indicate
// the caller should use the standard per-client WriteToUDP path.
func sendBatch(_ int, _ []byte, _ []clientTarget) []int {
	return nil
}

// extractUDPConnFd is not supported on non-Linux platforms.
func extractUDPConnFd(_ *net.UDPConn) (int, error) {
	return -1, nil
}
