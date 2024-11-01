package config

import (
	"encoding/json"
	"net/http"
)

// VolumeUpdate represents a volume change request
type VolumeUpdate struct {
	Channel int     `json:"channel"`
	Volume  float64 `json:"volume"`
}

// SetVolume handles volume update requests
func (s *ConfigServer) SetVolume(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var update VolumeUpdate
	if err := json.NewDecoder(r.Body).Decode(&update); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Validate volume range
	if update.Volume < 0 || update.Volume > 100 {
		http.Error(w, "Volume must be between 0 and 100", http.StatusBadRequest)
		return
	}

	// Store volume update in state
	if err := s.broadcastUpdate("volume", update); err != nil {
		http.Error(w, "Failed to update volume", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  "success",
		"channel": update.Channel,
		"volume":  update.Volume,
	})
}
