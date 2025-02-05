package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"fusion/internal/logging"
	"fusion/internal/timers"
	"net/http"
	"net/http/httptest"
	"os"
	"strconv"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestTimerManager(t *testing.T) {

	logging.InitLogger(logging.LogConfig{
		NodeName:    "TimeManager",
		LogDir:      "/tmp/test_timer_manager_test",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logging.DEBUG,
	})

	logger := logging.GetLogger()
	defer logger.Close()

	// Create temporary files for testing
	taskFile, err := os.CreateTemp("", "tasks_*.json")
	assert.NoError(t, err)
	defer os.Remove(taskFile.Name())
	historyFile, err := os.CreateTemp("", "history_*.json")
	assert.NoError(t, err)
	defer os.Remove(historyFile.Name())

	// Initialize TimerManager
	manager := timers.NewTimerManager(taskFile.Name(), historyFile.Name())

	// Start the TimerManager and ensure cleanup
	err = manager.Start()
	assert.NoError(t, err)
	defer manager.Stop() // Ensure the cron scheduler stops

	// Add a test task
	taskID := "test-task"
	err = manager.AddTask(taskID, "*/5 * * * *", "Test task", func() {
		logger.Info("Task '%s' executed", taskID)
	})
	assert.NoError(t, err)

	print("AddedTask\n")
	// Verify task is added
	tasks := manager.ListTasks()
	assert.Len(t, tasks, 1)

	// Simulate an execution
	manager.RecordExecution(taskID, "success", "Task executed successfully")

	// Verify execution history
	history := manager.GetExecutionHistory()
	assert.Len(t, history, 1)
	assert.Equal(t, "success", history[0].Status)

	// Remove the task
	err = manager.RemoveTask(taskID)
	assert.NoError(t, err)

	// Verify task is removed
	tasks = manager.ListTasks()
	assert.Len(t, tasks, 0)
}

func TestExecutionHistoryRotation(t *testing.T) {

	logging.InitLogger(logging.LogConfig{
		NodeName:    "TimeManager",
		LogDir:      "/tmp/test_timer_manager_test",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logging.DEBUG,
	})

	logger := logging.GetLogger()
	defer logger.Close()

	// Create temporary files for testing
	taskFile, err := os.CreateTemp("", "tasks_*.json")
	assert.NoError(t, err)
	defer os.Remove(taskFile.Name())

	historyFile, err := os.CreateTemp("", "history_*.json")
	assert.NoError(t, err)
	defer os.Remove(historyFile.Name())

	// Initialize TimerManager with a mock logger
	manager := timers.NewTimerManager(taskFile.Name(), historyFile.Name())

	// Start the TimerManager
	err = manager.Start()
	assert.NoError(t, err)
	defer manager.Stop()

	// Add tasks to generate history
	for i := 0; i < timers.MaxHistory+10; i++ {
		taskID := "task-" + strconv.Itoa(i)
		err = manager.AddTask(taskID, "*/5 * * * *", "Test task", func() {
			logger.Info("Task '%s' executed", taskID)
		})
		assert.NoError(t, err)

		// Simulate a single execution
		manager.RecordExecution(taskID, "success", "Task executed successfully")
	}

	// Verify history rotation
	history := manager.GetExecutionHistory()
	assert.Len(t, history, timers.MaxHistory)

	// Verify oldest records are dropped
	for i := 0; i < 10; i++ {
		assert.NotContains(t, history, "task-"+strconv.Itoa(i))
	}
}

func TestTimerManagerEndpoints(t *testing.T) {

	logging.InitLogger(logging.LogConfig{
		NodeName:    "TimeManager",
		LogDir:      "/tmp/test_timer_manager_test",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logging.DEBUG,
	})

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
	mux.HandleFunc("/tasks/history", manager.ExecutionHistoryHandler)

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
		req.Header.Set("Content-Type", "application/json")
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
		req.Header.Set("Content-Type", "application/json")
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
		req := httptest.NewRequest(http.MethodGet, "/tasks/history", nil)
		rec := httptest.NewRecorder()

		mux.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code, "Expected HTTP status 200 OK")

		var history []timers.ExecutionRecord
		err := json.Unmarshal(rec.Body.Bytes(), &history)
		assert.NoError(t, err, "Expected no error during unmarshalling response")
		assert.Len(t, history, 0, "Expected 0 history records initially")
	})
}

