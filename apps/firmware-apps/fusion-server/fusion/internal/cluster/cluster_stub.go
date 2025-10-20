//go:build !linux
// +build !linux

package cluster

func (c *Cluster) watchLocalVIP() {
	// No-op on non-Linux systems
}
