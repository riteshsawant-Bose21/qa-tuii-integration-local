package persistence

import (
	"bytes"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/routes"
	"fusion/internal/utils"
	"io"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	json "github.com/goccy/go-json"

	"github.com/hashicorp/memberlist"
)

const (
	checkInterval = 30 * time.Second
	httpTimeout   = 5 * time.Second
)

// StateManagerInterface defines the interface for state management
type StateManagerInterface interface {
	GetFullStateDeepCopy() VersionedState
}

// VersionedState represents a version of instance state
type VersionedState struct {
	State    map[string]*api.StateEntry
	Checksum string
}

// NewVersionedState creates and initializes a new VersionedState
func NewVersionedState() *VersionedState {
	return &VersionedState{
		State: make(map[string]*api.StateEntry),
	}
}

// StateManager manages a synchronized in-memory application state across distributed nodes.
// It supports versioning, and nested key access.
type StateManager struct {
	sync.RWMutex
	state      VersionedState
	version    api.Version
	httpClient *http.Client
	memberlist *memberlist.Memberlist
	verbose    bool
}

// NewStateManager creates and initializes a new StateManager for the given node.
func NewStateManager(config *api.AppConfig) *StateManager {
	return &StateManager{
		state:      *NewVersionedState(),
		version:    api.Version{Counter: 0, NodeID: config.NodeName},
		httpClient: &http.Client{Timeout: httpTimeout},
		verbose:    config.Verbose,
	}
}

// NewConfigUpdate returns a configured ConfigUpdate
func (sm *StateManager) NewConfigUpdate(data map[string]any) (*api.ConfigUpdate, error) {

	sm.Lock()
	defer sm.Unlock()

	return sm.newConfigUpdateUnsafe(data)
}

// newConfigUpdateUnsafe assumes sm.Lock() is already held.
func (sm *StateManager) newConfigUpdateUnsafe(data map[string]any) (*api.ConfigUpdate, error) {
	hash, err := utils.JSONChecksum(data)
	if err != nil {
		return nil, fmt.Errorf("failed to generate hash: %w", err)
	}
	sm.version.Counter++
	v := sm.version
	return &api.ConfigUpdate{Hash: hash, Data: data, Version: v, Clear: false}, nil
}

// Start starts periodic state verification
func (sm *StateManager) Start(memberlist *memberlist.Memberlist) {

	sm.SetMemberlist(memberlist)

	go func() {
		for {
			sm.validateState()
			sm.validateData()
			time.Sleep(checkInterval)
		}
	}()
}

// GetNode returns the node name
func (sm *StateManager) GetNode() string {
	sm.RLock()
	defer sm.RUnlock()
	return sm.version.NodeID
}

func (sm *StateManager) SetMemberlist(memberlist *memberlist.Memberlist) {
	sm.Lock()
	defer sm.Unlock()
	sm.memberlist = memberlist
}

// GetVersion returns the current version of the state.
func (sm *StateManager) GetVersion() api.Version {
	sm.RLock()
	defer sm.RUnlock()
	return sm.version
}

// Get retrieves a nested value from the application's state using a dot-separated key path.
//
// Key Path Syntax:
//   - Dot-separated keys for nested maps: "settings.audio.volume"
//   - Array index access: "modifiers[0]"
//   - Array slice access: "modifiers[1:3]"
//
// Returns the found value and a boolean indicating if the key was found.
func (sm *StateManager) Get(key string) (any, bool) {

	logger := logging.GetLogger()

	var current any = sm.GetStateMap()

	parts := strings.Split(key, ".")

	for _, part := range parts {
		if strings.Contains(part, "[") && strings.Contains(part, "]") {
			keyPart := part[:strings.Index(part, "[")]
			arrayAccess := part[strings.Index(part, "[")+1 : strings.Index(part, "]")]

			nestedMap, ok := current.(map[string]any)
			if !ok {
				logger.Warn("%s is not a supported type. Current type: %T", part, current)
				return nil, false
			}

			value, exists := nestedMap[keyPart]
			if !exists {
				logger.Warn("%s not found.", keyPart)
				return nil, false
			}

			array, ok := value.([]any)
			if !ok {
				logger.Warn("%s is not an array. Current type: %T", keyPart, value)
				return nil, false
			}

			if strings.Contains(arrayAccess, ":") {
				rangeParts := strings.Split(arrayAccess, ":")
				start, end := 0, len(array)

				if rangeParts[0] != "" {
					startIndex, err := strconv.Atoi(rangeParts[0])
					if err != nil || startIndex < 0 || startIndex > len(array) {
						logger.Warn("Invalid start index in %s", arrayAccess)
						return nil, false
					}
					start = startIndex
				}
				if rangeParts[1] != "" {
					endIndex, err := strconv.Atoi(rangeParts[1])
					if err != nil || endIndex < start || endIndex > len(array) {
						logger.Warn("Invalid end index in %s", arrayAccess)
						return nil, false
					}
					end = endIndex
				}

				current = array[start:end]
			} else {
				index, err := strconv.Atoi(arrayAccess)
				if err != nil || index < 0 || index >= len(array) {
					logger.Warn("Invalid index %s in %s", arrayAccess, part)
					return nil, false
				}
				current = array[index]
			}
		} else {
			nestedMap, ok := current.(map[string]any)
			if !ok {
				logger.Warn("%s is not a supported type. Current type: %T", part, current)
				return nil, false
			}

			value, exists := nestedMap[part]
			if !exists {
				logger.Warn("%s not found.", part)
				return nil, false
			}

			current = value
		}
	}
	return current, true
}

