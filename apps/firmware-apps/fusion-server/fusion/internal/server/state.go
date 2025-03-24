package server

import (
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"io"
	"net/http"
	"reflect"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/hashicorp/memberlist"
)

// StateManager manages a synchronized in-memory application state across distributed nodes.
// It supports subscriptions, versioning, and nested key access.
type StateManager struct {
	sync.RWMutex
	state       map[string]*api.StateEntry
	version     int64
	node        string
	subscribers []chan struct{}
}

// NewStateManager creates and initializes a new StateManager for the given node.
func NewStateManager(node string) *StateManager {
	stateManager := &StateManager{
		state:       make(map[string]*api.StateEntry),
		node:        node,
		subscribers: make([]chan struct{}, 0),
	}
	return stateManager
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
	sm.RLock()
	defer sm.RUnlock()

	parts := strings.Split(key, ".")
	var current any = TransformState(sm.state)
	logger := logging.GetLogger()

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

// ApplyUpdate applies a configuration update to the internal state and notifies subscribers.
func (sm *StateManager) ApplyUpdate(update api.ConfigUpdate) error {
	sm.Lock()
	defer sm.Unlock()

	if update.Clear {
		sm.state = make(map[string]*api.StateEntry)
		sm.version = update.Version
		sm.notifySubscribers()
		return nil
	}

	if len(update.Data) == 0 {
		return nil
	}

	for key, value := range update.Data {
		var newValue any
		if valueMap, ok := value.(map[string]any); ok {
			existingValue, exists := sm.state[key]
			if exists {
				existingData, isMap := existingValue.Data.(map[string]any)
				if isMap {
					newValue = mergeMaps(existingData, valueMap)
				} else {
					newValue = valueMap
				}
			} else {
				newValue = valueMap
			}
		} else {
			newValue = value
		}

		sm.state[key] = &api.StateEntry{
			Data:      newValue,
			Version:   update.Version,
			Timestamp: update.Time,
		}

		if update.Version > sm.version {
			sm.version = update.Version
		}
		sm.notifySubscribers()
	}
	return nil
}

// GetFullState returns a deep copy of the internal state including version and timestamp metadata.
func (sm *StateManager) GetFullState() map[string]*api.StateEntry {
	sm.RLock()
	defer sm.RUnlock()
	stateCopy := make(map[string]*api.StateEntry, len(sm.state))
	for k, v := range sm.state {
		entryCopy := api.StateEntry{
			Data:      v.Data,
			Version:   v.Version,
			Timestamp: v.Timestamp,
		}
		stateCopy[k] = &entryCopy
	}
	return stateCopy
}

// Subscribe registers a new listener to be notified when the state changes.
// Returns a buffered channel that will receive a signal on update.
func (sm *StateManager) Subscribe() chan struct{} {
	sm.Lock()
	defer sm.Unlock()
	ch := make(chan struct{}, 1)
	sm.subscribers = append(sm.subscribers, ch)
	return ch
}

// notifySubscribers sends update signals to all subscribed channels.
func (sm *StateManager) notifySubscribers() {
	for _, ch := range sm.subscribers {
		select {
		case ch <- struct{}{}:
		default:
		}
	}
}

// MergeRemoteState integrates a remote state into the local state if the remote version is newer.
func (sm *StateManager) MergeRemoteState(remoteState map[string]*api.StateEntry, sourceNodeID string) {
	sm.Lock()
	defer sm.Unlock()
	for key, remoteEntry := range remoteState {
		localEntry, exists := sm.state[key]
		if !exists || remoteEntry.Version > localEntry.Version {
			sm.state[key] = remoteEntry
			if remoteEntry.Version > sm.version {
				sm.version = remoteEntry.Version
			}
		}
	}
	sm.notifySubscribers()
}

// GetState returns the internal state map without making a copy.
func (sm *StateManager) GetState() map[string]*api.StateEntry {
	return sm.state
}

// SetState replaces the entire state map and updates the version timestamp.
func (sm *StateManager) SetState(state map[string]*api.StateEntry) {
	sm.RLock()
	defer sm.RUnlock()
	sm.state = state
	sm.version = time.Now().UnixNano()
	sm.notifySubscribers()
}

// ValidateMemberState fetches and compares state from other cluster members
// to check consistency. Logs any inconsistencies found.
func (sm *StateManager) ValidateMemberState(list *memberlist.Memberlist) {
	logger := logging.GetLogger()
	localState := sm.GetState()
	consistent := true
	members := list.Members()

	for _, member := range members {
		if member.State != memberlist.StateAlive || member.Name == list.LocalNode().Name {
			continue
		}

		url := fmt.Sprintf("http://%s%s/export", member.Addr.String(), api.HTTPPort)
		resp, err := http.Get(url)
		if err != nil {
			logger.Warn("Failed to get state from %s: %v", member.Name, err)
			continue
		}

		body, err := io.ReadAll(resp.Body)
		resp.Body.Close()
		if err != nil {
			logger.Warn("Error reading response body from %s: %v", member.Name, err)
			continue
		}

		var remoteState api.RawState
		if err := json.Unmarshal(body, &remoteState); err != nil {
			logger.Warn("Failed to unmarshal JSON from %s: %v. Raw JSON: %s", member.Name, err, string(body))
			continue
		}

		if !reflect.DeepEqual(localState, remoteState.State) {
			logger.Warn("[STATE] Inconsistent state detected with node %s", member.Name)
			consistent = false
		}
	}

	if consistent {
		logger.Info("[STATE] State consistent across cluster")
	}
}

// TransformState removes metadata and returns a simplified map of key-value data from the state.
func TransformState(state map[string]*api.StateEntry) map[string]any {
	result := make(map[string]any)
	for key, entry := range state {
		result[key] = entry.Data
	}
	return result
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
