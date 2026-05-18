package api

import (
	"fmt"

	json "github.com/goccy/go-json"
)

// AppConfig represents application configuration data.
type AppConfig struct {
	NodeName       string
	BindAddr       string
	BindPort       int
	NetIface       string
	Local          bool
	Profile        bool
	UDPDiagnostics bool
	Verbose        bool
}

func (a *AppConfig) SelfUrl() string {
	return fmt.Sprintf("http://%s:%s", a.BindAddr, HTTPPort)
}

// ConfigUpdate represents a full or partial snapshot of state for a top-level key.
//
//   - ConfigUpdate is a replication primitive used by memberlist to achieve
//     eventual consistency with Lamport ordering.
//
//   - ConfigUpdate.Data does not behave like a PATCH. It is not a partial,
//     deep-merge update. Instead:
//
//     Each top-level entry in Data is considered a complete authoritative
//     snapshot for that key.
//
//     That means:
//
//     ConfigUpdate{Data: {"config": {"param2": "updated"}}}
//
//     replaces the entire "config" entry on receivers.
//
//   - Partial/deep/nested updates must use the HTTP PATCH system, which applies
//     rich semantics (array index updates, nested map merges, deletes, diffs).
//
// In short:
//
//	PATCH  = mutating local configuration with nested semantics
//	POST/PUT = full replacement
//	ConfigUpdate = replication of authoritative state snapshots across nodes.
//
// This separation keeps replication simple and Lamport-correct, while PATCH
// provides advanced local update semantics.
type ConfigUpdate struct {
	Hash         string         `json:"hash"`
	Data         map[string]any `json:"data"`
	ObserverData map[string]any `json:"observer_data,omitempty"`
	PathValues   map[string]any `json:"path_values,omitempty"`
	Version      Version        `json:"version"`
	Clear        bool           `json:"clear,omitempty"`
}

// ConfigValue represents a key/value pair.
type ConfigValue struct {
	Key   string          `json:"key"`
	Value json.RawMessage `json:"value,omitempty"`
}

// RemoteStateSnapshot is what we send/receive during anti-entropy.
type RemoteStateSnapshot struct {
	Version Version                `json:"version"`
	NodeID  string                 `json:"node_id"`
	State   map[string]*StateEntry `json:"state"`
}

// StateEntry represents a single entry in the state.
type StateEntry struct {
	Data           any                `json:"data"`
	Version        Version            `json:"version"`
	NestedVersions map[string]Version `json:"nested_versions,omitempty"`
}