// Set updates a key in the state with the given value and applies the update.
func (sm *StateManager) Set(key string, value any) error {

	data := map[string]any{key: value}
	hash, err := utils.JSONChecksum(data)
	if err != nil {
		return fmt.Errorf("failed to generate hash: %w", err)
	}

	sm.Lock()
	defer sm.Unlock()

	sm.version.Counter++
	update := api.ConfigUpdate{
		Hash:    hash,
		Data:    data,
		Version: sm.version,
		Clear:   false,
	}

	dirty, err := sm.applyWhileLocked(update)
	if err != nil {
		return err
	}

	if dirty {
		sm.updateChecksumUnsafe()
	}

	return nil
}

// ApplyPatch applies an upated patch to the internal state.
func (sm *StateManager) ApplyPatch(update map[string]any) (map[string]any, error) {
	sm.Lock()
	defer sm.Unlock()

	existing := sm.getFullStateUnsafe()
	if err := utils.ApplyPatch(existing, update); err != nil {
		return nil, fmt.Errorf("failed to apply patch: %w", err)
	}

	configUpdate, err := sm.newConfigUpdateUnsafe(existing)
	if err != nil {
		return nil, err
	}

	dirty, err := sm.applyWhileLocked(*configUpdate)
	if err != nil {
		return nil, err
	}

	if dirty {
		sm.updateChecksumUnsafe()
	}

	return existing, nil
}

// ApplyUpdate applies a configuration update to the internal state.
func (sm *StateManager) ApplyUpdate(update api.ConfigUpdate) error {
	sm.Lock()
	defer sm.Unlock()

	dirty, err := sm.applyWhileLocked(update)
	if err != nil {
		return err
	}

	if dirty {
		sm.updateChecksumUnsafe()
	}

	return nil
}

// updateChecksumUnsafe updates the checksum. Do not lock here.
func (sm *StateManager) updateChecksumUnsafe() {
	payload := sm.getFullStateUnsafe()
	if sum, err := utils.JSONChecksum(payload); err != nil {
		logging.GetLogger().Error("failed to calculate checksum: %v", err)
	} else {
		sm.state.Checksum = sum
	}
}

// applyLocked applies a configuration update to the internal state,
// performing a Lamport version check and merging nested maps when needed.
func (sm *StateManager) applyWhileLocked(update api.ConfigUpdate) (bool, error) {

	logger := logging.GetLogger()

	dirty := false

	if update.Clear {
		sm.state = *NewVersionedState()
		sm.version.Counter++
		dirty = true
	}

	// Bail out if there is nothing left to
	if !update.Clear && len(update.Data) == 0 {
		return dirty, nil
	}

	for key, rawValue := range update.Data {
		localEntry, exists := sm.state.State[key]

		// Skip if local version is newer or equal
		if exists && !localEntry.Version.Less(update.Version) {
			logger.Debug("Skipping: Local is newer or equal")
			continue
		}

		// Determine new data: merge maps or overwrite
		var newData any
		if incomingMap, ok := rawValue.(map[string]any); ok {
			if exists {
				if existingMap, ok2 := localEntry.Data.(map[string]any); ok2 {
					newData = mergeMaps(existingMap, incomingMap)
				} else {
					newData = incomingMap
				}
			} else {
				newData = incomingMap
			}
		} else {
			newData = rawValue
		}

		sm.state.State[key] = &api.StateEntry{
			Data:    newData,
			Version: update.Version,
		}

		if sm.version.Less(update.Version) {
			sm.version = update.Version
		}

		dirty = true
	}

	return dirty, nil
}

// GetFullState returns the internal state

// This returns a copy of the struct VersionedState by value,
// but in Go copying a struct that contains a map does NOT copy the map’s contents.
// It copies only the map header (a small descriptor) which still points to the
// SAME underlying map backing array/hash table. So after GetFullState() returns,
// the caller holds a struct whose State field is an alias of the original shared map.

