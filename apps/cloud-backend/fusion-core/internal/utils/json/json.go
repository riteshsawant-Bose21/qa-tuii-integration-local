package jsonutil

import "encoding/json"

// ValidateJSONObject checks if the given byte slice represents a valid JSON object
func ValidateJSONObject(data []byte) error {
	var js map[string]interface{}
	if err := json.Unmarshal(data, &js); err != nil {
		return err
	}
	return nil
}
