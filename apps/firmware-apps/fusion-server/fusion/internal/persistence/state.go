package persistence

import (
	"bytes"
	"encoding/json"
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

	"github.com/hashicorp/memberlist"
)

const (
	checkInterval = 30
	httpTimeout   = 5 * time.Second
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
	node       string
	version    int64
	httpClient *http.Client
	verbose    bool
}

// NewStateManager creates and initializes a new StateManager for the given node.
func NewStateManager(config *api.AppConfig) *StateManager {
	return &StateManager{
		state:      *NewVersionedState(),
		node:       config.NodeName,
		verbose:    config.Verbose,
		httpClient: &http.Client{Timeout: httpTimeout},
	}
}

// GetNode returns the node name
func (sm *StateManager) GetNode() string {
	return sm.node
}

// GetVersion returns the current version of the state.
func (sm *StateManager) GetVersion() int64 {
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
	data := map[string]any{
		key: value,
	}
	return sm.ApplyUpdate(api.ConfigUpdate{
		Data:    data,
		Version: time.Now().UnixNano(),
		Time:    time.Now().UTC(),
	})
}

// ApplyUpdate applies a configuration update to the internal state.
func (sm *StateManager) ApplyUpdate(update api.ConfigUpdate) error {
	sm.Lock()
	defer sm.Unlock()

	// Handle clear‐state flag
	if update.Clear {
		sm.state = *NewVersionedState()
		sm.version = update.Version
		// Recalculate checksum for the empty map
		checksum, err := utils.CalculateChecksum(sm.state.State)
		if err != nil {
			logging.GetLogger().Error("Failed to calculate checksum: %v", err)
			return err
		}
		sm.state.Checksum = checksum
		return nil
	}

	if len(update.Data) == 0 {
		return nil
	}

	// Track whether any key was added or updated
	dirty := false

	for key, rawValue := range update.Data {
		var incomingVersion int64
		var newValue any

		// Determine incomingVersion & newValue
		if valueMap, ok := rawValue.(map[string]any); ok {
			// per‐key version
			switch v := valueMap["version"].(type) {
			case int64:
				incomingVersion = v
			case float64:
				incomingVersion = int64(v)
			default:
				incomingVersion = update.Version
			}

			// merge vs overwrite
			if existingEntry, exists := sm.state.State[key]; exists {
				if incomingVersion <= existingEntry.Version {
					continue
				}
				if existingData, ok := existingEntry.Data.(map[string]any); ok {
					newValue = mergeMaps(existingData, valueMap)
				} else {
					newValue = valueMap
				}
			} else {
				newValue = valueMap
			}
		} else {
			incomingVersion = update.Version
			newValue = rawValue
		}

		// Skip stale
		if existingEntry, exists := sm.state.State[key]; exists {
			if incomingVersion <= existingEntry.Version {
				continue
			}
		}

		// Apply the change
		sm.state.State[key] = &api.StateEntry{
			Data:      newValue,
			Version:   incomingVersion,
			Timestamp: update.Time,
		}
		if incomingVersion > sm.version {
			sm.version = incomingVersion
		}
		dirty = true
	}

	// Only recalc checksum once
	if dirty {
		checksum, err := utils.CalculateChecksum(sm.state.State)
		if err != nil {
			logging.GetLogger().Error("Failed to calculate checksum: %v", err)
		} else {
			sm.state.Checksum = checksum
		}
	}

	return nil
}

// GetFullState returns the internal state
func (sm *StateManager) GetFullState() VersionedState {
	sm.RLock()
	defer sm.RUnlock()
	return sm.state
}

// GetStateMap removes metadata and returns a simplified map of key-value data from the state.
// Callers must not mutate the returned value.
func (sm *StateManager) GetStateMap() map[string]any {

	result := make(map[string]any)

	state := sm.GetFullState().State
	for key, entry := range state {
		result[key] = entry.Data
	}
	return result
}

// MergeRemoteState integrates a remote state into the local state if the remote version is newer.
func (sm *StateManager) MergeRemoteState(remoteState map[string]*api.StateEntry) {
	sm.Lock()
	defer sm.Unlock()
	for key, remoteEntry := range remoteState {
		localEntry, exists := sm.state.State[key]
		if !exists || remoteEntry.Version > localEntry.Version {
			sm.state.State[key] = remoteEntry
			if remoteEntry.Version > sm.version {
				sm.version = remoteEntry.Version
			}
		}
	}

	checksum, err := utils.CalculateChecksum(sm.state.State)
	if err != nil {
		logging.GetLogger().Error("Failed to calculate checksum: %v", err)
	}
	sm.state.Checksum = checksum
}

