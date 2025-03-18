package server

import (
	"fusion/internal/api"
	"fusion/internal/logging"
	"strconv"
	"strings"
	"sync"
	"time"
)

type StateManager struct {
	sync.RWMutex
	state       map[string]*api.StateEntry
	version     int64
	nodeID      string
	subscribers []chan struct{}
}

func NewStateManager(nodeID string, verbose bool) *StateManager {
	stateManager := &StateManager{
		state:       make(map[string]*api.StateEntry),
		nodeID:      nodeID,
		subscribers: make([]chan struct{}, 0),
	}

	return stateManager
}

func (sm *StateManager) GetVersion() int64 {
	sm.RLock()
	defer sm.RUnlock()
	return sm.version
}

// Get retrieves a nested value from the application's state using a dot-separated key path.
// It supports accessing map keys, array indices, and array slices.
//
// Key Path Syntax:
// - Dot-separated keys navigate through nested maps (e.g., "settings.audio.modifiers").
// - Array indices can be used to retrieve a specific element (e.g., "settings.audio.modifiers[0]").
// - Array slicing allows retrieving a subset of elements (e.g., "settings.audio.modifiers[1:3]").
//
// Parameters:
// - key (string): A dot-separated key path that may include array indexing or slicing.
//
// Returns:
// - (any, bool): The retrieved value and a boolean indicating whether the key was found.
func (sm *StateManager) Get(key string) (any, bool) {
	sm.RLock()
	defer sm.RUnlock()

	// Split the key into parts using the dot separator
	parts := strings.Split(key, ".")

	// Start traversing the state from the root
	var current any = TransformState(sm.state)

	for _, part := range parts {
		// Check if the part contains array indexing or slicing
		if strings.Contains(part, "[") && strings.Contains(part, "]") {
			// Split the part into the key and the array access part
			keyPart := part[:strings.Index(part, "[")]
			arrayAccess := part[strings.Index(part, "[")+1 : strings.Index(part, "]")]

			// Type assert current as a map to continue traversal
			nestedMap, ok := current.(map[string]any)
			if !ok {
				logging.GetLogger().Warn("%s is not a supported type. Current type: %T", part, current)
				return nil, false
			}

			// Look up the keyPart in the map
			value, exists := nestedMap[keyPart]
			if !exists {
				logging.GetLogger().Warn("%s not found.", keyPart)
				return nil, false
			}

			// Type assert value as an array (slice)
			array, ok := value.([]any)
			if !ok {
				logging.GetLogger().Warn("%s is not an array. Current type: %T", keyPart, value)
				return nil, false
			}

			// Handle array access (indexing or slicing)
			if strings.Contains(arrayAccess, ":") {
				// Slice syntax
				rangeParts := strings.Split(arrayAccess, ":")
				start, end := 0, len(array)

				// Parse start index
				if rangeParts[0] != "" {
					startIndex, err := strconv.Atoi(rangeParts[0])
					if err != nil || startIndex < 0 || startIndex > len(array) {
						logging.GetLogger().Warn("Invalid start index in %s", arrayAccess)
						return nil, false
					}
					start = startIndex
				}

				// Parse end index
				if rangeParts[1] != "" {
					endIndex, err := strconv.Atoi(rangeParts[1])
					if err != nil || endIndex < start || endIndex > len(array) {
						logging.GetLogger().Warn("Invalid end index in %s", arrayAccess)
						return nil, false
					}
					end = endIndex
				}

				// Return the sliced array
				current = array[start:end]
			} else {
				// Index syntax
				index, err := strconv.Atoi(arrayAccess)
				if err != nil || index < 0 || index >= len(array) {
					logging.GetLogger().Warn("Invalid index %s in %s", arrayAccess, part)
					return nil, false
				}

				// Return the indexed value
				current = array[index]
			}
		} else {
			// Type assert current as a map to continue traversal
			nestedMap, ok := current.(map[string]any)
			if !ok {
				logging.GetLogger().Warn("%s is not a supported type. Current type: %T", part, current)
				return nil, false
			}

			// Look up the current key part in the map
			value, exists := nestedMap[part]
			if !exists {
				logging.GetLogger().Warn("%s not found.", part)
				return nil, false
			}

			// Move to the next level
			current = value
		}
	}

	// Return the final value found
	return current, true
}

func (sm *StateManager) Set(key string, value any) error {
	data := map[string]any{
		key: value,
	}
	return sm.ApplyUpdate(api.ConfigUpdate{
		Data:    data,
		Version: time.Now().UnixNano(),
		NodeID:  sm.nodeID,
		Time:    time.Now().UTC(),
	})
}

// ApplyUpdate applies a configuration update to the StateManager.
// and notifies subscribers of any changes.
func (sm *StateManager) ApplyUpdate(update api.ConfigUpdate) error {
	sm.Lock()
	defer sm.Unlock()

	// If the Clear flag is set, clear the state and return immediately.
	if update.Clear {
		sm.state = make(map[string]*api.StateEntry)
		sm.version = update.Version
		sm.notifySubscribers()
		return nil
	}

	// If there's no data to apply, do nothing.
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

func (sm *StateManager) Subscribe() chan struct{} {
	sm.Lock()
	defer sm.Unlock()
	ch := make(chan struct{}, 1)
	sm.subscribers = append(sm.subscribers, ch)
	return ch
}

func (sm *StateManager) notifySubscribers() {
	for _, ch := range sm.subscribers {
		select {
		case ch <- struct{}{}:
		default:
		}
	}
}

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

func TransformState(state map[string]*api.StateEntry) map[string]any {
	result := make(map[string]any)
	for key, entry := range state {
		result[key] = entry.Data
	}
	return result
}

func (sm *StateManager) GetState() map[string]*api.StateEntry {
	return sm.state
}

func (sm *StateManager) SetState(state map[string]*api.StateEntry) {
	sm.RLock()
	defer sm.RUnlock()
	sm.state = state
	sm.version = time.Now().UnixNano()
	sm.notifySubscribers()
}

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
