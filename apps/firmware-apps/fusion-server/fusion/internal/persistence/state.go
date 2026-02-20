package persistence

import (
	"bytes"
	"fmt"
	"fusion/internal/api"
	"fusion-services-core/logging"
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
)

// StateManagerInterface defines the interface for state management
type StateManagerInterface interface {
	GetFullState() VersionedState
}

// VersionedState represents a version of instance state
type VersionedState struct {
	State    map[string]*api.StateEntry
	Checksum string
}

// Flatten returns a simplified map of key-value data from the state
func (v *VersionedState) Flatten() map[string]any {
	result := make(map[string]any, len(v.State))
	for k, e := range v.State {
		if e != nil {
			result[k] = e.Data
		}
	}
	return result
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
		httpClient: &http.Client{Timeout: api.HTTPTimeout},
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

	copied := utils.DeepCopy(value)
	data := map[string]any{key: copied}

	hash, err := utils.JSONChecksum(data)
	if err != nil {
		return fmt.Errorf("failed to generate hash: %w", err)
	}

	sm.Lock()
	sm.version.Counter++
	localVersion := sm.version
	sm.Unlock()

	update := api.ConfigUpdate{
		Hash:    hash,
		Data:    data,
		Version: localVersion,
		Clear:   false,
	}

	_, err = sm.ApplyUpdate(update)
	return err
}

// Patch applies an updated patch to the internal state.
func (sm *StateManager) Patch(update map[string]any) (*map[string]any, error) {
	sm.Lock()

	// Apply patch to full current state snapshot
	existing := sm.getFullStateUnsafe()
	before := utils.DeepCopy(existing)

	if err := utils.ApplyPatch(existing, update); err != nil {
		sm.Unlock()
		return nil, fmt.Errorf("failed to apply patch: %w", err)
	}

	// Calculate the difference between the original and updated configuration.
	changed := utils.CalculateDiff(before, existing)
	if changed == nil {
		sm.Unlock()
		return nil, nil
	}

	sm.version.Counter++
	localVersion := sm.version

	sm.Unlock()

	configUpdate := api.ConfigUpdate{
		Data:    existing,
		Version: localVersion,
		Clear:   false,
	}

	hash, err := utils.JSONChecksum(existing)
	if err != nil {
		return nil, fmt.Errorf("failed to checksum patched config: %w", err)
	}
	configUpdate.Hash = hash

	if _, err := sm.ApplyUpdate(configUpdate); err != nil {
		return nil, err
	}

	return &existing, nil
}