func TestHTTPEndpointErrorCases(t *testing.T) {
	// Create temporary files for persistence.
	tasksFile, err := os.CreateTemp("", "tasks_http_error_*.json")
	require.NoError(t, err)
	defer os.Remove(tasksFile.Name())

	historyFile, err := os.CreateTemp("", "history_http_error_*.json")
	require.NoError(t, err)
	defer os.Remove(historyFile.Name())

	// Initialize and start the TimerManager.
	manager := timers.NewTimerManager(tasksFile.Name(), historyFile.Name())
	err = manager.Start()
	require.NoError(t, err)
	defer manager.Stop()

	// Set up an HTTP mux with our handlers.
	mux := http.NewServeMux()
	mux.HandleFunc("/tasks", manager.ListTasksHandler)
	mux.HandleFunc("/tasks/add", manager.AddTaskHandler)
	mux.HandleFunc("/tasks/update", manager.UpdateTaskHandler)
	mux.HandleFunc("/tasks/remove", manager.RemoveTaskHandler)
	mux.HandleFunc("/tasks/history", manager.ExecutionHistoryHandler)

	// --- ListTasksHandler ---
	t.Run("ListTasksHandler wrong method", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, "/tasks", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		assert.Equal(t, http.StatusMethodNotAllowed, rec.Code)
	})

	// --- AddTaskHandler ---
	t.Run("AddTaskHandler wrong method", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/tasks/add", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		assert.Equal(t, http.StatusMethodNotAllowed, rec.Code)
	})

	t.Run("AddTaskHandler malformed JSON", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, "/tasks/add", strings.NewReader("not-json"))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		assert.Equal(t, http.StatusBadRequest, rec.Code)
	})

	t.Run("AddTaskHandler missing required fields", func(t *testing.T) {
		// Expect a JSON payload with non-empty id, cron_expr, and description.
		payload := `{"id": "", "cron_expr": "", "description": ""}`
		req := httptest.NewRequest(http.MethodPost, "/tasks/add", strings.NewReader(payload))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		// The handler checks for empty fields and returns 400.
		assert.Equal(t, http.StatusBadRequest, rec.Code)
	})

	// --- UpdateTaskHandler ---
	t.Run("UpdateTaskHandler wrong method", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/tasks/update?id=test", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		assert.Equal(t, http.StatusMethodNotAllowed, rec.Code)
	})

	t.Run("UpdateTaskHandler missing query parameter", func(t *testing.T) {
		// No id query parameter.
		payload := `{"cron_expr": "*/5 * * * *", "description": "updated"}`
		req := httptest.NewRequest(http.MethodPut, "/tasks/update", strings.NewReader(payload))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		assert.Equal(t, http.StatusBadRequest, rec.Code)
	})

	t.Run("UpdateTaskHandler malformed JSON", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPut, "/tasks/update?id=test", strings.NewReader("not-json"))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		assert.Equal(t, http.StatusBadRequest, rec.Code)
	})

	t.Run("UpdateTaskHandler missing required fields", func(t *testing.T) {
		// Provide a JSON with empty cron_expr and description.
		payload := `{"cron_expr": "", "description": ""}`
		req := httptest.NewRequest(http.MethodPut, "/tasks/update?id=test", strings.NewReader(payload))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		assert.Equal(t, http.StatusBadRequest, rec.Code)
	})

	// --- RemoveTaskHandler ---
	t.Run("RemoveTaskHandler wrong method", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/tasks/remove?id=test", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		assert.Equal(t, http.StatusMethodNotAllowed, rec.Code)
	})

	t.Run("RemoveTaskHandler missing query parameter", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodDelete, "/tasks/remove", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		assert.Equal(t, http.StatusBadRequest, rec.Code)
	})

	// --- ExecutionHistoryHandler ---
	t.Run("ExecutionHistoryHandler wrong method", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, "/tasks/history", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		assert.Equal(t, http.StatusMethodNotAllowed, rec.Code)
	})
}

