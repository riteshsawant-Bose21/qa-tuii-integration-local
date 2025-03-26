package server

import (
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/version"
	"strconv"
	"strings"
	"time"

	"github.com/hashicorp/memberlist"
)

// Handler is the common handler for both UDP and HTTP servers.
type Handler struct {
	stateManager *StateManager
	persistence  *Persistence
	list         *memberlist.Memberlist
	broadcasters []Broadcaster
	updater      *Updater
	endpoints    []string
}

func NewHandler(list *memberlist.Memberlist, stateManager *StateManager,
	persistence *Persistence, updater *Updater) *Handler {
	return &Handler{
		stateManager: stateManager,
		persistence:  persistence,
		list:         list,
		updater:      updater,
	}
}

func (h *Handler) SetEndpoints(endpoints []string) {
	h.endpoints = endpoints
}

func (h *Handler) GetInitialState() (WebSocketResponse, error) {
	data := TransformState(h.stateManager.GetFullState())
	return WebSocketResponse{
		Type: "initial_state",
		Data: data,
	}, nil
}

func (h *Handler) HandleHTTPGet(key string) (any, error) {
	if key != "" {
		value, exists := h.stateManager.Get(key)
		if !exists {
			return map[string]any{
				"exists": false,
				"error":  "key not found",
			}, nil
		}
		return map[string]any{
			"exists": true,
			"value":  value,
		}, nil
	}

	state := TransformState(h.stateManager.GetFullState())
	return state, nil
}

// HandleHTTPSet replaces the entire configuration state with the new data.
func (h *Handler) HandleHTTPSet(update map[string]any) (any, error) {
	// Clear all existing data before applying the update.
	h.HandleClearAllData()

	if err := h.handleConfigUpdate(update); err != nil {
		return nil, fmt.Errorf("failed to handle update: %w", err)
	}

	return map[string]any{
		"status":  "success",
		"updates": update,
	}, nil
}

// HandleHTTPPatch updates only the specified fields.
func (h *Handler) HandleHTTPPatch(value map[string]any) (any, error) {
	existingData := TransformState(h.stateManager.GetFullState())
	if err := applyPatch(existingData, value); err != nil {
		return nil, fmt.Errorf("failed to apply patch: %w", err)
	}

	if err := h.handleConfigUpdate(existingData); err != nil {
		return nil, fmt.Errorf("failed to handle update after patch: %w", err)
	}

	return existingData, nil
}

func (h *Handler) HandleClearAllData() error {
	configUpdate := api.ConfigUpdate{
		Data:    map[string]any{},
		Version: time.Now().UnixNano(),
		Time:    time.Now().UTC(),
		Clear:   true,
	}

	message := api.NotifyMessage{
		Operation:    api.NotifyOpConfigUpdate,
		Node:         h.stateManager.node,
		ConfigUpdate: &configUpdate,
	}

	if err := h.broadcastUpdate(message); err != nil {
		return fmt.Errorf("failed to clear all data: %w", err)
	}

	if err := h.persistence.SaveState(); err != nil {
		return fmt.Errorf("failed to persist cleared state: %w", err)
	}
	return nil
}

func (h *Handler) GetServerInfo() (map[string]any, error) {
	info := map[string]any{
		"name":       "Fusion Server",
		"version":    version.Version,
		"commit":     version.Commit,
		"build_time": version.BuildTime, "node_id": h.list.LocalNode().Name,
		"endpoints":          h.endpoints,
		"cluster_size":       len(h.list.Members()),
		"update_in_progress": h.updater.currentUpdate != nil,
	}

	if h.updater.currentUpdate != nil {
		info["update_status"] = map[string]any{
			"source_node": h.updater.currentUpdate.NodeID,
			"time":        h.updater.currentUpdate.Time,
			"progress":    float64(h.updater.currentAssembler.received) / float64(h.updater.currentAssembler.size) * 100,
		}
	}
	return info, nil
}

func (h *Handler) handleConfigUpdate(data map[string]any) error {

	configUpdate := api.ConfigUpdate{
		Data:    data,
		Version: time.Now().UnixNano(),
		Time:    time.Now().UTC(),
		Clear:   false,
	}

	message := api.NotifyMessage{
		Operation:    api.NotifyOpConfigUpdate,
		Node:         h.stateManager.node,
		ConfigUpdate: &configUpdate,
	}

	return h.broadcastUpdate(message)
}