// ApplyUpdate applies a ConfigUpdate received via memberlist replication.
//
//	ConfigUpdate is not a patch. It is not merged deeply.
//	For each top-level key in update.Data, ApplyUpdate treats the incoming
//	value as the complete authoritative snapshot for that key.
//
//	That means:
//	    - Scalar or array values overwrite directly.
//	    - Map values overwrite the entire existing map for that key.
//	    - Nested keys that existed locally but not in the incoming update
//	      are intentionally discarded.
//
//	This is correct and intentional for cluster replication. PATCH updates
//	(via HTTP) apply deep/partial updates locally, and THEN broadcast a
//	new ConfigUpdate snapshot with a fresh Lamport version so other nodes
//	accept it.
//
//	ApplyUpdate simply converges nodes toward the same snapshot, using
//	Lamport timestamps to maintain causal ordering.
//
// Summary:
//
//	PATCH       = local deep/partial edits
//	ApplyPatch  = merges into existing hierarchical state
//	ConfigUpdate/ApplyUpdate = replicate authoritative state snapshots
func (sm *StateManager) ApplyUpdate(update api.ConfigUpdate) (bool, error) {

	sm.Lock()
	defer sm.Unlock()

	incoming := update.Version
	local := sm.version

	// Reject stale epoch
	if incoming.Epoch < local.Epoch {
		return false, nil
	}

	// Adopt future epoch (snapshot activated on another node)
	if incoming.Epoch > local.Epoch {
		// Adopt new epoch and counter
		sm.version.Epoch = incoming.Epoch
		sm.version.Counter = incoming.Counter
		goto apply
	}

	// Same epoch: Do normal Lamport logic
	if local.Counter < incoming.Counter {
		sm.version.Counter = incoming.Counter
	}
	sm.version.Counter++

apply:
	// Apply update using effective version
	effective := sm.version

	dirty, err := sm.applyWhileLocked(update, incoming, effective)
	if err != nil {
		return false, err
	}

	if dirty {
		sm.updateChecksumUnsafe()
	}

	return dirty, nil
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

// applyWhileLocked applies a configuration update to the internal state,
// performing a Lamport-aware version check and merging nested maps when needed.
// sm.Lock() must already be held.
func (sm *StateManager) applyWhileLocked(
	update api.ConfigUpdate,
	incomingVersion api.Version,
	effectiveVersion api.Version,
) (bool, error) {

	logger := logging.GetLogger()
	dirty := false

	if update.Clear {
		// Clear the entire versioned state. The Lamport clock has already
		// been advanced in ApplyUpdate, so do not modify it here.
		sm.state = *NewVersionedState()
		dirty = true
	}

	// If we are not clearing and there is no data, nothing to do.
	if !update.Clear && len(update.Data) == 0 {
		return dirty, nil
	}

	for key, rawValue := range update.Data {
		localEntry, exists := sm.state.State[key]

		// Skip if the local entry version is newer or equal to the incoming
		// update's version for this key.
		//
		// Important: we compare against incomingVersion (the timestamp of the
		// originating event), not effectiveVersion (the local receive event).
		if exists && !localEntry.Version.Less(incomingVersion) {
			logger.Info("------>>> Skipping key %q: local version is newer or equal", key)
			logger.Info("incoming.Version: %d local.Version %d", incomingVersion.Counter, localEntry.Version.Counter)
			logger.Info("incoming.Epoch: %d local.Epoch %d", incomingVersion.Epoch, localEntry.Version.Epoch)
			continue
		}

		// Determine new data: merge maps or overwrite.
		var newData any
		if incomingMap, ok := rawValue.(map[string]any); ok {
			// Treat incoming map as the authoritative snapshot for this top-level key.
			// This ensures that deletions (keys removed in the patched state) are preserved,
			// instead of being merged with stale keys from the old state.
			newData = utils.DeepCopy(incomingMap)
		} else {
			// Non-map value; overwrite directly.
			newData = rawValue
		}

		// Store the new entry with the effective local version (the receive event).
		sm.state.State[key] = &api.StateEntry{
			Data:    newData,
			Version: effectiveVersion,
		}

		dirty = true
	}

	return dirty, nil
}

// GetFullState returns the internal state after deep copy.
func (sm *StateManager) GetFullState() VersionedState {
	sm.RLock()
	defer sm.RUnlock()

	return VersionedState{
		Checksum: sm.state.Checksum,
		State:    deepCopyState(sm.state.State),
	}
}

// GetFullStateRaw returns the raw state data with metadata.
func (sm *StateManager) GetFullStateRaw() map[string]any {
	sm.RLock()
	defer sm.RUnlock()
	return sm.getFullStateUnsafe()
}

// GetStateMap removes metadata and returns a simplified map of key-value data from the state.
func (sm *StateManager) GetStateMap() map[string]any {
	state := sm.GetFullState().State
	return utils.FlattenState(state)
}

// MergeRemoteState integrates a remote state into the local state if the remote version is newer.
func (sm *StateManager) MergeRemoteState(remoteState map[string]*api.StateEntry) {
	sm.Lock()
	defer sm.Unlock()

	for key, remoteEntry := range remoteState {

		localEntry, exists := sm.state.State[key]

		if !exists || localEntry.Version.Less(remoteEntry.Version) {
			sm.state.State[key] = deepCopyEntry(remoteEntry)

			if sm.version.Less(remoteEntry.Version) {
				sm.version = remoteEntry.Version
			}
		}
	}

	sm.updateChecksumUnsafe()
}

// ReplaceFullState does a global replacement of all state data
func (sm *StateManager) ReplaceFullState(newState map[string]*api.StateEntry, newVersion api.Version) {
	sm.Lock()
	defer sm.Unlock()

	sm.state.State = deepCopyState(newState)
	sm.version = newVersion
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

// BumpEpochLocked caller must hold sm.Lock()
func (sm *StateManager) BumpEpochLocked() api.Version {

	sm.version.Epoch++
	sm.version.Counter = 0
	return sm.version
}

func (sm *StateManager) BumpEpoch() api.Version {
	sm.Lock()
	defer sm.Unlock()
	return sm.BumpEpochLocked()
}

func (sm *StateManager) SetVersion(newVersion api.Version) {
	sm.Lock()
	defer sm.Unlock()
	sm.version = newVersion
}

func (sm *StateManager) GetMemberList() *memberlist.Memberlist {
	return sm.memberlist
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

func deepCopyEntry(src *api.StateEntry) *api.StateEntry {
	if src == nil {
		return nil
	}

	// Shallow copy of struct (copies Version by value)
	dst := *src
	dst.Data = utils.DeepCopy(src.Data)
	return &dst
}
