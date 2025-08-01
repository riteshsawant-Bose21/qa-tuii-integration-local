package utils

import (
	"encoding/json"
	"net/http"
)

type APIResponse struct {
	Status  string      `json:"status"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

func Respond(w http.ResponseWriter, statusCode int, status string, message string, data any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)

	response := APIResponse{
		Status:  status,
		Message: message,
		Data:    data,
	}

	json.NewEncoder(w).Encode(response)
}
