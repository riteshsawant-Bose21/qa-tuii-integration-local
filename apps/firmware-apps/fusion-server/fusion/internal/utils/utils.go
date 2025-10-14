package utils

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"fusion/internal/logging"
	"io"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/gibson042/canonicaljson-go"
	"github.com/gorilla/mux"
)

// FileExists returns true if the given path exists and is not a directory.
func FileExists(path string) (bool, error) {
	info, err := os.Stat(path)
	if err == nil {
		// Check it’s not a directory
		return !info.IsDir(), nil
	}

	if os.IsNotExist(err) {
		return false, nil
	}
	return false, err
}

func IsDeleteRequest(r *http.Request) bool {
	return r.Method == http.MethodDelete
}

func IsGetRequest(r *http.Request) bool {
	return r.Method == http.MethodGet
}

func IsPatchRequest(r *http.Request) bool {
	return r.Method == http.MethodPatch
}

func IsPostRequest(r *http.Request) bool {
	return r.Method == http.MethodPost
}

func IsPutRequest(r *http.Request) bool {
	return r.Method == http.MethodPut
}

// RequireMethod checks the HTTP method and returns true if it matches, false otherwise.
func RequireMethod(w http.ResponseWriter, r *http.Request, method string) bool {
	if r.Method != method {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return false
	}
	return true
}

func RequireDelete(w http.ResponseWriter, r *http.Request) bool {
	return RequireMethod(w, r, http.MethodDelete)
}

func RequireGet(w http.ResponseWriter, r *http.Request) bool {
	return RequireMethod(w, r, http.MethodGet)
}

func RequirePatch(w http.ResponseWriter, r *http.Request) bool {
	return RequireMethod(w, r, http.MethodPatch)
}

func RequirePost(w http.ResponseWriter, r *http.Request) bool {
	return RequireMethod(w, r, http.MethodPost)
}

func RequirePut(w http.ResponseWriter, r *http.Request) bool {
	return RequireMethod(w, r, http.MethodPut)
}

func ApplyPatch(data map[string]any, changes map[string]any) error {
	for key, value := range changes {
		switch {
		case value == nil:
			removeNestedField(data, key)
		case isMap(value):
			subChanges := value.(map[string]any)
			if subData, ok := getNestedValue(data, key).(map[string]any); ok {
				if err := ApplyPatch(subData, subChanges); err != nil {
					return err
				}
			} else {
				newSubData := make(map[string]any)
				SetNestedValue(data, key, newSubData)
				if err := ApplyPatch(newSubData, subChanges); err != nil {
					return err
				}
			}
		case isArray(value):
			subArray := value.([]any)
			existingValue := getNestedValue(data, key)
			if _, isExistingArray := existingValue.([]any); isExistingArray && !isIndexedKey(key) {
				SetNestedValue(data, key, subArray)
			} else {
				if existingArray, ok := existingValue.([]any); ok {
					for i, v := range subArray {
						if i < len(existingArray) {
							existingArray[i] = v
						} else {
							return fmt.Errorf("index %d out of bounds for array %s", i, key)
						}
					}
					SetNestedValue(data, key, existingArray)
				} else {
					SetNestedValue(data, key, subArray)
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

// CalculateChecksum returns a SHA-256 hash of JSON data.
func CalculateChecksum(v any) (string, error) {

	// canonicaljson is used to ensure deterministic ordering
	b, err := canonicaljson.Marshal(v)
	if err != nil {
		return "", fmt.Errorf("canonical marshal failed: %w", err)
	}
	sum := sha256.Sum256(b)
	return hex.EncodeToString(sum[:]), nil
}

// VerifyChecksum validates the checksum.
func VerifyChecksum(file multipart.File, expectedChecksum string) bool {

	hash := sha256.New()
	if _, err := io.Copy(hash, file); err != nil {
		return false
	}

	actualChecksum := hex.EncodeToString(hash.Sum(nil))
	return actualChecksum == expectedChecksum
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

func parseArrayIndex(key string) (int, bool) {
	if i, err := strconv.Atoi(key); err == nil {
		return i, true
	}
	return -1, false
}

func parseKeyPath(key string) []string {
	return strings.FieldsFunc(key, func(r rune) bool {
		return r == '.' || r == '[' || r == ']'
	})
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

func isMap(v any) bool {
	_, ok := v.(map[string]any)
	return ok
}

func isArray(v any) bool {
	_, ok := v.([]any)
	return ok
}

// ExtractValue pulls the named value from mux
func ExtractValue(r *http.Request, value string) (string, error) {
	name := mux.Vars(r)[value]
	if name == "" {
		return "", fmt.Errorf("%s is required", value)
	}
	return filepath.Base(name), nil
}

// ExtractId pulls the "id" var from mux and returns an error if it’s missing.
func ExtractId(r *http.Request) (string, error) {
	return ExtractValue(r, "id")
}

// ExtractName pulls the “name” var from mux and returns aan error if it’s missing.
func ExtractName(r *http.Request) (string, error) {
	return ExtractValue(r, "name")

}

// DeepCopy recursively copies maps, slices, and arrays.
// It supports arbitrary nesting of map[string]any, []any, and primitive values.
func DeepCopy(src any) any {
	switch v := src.(type) {
	case map[string]any:
		cp := make(map[string]any, len(v))
		for key, val := range v {
			cp[key] = DeepCopy(val)
		}
		return cp

	case []any:
		cp := make([]any, len(v))
		for i, val := range v {
			cp[i] = DeepCopy(val)
		}
		return cp

	case []float64:
		cp := make([]float64, len(v))
		copy(cp, v)
		return cp
	case []int:
		cp := make([]int, len(v))
		copy(cp, v)
		return cp
	case []string:
		cp := make([]string, len(v))
		copy(cp, v)
		return cp

	default:
		return v
	}
}
