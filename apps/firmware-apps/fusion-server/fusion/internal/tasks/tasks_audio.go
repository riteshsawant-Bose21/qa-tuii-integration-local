package tasks

import (
	"fmt"
	"fusion/internal/api"
	"fusion/internal/utils"
	"net/http"
	"path/filepath"

	"github.com/gorilla/mux"
)

// HandleTriggerMessage handles triggering the playback of an audio message
func (tm *TaskManager) HandleTriggerMessage(w http.ResponseWriter, r *http.Request) {

	if !utils.RequirePut(w, r) {
		return
	}

	name, err := extractName(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	filePath := filepath.Join(api.AudioFilesLocation, name)
	exists, err := utils.FileExists(filePath)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if !exists {
		http.Error(w, "File not found", http.StatusNotFound)
		return
	}

	// TODO: Do what is needed to play the file

	w.WriteHeader(http.StatusNoContent)
}

// returns a func that plays the given file
func (tm *TaskManager) taskPlayAudioFunc(path string) func() {
	return func() {
		// if err := tm.audioPlayer.Play(path); err != nil {
		//   tm.RecordExecution(&api.Task{ID: /*…*/}, "failed")
		//   logging.GetLogger().Error("playback failed: %v", err)
		// } else {
		//   tm.RecordExecution(&api.Task{/*…*/}, "success")
		// }
	}
}

// extractName pulls the “name” var from mux and returns a proper error if it’s missing.
func extractName(r *http.Request) (string, error) {
	name := mux.Vars(r)["name"]
	if name == "" {
		return "", fmt.Errorf("name is required")
	}
	return filepath.Base(name), nil
}