func applyPatch(data map[string]any, changes map[string]any) error {
	for key, value := range changes {
		switch {
		case value == nil:
			removeNestedField(data, key)
		case isMap(value):
			subChanges := value.(map[string]any)
			if subData, ok := getNestedValue(data, key).(map[string]any); ok {
				if err := applyPatch(subData, subChanges); err != nil {
					return err
				}
			} else {
				newSubData := make(map[string]any)
				setNestedValue(data, key, newSubData)
				if err := applyPatch(newSubData, subChanges); err != nil {
					return err
				}
			}
		case isArray(value):
			subArray := value.([]any)
			existingValue := getNestedValue(data, key)
			if _, isExistingArray := existingValue.([]any); isExistingArray && !isIndexedKey(key) {
				setNestedValue(data, key, subArray)
			} else {
				if existingArray, ok := existingValue.([]any); ok {
					for i, v := range subArray {
						if i < len(existingArray) {
							existingArray[i] = v
						} else {
							return fmt.Errorf("index %d out of bounds for array %s", i, key)
						}
					}
					setNestedValue(data, key, existingArray)
				} else {
					setNestedValue(data, key, subArray)
				}
			}
		default:
			if err := updateNestedField(data, key, value); err != nil {
				return err
			}
		}
	}
	return nil
}

func isMap(v any) bool {
	_, ok := v.(map[string]any)
	return ok
}

func isArray(v any) bool {
	_, ok := v.([]any)
	return ok
}

// updateNestedField updates a nested field (supporting array indices) in a map.
func updateNestedField(data map[string]any, key string, value any) error {
	keys := parseKeyPath(key)
	for i := 0; i < len(keys)-1; i++ {
		subKey := keys[i]
		if index, isIndex := parseArrayIndex(subKey); isIndex {
			parentKey := keys[i-1]
			array, ok := data[parentKey].([]any)
			if !ok || index >= len(array) {
				return fmt.Errorf("index %d out of bounds for array %s", index, parentKey)
			}
			nestedMap, ok := array[index].(map[string]any)
			if !ok {
				return fmt.Errorf("expected map at index %d in array %s", index, parentKey)
			}
			data = nestedMap
		} else {
			if _, exists := data[subKey]; !exists {
				data[subKey] = make(map[string]any)
			}
			subData, ok := data[subKey].(map[string]any)
			if !ok {
				return fmt.Errorf("intermediate value for key %s is not a map", subKey)
			}
			data = subData
		}
	}

	finalKey := keys[len(keys)-1]
	if index, isIndex := parseArrayIndex(finalKey); isIndex {
		parentKey := keys[len(keys)-2]
		parentVal, exists := data[parentKey]
		if !exists {
			return fmt.Errorf("parent key %s does not exist", parentKey)
		}
		array, ok := parentVal.([]any)
		if !ok || index >= len(array) {
			return fmt.Errorf("index %d out of bounds for array %s", index, parentKey)
		}
		array[index] = value
	} else {
		data[finalKey] = value
	}
	return nil
}

func removeNestedField(data map[string]any, key string) {
	keys := parseKeyPath(key)
	// Traverse to the parent of the target key.
	for i := range len(keys) - 1 {
		subKey := keys[i]
		if subData, ok := data[subKey].(map[string]any); ok {
			data = subData
		} else {
			return // Key not found or not a map.
		}
	}
	finalKey := keys[len(keys)-1]
	if index, isIndex := parseArrayIndex(finalKey); isIndex {
		if array, ok := data[keys[len(keys)-2]].([]any); ok && index >= 0 && index < len(array) {
			data[keys[len(keys)-2]] = append(array[:index], array[index+1:]...)
		}
	} else if start, end, isSlice := parseArraySlice(finalKey); isSlice {
		if array, ok := data[keys[len(keys)-2]].([]any); ok && start >= 0 && end <= len(array) && start < end {
			data[keys[len(keys)-2]] = append(array[:start], array[end:]...)
		}
	} else {
		delete(data, finalKey)
	}
}

