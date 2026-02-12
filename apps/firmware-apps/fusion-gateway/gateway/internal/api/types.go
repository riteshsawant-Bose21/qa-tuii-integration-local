package api

import (
	"fmt"
)

// AppConfig represents application configuration data
type AppConfig struct {
	NodeName string
	BindAddr string
	BindPort int
	// PublicPort is the listen port for gateway public API.
	PublicPort string
	// AdminPort is the listen port for gateway private/admin API.
	AdminPort string
	NetIface  string
	Local     bool
	Profile   bool
	Verbose   bool
	// PublicUpstreamFromVRRP enables VRRP-based discovery of the public upstream VIP.
	PublicUpstreamFromVRRP bool
	// PublicUpstreamVRRPTimeout controls how long to wait for a VRRP advertisement.
	PublicUpstreamVRRPTimeoutSec int
	// UpstreamPublicURL is the target for the public HTTP proxy.
	UpstreamPublicURL string
	// UpstreamPrivateURL is the target for the private/admin HTTP proxy.
	UpstreamPrivateURL string
}

func (a *AppConfig) SelfUrl() string {
	return fmt.Sprintf("http://%s:%s", a.BindAddr, a.PublicPort)
}

// Version encodes a Lamport counter plus the origin node's ID.
// https://en.wikipedia.org/wiki/Lamport_timestamp
type Version struct {
	Epoch   uint64 `json:"epoch"`
	Counter uint64 `json:"counter"`
	NodeID  string `json:"node_id"`
}

// Compare returns true if v is less than the other.
func (v Version) Less(other Version) bool {
	if v.Epoch != other.Epoch {
		return v.Epoch < other.Epoch
	}

	if v.Counter != other.Counter {
		return v.Counter < other.Counter
	}

	return v.NodeID < other.NodeID
}