func (sm *StateManager) GetFullState() VersionedState {
	sm.RLock()
	defer sm.RUnlock()
	return sm.state
}

// GetFullState returns the internal state after deep copy.
func (sm *StateManager) GetFullStateDeepCopy() VersionedState {
	sm.RLock()
	defer sm.RUnlock()

	return VersionedState{
		Checksum: sm.state.Checksum,
		State:    deepCopyState(sm.state.State),
	}
}

// GetStateMap removes metadata and returns a simplified map of key-value data from the state.
// Callers must not mutate the returned value.
func (sm *StateManager) GetStateMap() map[string]any {

	state := sm.GetFullStateDeepCopy().State

	result := make(map[string]any, len(state))
	for k, e := range state {
		if e != nil {
			result[k] = e.Data // already deep-copied inside GetFullStateDeepCopy
		}
	}
	return result

}

// MergeRemoteState integrates a remote state into the local state if the remote version is newer.
func (sm *StateManager) MergeRemoteState(remoteState map[string]*api.StateEntry) {

	sm.Lock()
	defer sm.Unlock()

	for key, remoteEntry := range remoteState {
		localEntry, exists := sm.state.State[key]

		// if we don’t have it yet, or the remote version is newer...
		if !exists || localEntry.Version.Less(remoteEntry.Version) {
			sm.state.State[key] = remoteEntry

			// bump our “highest‐seen” version if this remote one is newer
			if sm.version.Less(remoteEntry.Version) {
				sm.version = remoteEntry.Version
			}
		}
	}
	sm.updateChecksumUnsafe()
}

// SetState replaces the entire state map and advances the version.
func (sm *StateManager) SetState(state map[string]*api.StateEntry) {
	sm.Lock()
	sm.state.State = state
	sm.version.Counter++
	sm.Unlock()

	sm.updateChecksumUnsafe()
}

// validateState fetches and compares state from other cluster members
// to check consistency. Logs any inconsistencies found.
func (sm *StateManager) validateState() {
	logger := logging.GetLogger()

	sm.RLock()
	ml := sm.memberlist
	checksum := sm.state.Checksum
	sm.RUnlock()

	if ml == nil {
		logger.Warn("memberlist is not yet set")
		return
	}

	consistent := true
	localName := ml.LocalNode().Name

	for _, member := range ml.Members() {
		if member.State != memberlist.StateAlive || member.Name == localName {
			continue
		}

		url := buildInternalURL(member.Addr.String(), api.AdminPort, routes.StateEndpoint)
		resp, err := sm.httpClient.Get(url)
		if err != nil {
			logger.Warn("Failed to get state from %s: %v", member.Name, err)
			continue
		}

		if resp.StatusCode < 200 || resp.StatusCode >= 300 {
			logger.Warn("Unexpected status %d", resp.StatusCode)
			continue
		}

		body, err := io.ReadAll(resp.Body)
		resp.Body.Close()
		if err != nil {
			logger.Warn("Error reading response body from %s: %v", member.Name, err)
			continue
		}

		var remoteState VersionedState
		if err := json.Unmarshal(body, &remoteState); err != nil {
			logger.Warn("Failed to unmarshal JSON from %s: %v. Raw JSON: %s", member.Name, err, string(body))
			continue
		}

		if checksum != remoteState.Checksum {
			logger.Warn("[STATE] Inconsistent state detected with node %s", member.Name)
			if sm.verbose {
				logger.Debug("[STATE] Local checksum:  %s", checksum)
				logger.Debug("[STATE] Remote checksum: %s", remoteState.Checksum)
			}

			consistent = false
		}
	}

	if consistent {
		if sm.verbose {
			logger.Debug("[STATE] Consistent across cluster")
		}
		return
	}

}

// getMemberData return MemberMetadata for all members of the memberlist cluster.
func (sm *StateManager) getMemberData() []api.MemberMetadata {

	logger := logging.GetLogger()

	sm.RLock()
	ml := sm.memberlist
	sm.RUnlock()
	if ml == nil {
		return nil
	}

	members := ml.Members()

	var memberMetadata []api.MemberMetadata

	// Collect metadata for all alive members
	for _, member := range members {
		if member.State != memberlist.StateAlive {
			continue
		}

		url := buildInternalURL(member.Addr.String(), api.HTTPPort, routes.MetadataEndpoint)
		resp, err := sm.httpClient.Get(url)
		if err != nil {
			logger.Warn("Failed to get metadata from %s: %v", member.Name, err)
			continue
		}

		if resp.StatusCode < 200 || resp.StatusCode >= 300 {
			logger.Warn("Unexpected status %d", resp.StatusCode)
			continue
		}

		body, err := io.ReadAll(resp.Body)
		resp.Body.Close()
		if err != nil {
			logger.Warn("Error reading response body from %s: %v", member.Name, err)
			continue
		}

		var metadata api.DatabaseMetadata
		if err := json.Unmarshal(body, &metadata); err != nil {
			logger.Warn("Failed to unmarshal JSON from %s: %v. Raw JSON: %s", member.Name, err, string(body))
			continue
		}

		memberMetadata = append(memberMetadata, api.MemberMetadata{Member: member, Metadata: metadata})
	}

	return memberMetadata
}