func getNestedValue(data map[string]any, key string) any {
	keys := parseKeyPath(key)
	current := any(data)
	for _, part := range keys {
		switch c := current.(type) {
		case map[string]any:
			val, exists := c[part]
			if !exists {
				return nil
			}
			current = val
		case []any:
			if index, isIndex := parseArrayIndex(part); isIndex {
				if index < 0 || index >= len(c) {
					return nil
				}
				current = c[index]
			} else if start, end, isSlice := parseArraySlice(part); isSlice {
				if start < 0 || end > len(c) || start >= end {
					return nil
				}
				return c[start:end]
			} else {
				return nil
			}
		default:
			return nil
		}
	}
	return current
}

func isIndexedKey(key string) bool {
	keys := parseKeyPath(key)
	lastKey := keys[len(keys)-1]
	_, isIndex := parseArrayIndex(lastKey)
	return isIndex
}

func ensureArrayCapacity(parent map[string]any, parentKey string, index int) {
	existingArray, exists := parent[parentKey].([]any)
	if !exists {
		parent[parentKey] = make([]any, index+1)
		return
	}
	if index < len(existingArray) {
		return
	}
	newArray := make([]any, index+1)
	copy(newArray, existingArray)
	parent[parentKey] = newArray
}

func setNestedValue(data map[string]any, key string, value any) {
	logger := logging.GetLogger()
	keys := parseKeyPath(key)
	current := data
	for i := 0; i < len(keys)-1; i++ {
		subKey := keys[i]
		if index, isIndex := parseArrayIndex(subKey); isIndex {
			if i == 0 {
				logger.Error("Array index cannot be at the root level.")
				return
			}
			parentKey := keys[i-1]
			parentVal, exists := current[parentKey]
			if !exists {
				logger.Warn("Parent key %s does not exist, skipping update.", parentKey)
				return
			}
			if _, ok := parentVal.([]any); !ok {
				logger.Error("Expected an array at key %s but got %T", parentKey, parentVal)
				return
			}
			ensureArrayCapacity(current, parentKey, index)
			arrayRef := current[parentKey].([]any)
			if index >= len(arrayRef) {
				logger.Error("Index %d out of bounds after ensureArrayCapacity", index)
				return
			}
			arrayRef[index] = value
			return
		} else {
			if _, exists := current[subKey]; !exists {
				// Create new container based on the next key.
				nextKey := keys[i+1]
				if _, isNextIndex := parseArrayIndex(nextKey); isNextIndex {
					current[subKey] = make([]any, 0)
				} else {
					current[subKey] = make(map[string]any)
				}
			}
			if subData, ok := current[subKey].(map[string]any); ok {
				current = subData
			} else if _, ok := current[subKey].([]any); ok {
				break
			} else {
				logger.Error("Intermediate value for key %s is not a map", subKey)
				return
			}
		}
	}
	finalKey := keys[len(keys)-1]
	if index, isIndex := parseArrayIndex(finalKey); isIndex {
		parentKey := keys[len(keys)-2]
		parentVal, exists := current[parentKey]
		if !exists {
			logger.Error("Parent key %s does not exist, skipping update.", parentKey)
			return
		}
		if _, ok := parentVal.([]any); !ok {
			logger.Error("Expected an array at key %s but got %T", parentKey, parentVal)
			return
		}
		ensureArrayCapacity(current, parentKey, index)
		arrayRef := current[parentKey].([]any)
		arrayRef[index] = value
	} else {
		current[finalKey] = value
	}
}

func parseArrayIndex(key string) (int, bool) {
	if i, err := strconv.Atoi(key); err == nil {
		return i, true
	}
	return -1, false
}

func parseArraySlice(key string) (int, int, bool) {
	if strings.Contains(key, ":") {
		parts := strings.Split(key, ":")
		start, err1 := strconv.Atoi(parts[0])
		end, err2 := strconv.Atoi(parts[1])
		if err1 == nil && err2 == nil {
			return start, end, true
		}
	}
	return -1, -1, false
}

func parseKeyPath(key string) []string {
	return strings.FieldsFunc(key, func(r rune) bool {
		return r == '.' || r == '[' || r == ']'
	})
}
