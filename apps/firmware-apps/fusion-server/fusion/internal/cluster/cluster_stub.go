//go:build !linux
// +build !linux

package cluster

func (c *Cluster) watchLocalVIP(iface string) {
	// No-op on non-Linux systems
}