// validateData resolves any mismatches in node data across cluster
// by picking the member with the highest Lamport version.
func (sm *StateManager) validateData() {
	logger := logging.GetLogger()

	memberMetadata := sm.getMemberData()
	if len(memberMetadata) == 0 {
		if sm.verbose {
			logger.Debug("[DATA] Empty member data")
		}
		return
	}

	if hashIsConsistent(memberMetadata) {
		if sm.verbose {
			logger.Debug("[DATA] Consistent across cluster")
		}
		return
	}

	// Pick the member whose metadata.Version is greatest.
	// (Version is your Lamport counter + node‐ID tie breaker.)
	mostCurrent := memberMetadata[0]
	for _, ms := range memberMetadata[1:] {
		if mostCurrent.Metadata.Version.Less(ms.Metadata.Version) {
			mostCurrent = ms
		}
	}

	logger.Info(
		"Most current data found on member %s with version %v",
		mostCurrent.Member.Name,
		mostCurrent.Metadata.Version,
	)

	exportURL := buildInternalURL(
		mostCurrent.Member.Addr.String(),
		api.AdminPort,
		routes.StateEndpoint,
	)

	resp, err := sm.httpClient.Get(exportURL)
	if err != nil {
		logger.Error("Failed to export data from %s: %v", mostCurrent.Member.Name, err)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, err := io.ReadAll(resp.Body)
		logger.Error("Export returned %v with body %s", err, string(body))
		return
	}

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		logger.Error("Failed to read body: %v", err)
		return
	}

	sm.syncData(memberMetadata, mostCurrent.Metadata.Hash, data)
	logger.Info("Successfully synced data")
}

// syncData propagate the data to all nodes with outdated data
func (sm *StateManager) syncData(memberMetadata []api.MemberMetadata, currentHash string, data []byte) {

	for _, ms := range memberMetadata {
		if ms.Metadata.Hash != currentHash {
			importURL := buildInternalURL(ms.Member.Addr.String(), api.AdminPort, routes.DataEndpoint)
			sm.importData(importURL, data)
		}
	}
}

// importData imports data into the state at the endpoint
func (sm *StateManager) importData(endpoint string, data []byte) {

	logger := logging.GetLogger()

	resp, err := sm.httpClient.Post(endpoint, api.JsonMIMEType, bytes.NewBuffer(data))
	if err != nil {
		logger.Error("Failed to import data on %s: %v", endpoint, err)
		return
	}

	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		logger.Error("Unexpected status code on: %s %d", endpoint, resp.StatusCode)
	}
}

// getFullStateUnsafe caller must hold sm.Lock or sm.RLock
func (sm *StateManager) getFullStateUnsafe() map[string]any {
	out := make(map[string]any, len(sm.state.State))
	for k, v := range sm.state.State {
		out[k] = utils.DeepCopy(v.Data)
	}
	return out
}

// hashIsConsistent checks if hash is consistent across all members
func hashIsConsistent(metadata []api.MemberMetadata) bool {
	if len(metadata) > 0 {
		firstHash := metadata[0].Metadata.Hash
		for _, ms := range metadata[1:] {
			if ms.Metadata.Hash != firstHash {
				return false
			}
		}
	}
	return true
}

// mergeMaps recursively merges two maps.
// Values from the update map overwrite or are merged into the existing map.
func mergeMaps(existing, update map[string]any) map[string]any {
	for key, value := range update {
		if vMap, ok := value.(map[string]any); ok {
			if existingMap, exists := existing[key].(map[string]any); exists {
				existing[key] = mergeMaps(existingMap, vMap)
			} else {
				existing[key] = vMap
			}
		} else {
			existing[key] = value
		}
	}
	return existing
}

func buildInternalURL(address, port, endpoint string) string {
	return fmt.Sprintf("%s%s:%s%s", api.Protocol, address, port, endpoint)
}

// deepCopyState makes a deep copy of the state map
func deepCopyState(src map[string]*api.StateEntry) map[string]*api.StateEntry {
	if src == nil {
		return nil
	}
	dst := make(map[string]*api.StateEntry, len(src))
	for k, v := range src {
		if v == nil {
			dst[k] = nil
			continue
		}
		// Create a copy of the struct, not the pointer
		c := *v                         // copy the struct
		c.Data = utils.DeepCopy(v.Data) // deep-copy the payload
		dst[k] = &c
	}
	return dst
}
