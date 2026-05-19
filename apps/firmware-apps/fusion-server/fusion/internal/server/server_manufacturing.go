package server

import (
	"fmt"
	"net/http"
	"os/exec"
	"strings"

	json "github.com/goccy/go-json"

	"fusion-services-core/logging"
	"fusion/internal/utils"
)

// setModelNameRequest is the request body for POST /manufacturing/model-name.
// ModelName must be one of the accepted values: c1-evk, powersmart, fm6, fm8y, xlr-pal, blue-pal, som.
type setModelNameRequest struct {
	ModelName string `json:"model_name"`
}

func (s *FusionServer) SetModelNameLocal(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	defer r.Body.Close()

	var req setModelNameRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON: %v", err), http.StatusBadRequest)
		return
	}

	cmd := exec.Command("fusion-model-name", "set-reboot", req.ModelName)
	output, err := cmd.CombinedOutput()
	if err != nil {
		errOutput := strings.TrimSpace(string(output))
		if errOutput == "" {
			errOutput = err.Error()
		}
		logging.GetLogger().Error("Failed to set model name via fusion-model-name: %s", errOutput)
		http.Error(w, fmt.Sprintf("failed to set model name: %s", errOutput), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
