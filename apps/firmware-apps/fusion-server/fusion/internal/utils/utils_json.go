package utils

import (
	"fusion-services-core/logging"
	"strconv"
	"strings"
)

func ApplyPatch(data map[string]any, changes map[string]any) error {
	for key, value := range changes {

		// Delete
		if value == nil {
			if isIndexedKey(key) || isSliceKey(key) {
				removeArrayElement(data, key)
			} else {
				removeNestedField(data, key)
			}
			continue
		}

		// Nested map
		if isMap(value) {
			subChanges := value.(map[string]any)

			existing, ok := getNestedValue(data, key).(map[string]any)
			if !ok {
				existing = map[string]any{}
				setNestedMapContainer(data, key, existing)
			}

			if err := ApplyPatch(existing, subChanges); err != nil {
				return err
			}
			continue
		}

		// Array update
		if isArray(value) {
			arr := value.([]any)

			if !isIndexedKey(key) {
				setNestedValueRaw(data, key, arr)
			} else {
				// PATCH for one element: arr always len=1
				setArrayElement(data, key, arr[0])
			}
			continue
		}

		// Scaler update
		if isIndexedKey(key) {
			// Patch into existing array
			setArrayElement(data, key, value)
			continue
		}
		setNestedValueRaw(data, key, value)
	}
	return nil
}

func SetNestedValue(data map[string]any, key string, value any) {
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

func removeArrayElement(data map[string]any, key string) {
	parentPath, index := splitIndexedKey(key)

	raw := getNestedValue(data, parentPath)
	arr, ok := raw.([]any)
	if !ok {
		return
	}

	if index < 0 || index >= len(arr) {
		return
	}

	arr[index] = nil
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

func parseArrayIndex(key string) (int, bool) {
	i, err := strconv.Atoi(key)
	return i, err == nil
}

func parseArraySlice(key string) (int, int, bool) {
	if strings.Contains(key, ":") {
		parts := strings.Split(key, ":")
		if len(parts) == 2 {
			start, e1 := strconv.Atoi(parts[0])
			end, e2 := strconv.Atoi(parts[1])
			if e1 == nil && e2 == nil {
				return start, end, true
			}
		}
	}
	return -1, -1, false
}

func setArrayElement(data map[string]any, key string, value any) {
	parentPath, index := splitIndexedKey(key)

	raw := getNestedValue(data, parentPath)
	arr, ok := raw.([]any)
	if !ok {
		// create array if missing
		arr = make([]any, 0)
		setNestedValueRaw(data, parentPath, arr)
	}

	// expand array if needed
	if index >= len(arr) {
		newArr := make([]any, index+1)
		copy(newArr, arr)
		arr = newArr
		setNestedValueRaw(data, parentPath, arr)
	}

	arr[index] = value
}

func removeNestedField(data map[string]any, key string) {
	keys := parseKeyPath(key)

	for i := 0; i < len(keys)-1; i++ {
		next, ok := data[keys[i]].(map[string]any)
		if !ok {
			return
		}
		data = next
	}
	delete(data, keys[len(keys)-1])
}

func setNestedMapContainer(data map[string]any, key string, container map[string]any) {
	keys := parseKeyPath(key)

	for i := 0; i < len(keys)-1; i++ {
		k := keys[i]
		next, ok := data[k].(map[string]any)
		if !ok {
			next = map[string]any{}
			data[k] = next
		}
		data = next
	}
	data[keys[len(keys)-1]] = container
}

func setNestedValueRaw(data map[string]any, key string, value any) {
	keys := parseKeyPath(key)

	for i := 0; i < len(keys)-1; i++ {
		k := keys[i]
		next, ok := data[k].(map[string]any)
		if !ok {
			next = map[string]any{}
			data[k] = next
		}
		data = next
	}

	data[keys[len(keys)-1]] = value
}

func parseKeyPath(key string) []string {
	return strings.FieldsFunc(key, func(r rune) bool {
		return r == '.' || r == '[' || r == ']'
	})
}

func splitIndexedKey(key string) (string, int) {
	i := strings.Index(key, "[")
	j := strings.Index(key, "]")
	base := key[:i]
	idx, _ := strconv.Atoi(key[i+1 : j])
	return base, idx
}

func isIndexedKey(key string) bool {
	return strings.Contains(key, "[") && strings.HasSuffix(key, "]")
}

func isSliceKey(key string) bool {
	return strings.Contains(key, ":")
}
