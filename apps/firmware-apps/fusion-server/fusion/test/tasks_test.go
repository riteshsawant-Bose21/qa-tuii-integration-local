package main

import (
	"bytes"
	"encoding/json"
	"fusion/internal/api"
	"fusion/internal/routes"
	"fusion/internal/server"
	"net/http"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// liveServerURL points to your running server.
const (
	liveServerURL = "http://192.168.64.100:8080"
	snapshotID    = "test-snapshot"
)

// clearTasks retrieves all tasks from the live server and deletes each one.
// This ensures tests run against a clean slate.
func clearTasks(t *testing.T) {
	resp, err := http.Get(liveServerURL + routes.TasksEndpoint)
	require.NoError(t, err)
	defer resp.Body.Close()

	var tasks []api.Task
	err = json.NewDecoder(resp.Body).Decode(&tasks)
	require.NoError(t, err)

	for _, task := range tasks {
		req, err := http.NewRequest(http.MethodDelete, liveServerURL+routes.TasksEndpoint+"/"+task.ID, nil)
		require.NoError(t, err)
		respDel, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		respDel.Body.Close()
	}
}

func TestTaskManagerEndpoints(t *testing.T) {
	// Clean up any existing tasks on the live server.
	clearTasks(t)

	t.Run("AddTaskHandler", func(t *testing.T) {
		task := api.Task{
			ID:          "test-task",
			CronExpr:    "*/5 * * * *",
			SnapshotID:  snapshotID,
			Description: "Test task description",
		}
		taskJSON, err := json.Marshal(task)
		require.NoError(t, err)

		resp, err := http.Post(liveServerURL+routes.TasksEndpoint, api.JsonMIMEType, bytes.NewReader(taskJSON))
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusCreated, resp.StatusCode, "Expected HTTP status 201 Created")
	})

	t.Run("ListTasksHandler", func(t *testing.T) {
		resp, err := http.Get(liveServerURL + routes.TasksEndpoint)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusOK, resp.StatusCode, "Expected HTTP status 200 OK")

		var tasks []api.Task
		err = json.NewDecoder(resp.Body).Decode(&tasks)
		require.NoError(t, err, "Expected valid JSON response")
		assert.Len(t, tasks, 1, "Expected 1 task in the list")
		assert.Equal(t, "test-task", tasks[0].ID, "Task ID should match")
	})

	t.Run("UpdateTaskHandler", func(t *testing.T) {
		// Update the test-task with new data.
		task := api.Task{
			ID:          "test-task",
			CronExpr:    "*/10 * * * *",
			SnapshotID:  snapshotID,
			Description: "Updated task description",
		}
		taskJSON, err := json.Marshal(task)
		require.NoError(t, err)

		req, err := http.NewRequest(http.MethodPut, liveServerURL+routes.TasksEndpoint+"/test-task", bytes.NewReader(taskJSON))
		require.NoError(t, err)
		req.Header.Set(api.ContentType, api.JsonMIMEType)

		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusOK, resp.StatusCode, "Expected HTTP status 200 OK")
	})

	t.Run("RemoveTaskHandler", func(t *testing.T) {
		// Delete the test-task.
		req, err := http.NewRequest(http.MethodDelete, liveServerURL+routes.TasksEndpoint+"/test-task", nil)
		require.NoError(t, err)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusOK, resp.StatusCode, "Expected HTTP status 200 OK")

		// Verify the task is removed by fetching the task list.
		resp, err = http.Get(liveServerURL + routes.TasksEndpoint)
		require.NoError(t, err)
		defer resp.Body.Close()

		var tasks []api.Task
		err = json.NewDecoder(resp.Body).Decode(&tasks)
		require.NoError(t, err, "Expected valid JSON response")
		assert.Len(t, tasks, 0, "Expected 0 tasks in the list after removal")
	})

	t.Run("ExecutionHistoryHandler", func(t *testing.T) {
		// This test checks the history endpoint. Depending on your live server's activity,
		// you may get one or more history entries.
		resp, err := http.Get(liveServerURL + routes.TasksHistoryEndpoint)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusOK, resp.StatusCode, "Expected HTTP status 200 OK")

		var history []server.ExecutionRecord
		err = json.NewDecoder(resp.Body).Decode(&history)
		require.NoError(t, err, "Expected valid JSON for execution history")
		// Optionally, add more assertions based on the expected state.
	})
}

