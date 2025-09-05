package tasks

import (
	"context"
	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/utils"
	"net/http"
	"os"
	"path/filepath"
)

// HandleTriggerMessage handles triggering the playback of an audio message
func (tm *TaskManager) HandleTriggerMessage(w http.ResponseWriter, r *http.Request) {

	if !utils.RequirePut(w, r) {
		return
	}

	name, err := utils.ExtractName(r)
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
func (tm *TaskManager) taskPlayAudioFunc(path string) TaskFunc {
	return func(ctx context.Context) error {
		_, err := os.Stat(path)
		if err != nil {
			logging.GetLogger().Error("Failed to stat audio file: %v", err)
			return err
		}
		// if err := tm.audioPlayer.Play(path); err != nil {
		//   tm.RecordExecution(&api.Task{ID: /*…*/}, "failed")
		//   logging.GetLogger().Error("playback failed: %v", err)
		// } else {
		//   tm.RecordExecution(&api.Task{/*…*/}, "success")
		// }
		return nil
	}
}