func TestTasksPersistence(t *testing.T) {

	logging.InitLogger(logging.LogConfig{
		NodeName:    "TimeManager",
		LogDir:      "/tmp/test_timer_manager_test",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logging.DEBUG,
	})

	logger := logging.GetLogger()
	defer logger.Close()

	// Create temporary files for tasks and history
	tasksFile, err := os.CreateTemp("", "tasks_persistence_*.json")
	require.NoError(t, err)
	defer os.Remove(tasksFile.Name())

	historyFile, err := os.CreateTemp("", "history_persistence_*.json")
	require.NoError(t, err)
	defer os.Remove(historyFile.Name())

	// Create an initial TimerManager instance and start it.
	manager1 := timers.NewTimerManager(tasksFile.Name(), historyFile.Name())
	err = manager1.Start()
	require.NoError(t, err)
	defer manager1.Stop()

	// Add a task and ensure it is added.
	err = manager1.AddTask("persist-task", "*/1 * * * *", "Persistence test task", func() {})
	require.NoError(t, err)

	tasks := manager1.ListTasks()
	assert.Len(t, tasks, 1)
	assert.Equal(t, "persist-task", tasks[0].ID)

	// Stop manager1 to flush changes to the files.
	manager1.Stop()

	// Create a new TimerManager instance using the same persistence files.
	manager2 := timers.NewTimerManager(tasksFile.Name(), historyFile.Name())
	err = manager2.Start()
	require.NoError(t, err)
	defer manager2.Stop()

	// Verify that the task is loaded correctly.
	tasks = manager2.ListTasks()
	assert.Len(t, tasks, 1)
	assert.Equal(t, "persist-task", tasks[0].ID)
}

func TestHistoryPersistence(t *testing.T) {

	logging.InitLogger(logging.LogConfig{
		NodeName:    "TimeManager",
		LogDir:      "/tmp/test_timer_manager_test",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logging.DEBUG,
	})

	logging.SetGlobalLogger(logging.NewDummyLogger())

	tasksFile, err := os.CreateTemp("", "tasks_history_persistence_*.json")
	require.NoError(t, err)
	defer os.Remove(tasksFile.Name())

	historyFile, err := os.CreateTemp("", "history_history_persistence_*.json")
	require.NoError(t, err)
	defer os.Remove(historyFile.Name())

	manager1 := timers.NewTimerManager(tasksFile.Name(), historyFile.Name())
	err = manager1.Start()
	require.NoError(t, err)
	defer manager1.Stop()

	// Record a couple of execution records.
	manager1.RecordExecution("persist-task", "success", "First execution")
	time.Sleep(10 * time.Millisecond) // ensure different timestamps
	manager1.RecordExecution("persist-task", "failed", "Second execution")

	history := manager1.GetExecutionHistory()
	assert.Len(t, history, 2)
	assert.Equal(t, "First execution", history[0].Description)
	assert.Equal(t, "Second execution", history[1].Description)

	manager1.Stop()

	manager2 := timers.NewTimerManager(tasksFile.Name(), historyFile.Name())
	err = manager2.Start()
	require.NoError(t, err)
	defer manager2.Stop()

	history = manager2.GetExecutionHistory()
	assert.Len(t, history, 2)
	assert.Equal(t, "First execution", history[0].Description)
	assert.Equal(t, "Second execution", history[1].Description)
}

// TestUpdateNonExistentTask verifies that attempting to update a task that doesn't exist returns an error.
func TestUpdateNonExistentTask(t *testing.T) {
	// Create temporary files for persistence.
	tasksFile, err := os.CreateTemp("", "tasks_update_nonexistent_*.json")
	require.NoError(t, err)
	defer os.Remove(tasksFile.Name())

	historyFile, err := os.CreateTemp("", "history_update_nonexistent_*.json")
	require.NoError(t, err)
	defer os.Remove(historyFile.Name())

	// Initialize and start the TimerManager.
	manager := timers.NewTimerManager(tasksFile.Name(), historyFile.Name())
	err = manager.Start()
	require.NoError(t, err)
	defer manager.Stop()

	// Attempt to update a non-existent task.
	err = manager.UpdateTask("nonexistent", "*/5 * * * *", "New description", func() {})
	require.Error(t, err)
	assert.Contains(t, err.Error(), "no task found")
}