// SetState replaces the entire state map and updates the version timestamp.
func (sm *StateManager) SetState(state map[string]*api.StateEntry) {
	sm.Lock()
	defer sm.Unlock()
	sm.state.State = state
	checksum, err := utils.CalculateChecksum(state)
	if err != nil {
		logging.GetLogger().Error("Failed to calculate checksum: %v", err)
	}
	sm.state.Checksum = checksum
	sm.version = time.Now().UnixNano()
}

// validateState fetches and compares state from other cluster members
// to check consistency. Logs any inconsistencies found.
func (sm *StateManager) validateState(list *memberlist.Memberlist) {
	logger := logging.GetLogger()
	localState := sm.GetFullState()
	consistent := true
	members := list.Members()

	for _, member := range members {
		if member.State != memberlist.StateAlive || member.Name == list.LocalNode().Name {
			continue
		}

		url := buildInternalURL(member.Addr.String(), api.AdminPort, routes.StateEndpoint)
		resp, err := sm.httpClient.Get(url)
		if err != nil {
			logger.Warn("Failed to get state from %s: %v", member.Name, err)
			continue
		}

		defer resp.Body.Close()
		if resp.StatusCode < 200 || resp.StatusCode >= 300 {
			logger.Warn("Unexpected status %d", resp.StatusCode)
			continue
		}

		body, err := io.ReadAll(resp.Body)
		if err != nil {
			logger.Warn("Error reading response body from %s: %v", member.Name, err)
			continue
		}

		var remoteState VersionedState
		if err := json.Unmarshal(body, &remoteState); err != nil {
			logger.Warn("Failed to unmarshal JSON from %s: %v. Raw JSON: %s", member.Name, err, string(body))
			continue
		}

		if localState.Checksum != remoteState.Checksum {
			logger.Warn("[STATE] Inconsistent state detected with node %s", member.Name)
			logger.Debug("[STATE] Local checksum:  %s", localState.Checksum)
			logger.Debug("[STATE] Remote checksum: %s", remoteState.Checksum)

			consistent = false
		}
	}

	if consistent {
		logger.Debug("[STATE] Consistent across cluster")
		return
	}

}

// StartVerification starts periodic state verification
func (sm *StateManager) StartVerification(list *memberlist.Memberlist) {
	go func() {
		for {
			sm.validateState(list)
			sm.validateData(list)
			time.Sleep(checkInterval * time.Second)
		}
	}()
}

// getMemberData return MemberMetadata for all members of the memberlist cluster.
func (sm *StateManager) getMemberData(list *memberlist.Memberlist) []api.MemberMetadata {

	logger := logging.GetLogger()

	members := list.Members()

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

		defer resp.Body.Close()
		if resp.StatusCode < 200 || resp.StatusCode >= 300 {
			logger.Warn("Unexpected status %d", resp.StatusCode)
			continue
		}

		body, err := io.ReadAll(resp.Body)
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
func (sm *StateManager) validateData(list *memberlist.Memberlist) {

	logger := logging.GetLogger()

	memberMetadata := sm.getMemberData(list)

	if hashIsConsistent(memberMetadata) {
		logger.Debug("[DATA] Consistent across cluster")
		return
	}

	// Determine the node with the most recent timestamp.
	mostCurrent := memberMetadata[0]
	for _, ms := range memberMetadata[1:] {
		if ms.Metadata.Timestamp.After(mostCurrent.Metadata.Timestamp) {
			mostCurrent = ms
		}
	}
	logger.Info("Most current data found on member %s with timestamp %v",
		mostCurrent.Member.Name, mostCurrent.Metadata.Timestamp)

	exportURL := buildInternalURL(mostCurrent.Member.Addr.String(), api.AdminPort, routes.StateEndpoint)

	resp, err := sm.httpClient.Get(exportURL)
	if err != nil {
		logger.Error("Failed to export data from %s: %v", mostCurrent.Member.Name, err)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		logger.Error("Export returned %d: %s", resp.StatusCode, string(body))
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