func TestTasksEndpointErrorCases(t *testing.T) {
	// Clean up any existing tasks before testing error cases.
	clearTasks(t)

	t.Run("ListTasksHandler wrong method", func(t *testing.T) {
		// Using POST on /tasks when GET is expected.
		req, err := http.NewRequest(http.MethodPost, liveServerURL+routes.TasksEndpoint, nil)
		require.NoError(t, err)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		// Expect the server to reject the method (the expected code may vary).
		assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
	})

	t.Run("AddTaskHandler wrong method", func(t *testing.T) {
		req, err := http.NewRequest(http.MethodPut, liveServerURL+routes.TasksEndpoint, nil)
		require.NoError(t, err)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusMethodNotAllowed, resp.StatusCode)
	})

	t.Run("AddTaskHandler malformed JSON", func(t *testing.T) {
		resp, err := http.Post(liveServerURL+routes.TasksEndpoint, api.JsonMIMEType, strings.NewReader("not-json"))
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
	})

	t.Run("AddTaskHandler missing required fields", func(t *testing.T) {
		payload := `{"id": "", "cron_expr": "", "description": ""}`
		resp, err := http.Post(liveServerURL+routes.TasksEndpoint, api.JsonMIMEType, strings.NewReader(payload))
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
	})

	t.Run("UpdateTaskHandler wrong method", func(t *testing.T) {
		req, err := http.NewRequest(http.MethodGet, liveServerURL+routes.TasksEndpoint+"/test", nil)
		require.NoError(t, err)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusNotFound, resp.StatusCode)
	})

	t.Run("UpdateTaskHandler missing id parameter", func(t *testing.T) {
		payload := `{"cron_expr": "*/5 * * * *", "description": "updated"}`
		req, err := http.NewRequest(http.MethodPut, liveServerURL+routes.TasksEndpoint, strings.NewReader(payload))
		require.NoError(t, err)
		req.Header.Set(api.ContentType, api.JsonMIMEType)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusMethodNotAllowed, resp.StatusCode)
	})

	t.Run("UpdateTaskHandler malformed JSON", func(t *testing.T) {
		req, err := http.NewRequest(http.MethodPut, liveServerURL+routes.TasksEndpoint+"/test", strings.NewReader("not-json"))
		require.NoError(t, err)
		req.Header.Set(api.ContentType, api.JsonMIMEType)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
	})

	t.Run("UpdateTaskHandler missing required fields", func(t *testing.T) {
		payload := `{"cron_expr": "", "description": ""}`
		req, err := http.NewRequest(http.MethodPut, liveServerURL+routes.TasksEndpoint+"/test", strings.NewReader(payload))
		require.NoError(t, err)
		req.Header.Set(api.ContentType, api.JsonMIMEType)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
	})

	t.Run("RemoveTaskHandler wrong method", func(t *testing.T) {
		req, err := http.NewRequest(http.MethodGet, liveServerURL+routes.TasksEndpoint+"/test", nil)
		require.NoError(t, err)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusNotFound, resp.StatusCode)
	})

	t.Run("RemoveTaskHandler missing task id", func(t *testing.T) {
		req, err := http.NewRequest(http.MethodDelete, liveServerURL+routes.TasksEndpoint, nil)
		require.NoError(t, err)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusMethodNotAllowed, resp.StatusCode)
	})

	t.Run("ExecutionHistoryHandler wrong method", func(t *testing.T) {
		req, err := http.NewRequest(http.MethodPost, liveServerURL+routes.TasksHistoryEndpoint, nil)
		require.NoError(t, err)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusMethodNotAllowed, resp.StatusCode)
	})
}
