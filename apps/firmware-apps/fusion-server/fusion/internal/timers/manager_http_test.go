package timers_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"fusion/internal/logging"
	"fusion/internal/timers"

	"github.com/stretchr/testify/assert"
)

const (
	contentType     = "Content-Type"
	jsonContentType = "application/json"
)

func TestTimerManagerEndpoints(t *testing.T) {
	logger := logging.GetLogger()
	defer logger.Close()

	manager := timers.NewTimerManager("tasks_test.json", "history_test.json")
	defer manager.Stop()

	// Initialize mock server
	mux := http.NewServeMux()
	mux.HandleFunc("/tasks", manager.ListTasksHandler)
	mux.HandleFunc("/tasks/add", manager.AddTaskHandler)
	mux.HandleFunc("/tasks/update", manager.UpdateTaskHandler)
	mux.HandleFunc("/tasks/remove", manager.RemoveTaskHandler)
	mux.HandleFunc("/history", manager.ExecutionHistoryHandler)

	// Start TimerManager
	assert.NoError(t, manager.Start())

	// Test AddTaskHandler
	t.Run("AddTaskHandler", func(t *testing.T) {
		task := timers.TimerTask{
			ID:          "test-task",
			CronExpr:    "*/5 * * * *",
			Description: "Test task description",
		}
		taskJSON, _ := json.Marshal(task)

		req := httptest.NewRequest(http.MethodPost, "/tasks/add", bytes.NewReader(taskJSON))
		req.Header.Set(contentType, jsonContentType)
		rec := httptest.NewRecorder()

		mux.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusCreated, rec.Code, "Expected HTTP status 201 Created")
	})

	// Test ListTasksHandler
	t.Run("ListTasksHandler", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/tasks", nil)
		rec := httptest.NewRecorder()

		mux.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code, "Expected HTTP status 200 OK")

		var tasks []timers.TimerTask
		err := json.Unmarshal(rec.Body.Bytes(), &tasks)
		assert.NoError(t, err, "Expected no error during unmarshalling response")
		assert.Len(t, tasks, 1, "Expected 1 task in the list")
		assert.Equal(t, "test-task", tasks[0].ID, "Expected task ID to match")
	})

	// Test UpdateTaskHandler
	t.Run("UpdateTaskHandler", func(t *testing.T) {
		task := timers.TimerTask{
			CronExpr:    "*/10 * * * *",
			Description: "Updated task description",
		}
		taskJSON, _ := json.Marshal(task)

		req := httptest.NewRequest(http.MethodPut, "/tasks/update?id=test-task", bytes.NewReader(taskJSON))
		req.Header.Set(contentType, jsonContentType)
		rec := httptest.NewRecorder()

		mux.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code, "Expected HTTP status 200 OK")
	})

	// Test RemoveTaskHandler
	t.Run("RemoveTaskHandler", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodDelete, "/tasks/remove?id=test-task", nil)
		rec := httptest.NewRecorder()

		mux.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code, "Expected HTTP status 200 OK")

		// Ensure task is removed
		req = httptest.NewRequest(http.MethodGet, "/tasks", nil)
		rec = httptest.NewRecorder()

		mux.ServeHTTP(rec, req)

		var tasks []timers.TimerTask
		err := json.Unmarshal(rec.Body.Bytes(), &tasks)
		assert.NoError(t, err, "Expected no error during unmarshalling response")
		assert.Len(t, tasks, 0, "Expected 0 tasks in the list after removal")
	})

	// Test ExecutionHistoryHandler
	t.Run("ExecutionHistoryHandler", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/history", nil)
		rec := httptest.NewRecorder()

		mux.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code, "Expected HTTP status 200 OK")

		var history []timers.ExecutionRecord
		err := json.Unmarshal(rec.Body.Bytes(), &history)
		assert.NoError(t, err, "Expected no error during unmarshalling response")
		assert.Len(t, history, 0, "Expected 0 history records initially")
	})
}