// TestRemoveNonExistentTask verifies that attempting to remove a non-existent task returns an error.
func TestRemoveNonExistentTask(t *testing.T) {
	// Create temporary files for persistence.
	tasksFile, err := os.CreateTemp("", "tasks_remove_nonexistent_*.json")
	require.NoError(t, err)
	defer os.Remove(tasksFile.Name())

	historyFile, err := os.CreateTemp("", "history_remove_nonexistent_*.json")
	require.NoError(t, err)
	defer os.Remove(historyFile.Name())

	// Initialize and start the TimerManager.
	manager := timers.NewTimerManager(tasksFile.Name(), historyFile.Name())
	err = manager.Start()
	require.NoError(t, err)
	defer manager.Stop()

	// Attempt to remove a non-existent task.
	err = manager.RemoveTask("nonexistent")
	require.Error(t, err)
	assert.Contains(t, err.Error(), "no task found")
}

// TestUpdateTaskInvalidCron verifies that updating an existing task with an invalid cron expression returns an error.
func TestUpdateTaskInvalidCron(t *testing.T) {
	// Create temporary files for persistence.
	tasksFile, err := os.CreateTemp("", "tasks_update_invalidcron_*.json")
	require.NoError(t, err)
	defer os.Remove(tasksFile.Name())

	historyFile, err := os.CreateTemp("", "history_update_invalidcron_*.json")
	require.NoError(t, err)
	defer os.Remove(historyFile.Name())

	// Initialize and start the TimerManager.
	manager := timers.NewTimerManager(tasksFile.Name(), historyFile.Name())
	err = manager.Start()
	require.NoError(t, err)
	defer manager.Stop()

	// First, add a valid task.
	err = manager.AddTask("test-task", "*/5 * * * *", "Valid task", func() {})
	require.NoError(t, err)

	// Attempt to update the task with an invalid cron expression.
	err = manager.UpdateTask("test-task", "invalid-cron", "Updated description", func() {})
	require.Error(t, err)
	// Optionally, check for a specific substring in the error message that comes from the cron parser.
	// For example:
	// assert.Contains(t, err.Error(), "expected")
}

func TestConcurrentModifications(t *testing.T) {
	// Create temporary files for tasks and history persistence.
	tasksFile, err := os.CreateTemp("", "tasks_concurrency_*.json")
	require.NoError(t, err)
	defer os.Remove(tasksFile.Name())

	historyFile, err := os.CreateTemp("", "history_concurrency_*.json")
	require.NoError(t, err)
	defer os.Remove(historyFile.Name())

	// Initialize and start the TimerManager.
	manager := timers.NewTimerManager(tasksFile.Name(), historyFile.Name())
	require.NoError(t, manager.Start())
	defer manager.Stop()

	var wg sync.WaitGroup
	numTasks := 100

	// Concurrently add tasks.
	for i := 0; i < numTasks; i++ {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			taskID := fmt.Sprintf("task-%d", i)
			err := manager.AddTask(taskID, "*/1 * * * *", "Concurrent task", func() {
				// Each task function records an execution.
				manager.RecordExecution(taskID, "success", "Executed concurrently")
			})
			if err != nil {
				// If a task cannot be added, report the error.
				t.Errorf("AddTask error for %s: %v", taskID, err)
			}
		}(i)
	}

	// Concurrently list tasks repeatedly.
	wg.Add(1)
	go func() {
		defer wg.Done()
		for i := 0; i < 50; i++ {
			_ = manager.ListTasks()
			time.Sleep(10 * time.Millisecond)
		}
	}()

	// Concurrently record execution entries.
	wg.Add(1)
	go func() {
		defer wg.Done()
		for i := 0; i < 50; i++ {
			tasks := manager.ListTasks()
			if len(tasks) > 0 {
				// Use i mod len(tasks) to pick one task.
				task := tasks[i%len(tasks)]
				manager.RecordExecution(task.ID, "success", "Concurrent execution record")
			}
			time.Sleep(5 * time.Millisecond)
		}
	}()

	// Concurrently remove tasks.
	for i := 0; i < numTasks; i++ {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			taskID := fmt.Sprintf("task-%d", i)
			// Allow some time for the task to be added before attempting removal.
			time.Sleep(20 * time.Millisecond)
			err := manager.RemoveTask(taskID)
			// It's possible that removal fails if the task has already been removed.
			if err != nil {
				t.Logf("RemoveTask for %s returned error: %v", taskID, err)
			}
		}(i)
	}

	// Wait for all concurrent operations to finish.
	wg.Wait()
}
