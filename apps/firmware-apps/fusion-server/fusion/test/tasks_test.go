package main

import (
	"bytes"
	"fusion/internal/api"
	"fusion/internal/routes"
	"fusion/internal/tasks"
	"net/http"
	"strings"
	"testing"
	"time"

	json "github.com/goccy/go-json"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const (
	tasksServerURL = "http://192.168.2.100:8080"
	tasksURL       = tasksServerURL + routes.TasksEndpoint
	testTaskId     = "test-task"
	snapshotID     = "test-snapshot"
)

// clearTasks retrieves all tasks from the live server and deletes each one.
// This ensures tests run against a clean slate.
func clearTasks(t *testing.T) {
	resp, err := http.Get(tasksURL)
	require.NoError(t, err)
	defer resp.Body.Close()

	var tasks []api.Task
	err = json.NewDecoder(resp.Body).Decode(&tasks)
	require.NoError(t, err)

	for _, task := range tasks {
		req, err := http.NewRequest(http.MethodDelete, tasksURL+"/"+task.ID, nil)
		require.NoError(t, err)
		respDel, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		respDel.Body.Close()
	}
}

func createTask(t *testing.T) {
	task := api.Task{
		ID:          testTaskId,
		CronExpr:    "*/5 * * * *",
		Description: "Test task description",
		Type:        api.TaskTypeSnapshot,
		Enabled:     true,
		Params:      map[string]any{api.SnapshotIDKey: "default"},
	}

	taskJSON, err := json.Marshal(task)
	require.NoError(t, err)

	resp, err := http.Post(tasksURL, api.JsonMIMEType, bytes.NewReader(taskJSON))
	require.NoError(t, err)
	defer resp.Body.Close()
}

func TestTaskManagerEndpoints(t *testing.T) {
	// Clean up any existing tasks on the live server.
	clearTasks(t)

	t.Run("AddTaskHandler", func(t *testing.T) {
		task := api.Task{
			ID:          testTaskId,
			CronExpr:    "*/5 * * * *",
			Description: "Test task description",
			Type:        api.TaskTypeSnapshot,
			Enabled:     true,
			Params:      map[string]any{api.SnapshotIDKey: "default"},
		}

		taskJSON, err := json.Marshal(task)
		require.NoError(t, err)

		resp, err := http.Post(tasksURL, api.JsonMIMEType, bytes.NewReader(taskJSON))
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusCreated, resp.StatusCode, "Expected HTTP 201 Created")
	})

	t.Run("ListTasksHandler", func(t *testing.T) {
		resp, err := http.Get(tasksServerURL + routes.TasksEndpoint)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusOK, resp.StatusCode, "Expected HTTP 200")

		var tasks []api.Task
		err = json.NewDecoder(resp.Body).Decode(&tasks)
		require.NoError(t, err, "Expected valid JSON response")
		assert.Len(t, tasks, 1, "Expected 1 task in the list")
		assert.Equal(t, testTaskId, tasks[0].ID, "Task ID should match")
	})

	t.Run("UpdateTaskHandler", func(t *testing.T) {

		// Update the test-task with new data.
		desc := "Updated task description"
		cron := "*/10 * * * *"
		snap := "default"

		task := api.TaskSnapshopPatch{
			Description: &desc,
			CronExpr:    &cron,
			Snapshot:    &snap,
		}

		taskJSON, err := json.Marshal(task)
		require.NoError(t, err)

		req, err := http.NewRequest(http.MethodPatch, tasksURL+"/test-task", bytes.NewReader(taskJSON))
		require.NoError(t, err)
		req.Header.Set(api.ContentType, api.JsonMIMEType)

		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusOK, resp.StatusCode, "Expected HTTP 200")
	})

	t.Run("RemoveTaskHandler", func(t *testing.T) {
		// Delete the test-task.
		req, err := http.NewRequest(http.MethodDelete, tasksURL+"/test-task", nil)
		require.NoError(t, err)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusNoContent, resp.StatusCode, "Expected HTTP 204")

		// Verify the task is removed by fetching the task list.
		resp, err = http.Get(tasksServerURL + routes.TasksEndpoint)
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
		resp, err := http.Get(tasksServerURL + routes.TasksHistoryEndpoint)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusOK, resp.StatusCode, "Expected HTTP 200")

		var history []tasks.ExecutionRecord
		err = json.NewDecoder(resp.Body).Decode(&history)
		require.NoError(t, err, "Expected valid JSON for execution history")
		// Optionally, add more assertions based on the expected state.
	})

	t.Run("EnableDisableTask", func(t *testing.T) {
		clearTasks(t)
		createTask(t)

		// Disable Task
		reqDisable, err := http.NewRequest(http.MethodPost, tasksURL+"/"+testTaskId+"/disable", nil)
		require.NoError(t, err)
		respDisable, err := http.DefaultClient.Do(reqDisable)
		require.NoError(t, err)
		defer respDisable.Body.Close()

		assert.Equal(t, http.StatusNoContent, respDisable.StatusCode)

		// Verify disabled
		respGet, err := http.Get(tasksURL + "/" + testTaskId)
		require.NoError(t, err)
		defer respGet.Body.Close()

		var disabledTask api.Task
		err = json.NewDecoder(respGet.Body).Decode(&disabledTask)
		require.NoError(t, err)
		assert.False(t, disabledTask.Enabled, "Task should be disabled")

		// Enable Task
		reqEnable, err := http.NewRequest(http.MethodPost, tasksURL+"/"+testTaskId+"/enable", nil)
		require.NoError(t, err)
		respEnable, err := http.DefaultClient.Do(reqEnable)
		require.NoError(t, err)
		defer respEnable.Body.Close()

		assert.Equal(t, http.StatusNoContent, respEnable.StatusCode)

		// Verify enabled
		respGet2, err := http.Get(tasksURL + "/" + testTaskId)
		require.NoError(t, err)
		defer respGet2.Body.Close()

		var enabledTask api.Task
		err = json.NewDecoder(respGet2.Body).Decode(&enabledTask)
		require.NoError(t, err)
		assert.True(t, enabledTask.Enabled, "Task should be enabled")
	})
}

func TestTasksEndpointErrorCases(t *testing.T) {

	clearTasks(t)
	createTask(t)

	t.Run("ListTasksHandler wrong method", func(t *testing.T) {
		// Using POST on /tasks when GET is expected.
		req, err := http.NewRequest(http.MethodPost, tasksURL, nil)
		require.NoError(t, err)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		// Expect the server to reject the method (the expected code may vary).
		assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
	})

	t.Run("AddTaskHandler wrong method", func(t *testing.T) {
		req, err := http.NewRequest(http.MethodPut, tasksURL, nil)
		require.NoError(t, err)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusMethodNotAllowed, resp.StatusCode)
	})

	t.Run("AddTaskHandler malformed JSON", func(t *testing.T) {
		resp, err := http.Post(tasksURL, api.JsonMIMEType, strings.NewReader("not-json"))
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
	})

	t.Run("AddTaskHandler missing required fields", func(t *testing.T) {
		payload := `{"id": "", "cron_expr": "", "description": ""}`
		resp, err := http.Post(tasksURL, api.JsonMIMEType, strings.NewReader(payload))
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
	})

	t.Run("UpdateTaskHandler wrong method", func(t *testing.T) {
		req, err := http.NewRequest(http.MethodGet, tasksURL+"/test", nil)
		require.NoError(t, err)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusNotFound, resp.StatusCode)
	})

	t.Run("UpdateTaskHandler missing id parameter", func(t *testing.T) {
		payload := `{"cron_expr": "*/5 * * * *", "description": "updated"}`
		req, err := http.NewRequest(http.MethodPut, tasksURL, strings.NewReader(payload))
		require.NoError(t, err)
		req.Header.Set(api.ContentType, api.JsonMIMEType)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusMethodNotAllowed, resp.StatusCode)
	})

	t.Run("UpdateTaskHandler malformed JSON", func(t *testing.T) {
		req, err := http.NewRequest(http.MethodPatch, tasksURL+"/"+testTaskId, strings.NewReader("not-json"))
		require.NoError(t, err)
		req.Header.Set(api.ContentType, api.JsonMIMEType)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
	})

	t.Run("UpdateTaskHandler missing required fields", func(t *testing.T) {
		payload := `{"cron_expr": "", "description": ""}`
		req, err := http.NewRequest(http.MethodPatch, tasksURL+"/"+testTaskId, strings.NewReader(payload))
		require.NoError(t, err)
		req.Header.Set(api.ContentType, api.JsonMIMEType)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
	})

	t.Run("RemoveTaskHandler wrong method", func(t *testing.T) {
		req, err := http.NewRequest(http.MethodGet, tasksURL+"/test", nil)
		require.NoError(t, err)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusNotFound, resp.StatusCode)
	})

	t.Run("RemoveTaskHandler missing task id", func(t *testing.T) {
		req, err := http.NewRequest(http.MethodDelete, tasksURL, nil)
		require.NoError(t, err)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusMethodNotAllowed, resp.StatusCode)
	})

	t.Run("ExecutionHistoryHandler wrong method", func(t *testing.T) {
		req, err := http.NewRequest(http.MethodPut, tasksServerURL+routes.TasksHistoryEndpoint, nil)
		require.NoError(t, err)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusMethodNotAllowed, resp.StatusCode)
	})

	t.Run("EnableTask non-existent", func(t *testing.T) {
		req, err := http.NewRequest(http.MethodPost, tasksURL+"/no-such-task/enable", nil)
		require.NoError(t, err)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusNotFound, resp.StatusCode)
	})

	t.Run("DisableTask non-existent", func(t *testing.T) {
		req, err := http.NewRequest(http.MethodPost, tasksURL+"/nope/disable", nil)
		require.NoError(t, err)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusNotFound, resp.StatusCode)
	})

	t.Run("EnableTask wrong method", func(t *testing.T) {
		req, err := http.NewRequest(http.MethodGet, tasksURL+"/"+testTaskId+"/enable", nil)
		require.NoError(t, err)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusMethodNotAllowed, resp.StatusCode)
	})

	t.Run("DisableTask wrong method", func(t *testing.T) {
		req, err := http.NewRequest(http.MethodPut, tasksURL+"/"+testTaskId+"/disable", nil)
		require.NoError(t, err)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusMethodNotAllowed, resp.StatusCode)
	})
}

func TestTaskDoesNotScheduleBeforeStartAt(t *testing.T) {
	clearTasks(t)

	start := time.Now().Add(5 * time.Second)

	task := api.Task{
		ID:          "future-task",
		CronExpr:    "* * * * *", // valid 5-field cron
		Description: "test future start window",
		Type:        api.TaskTypeSnapshot,
		Enabled:     true,
		StartAt:     start,
		Params:      map[string]any{api.SnapshotIDKey: "default"},
	}

	body, _ := json.Marshal(task)
	resp, err := http.Post(tasksURL, api.JsonMIMEType, bytes.NewReader(body))
	require.NoError(t, err)
	resp.Body.Close()
	require.Equal(t, http.StatusCreated, resp.StatusCode)

	resp, err = http.Get(tasksURL + "/future-task")
	require.NoError(t, err)
	defer resp.Body.Close()

	var ret api.Task
	json.NewDecoder(resp.Body).Decode(&ret)

	assert.True(t, ret.Enabled)
	assert.Equal(t, int64(0), int64(ret.CronEntryID), "CronEntryID must be zero before StartAt")
}

func TestTaskAutoDisablesAfterEndAt(t *testing.T) {
	clearTasks(t)

	end := time.Now().Add(2 * time.Second)

	task := api.Task{
		ID:          "end-window-task",
		CronExpr:    "* * * * *",
		Description: "test end window",
		Type:        api.TaskTypeSnapshot,
		Enabled:     true,
		EndAt:       end,
		Params:      map[string]any{api.SnapshotIDKey: "default"},
	}

	body, _ := json.Marshal(task)
	resp, err := http.Post(tasksURL, api.JsonMIMEType, bytes.NewReader(body))
	require.NoError(t, err)
	resp.Body.Close()
	require.Equal(t, http.StatusCreated, resp.StatusCode)

	// Wait for EndAt + window manager evaluation
	time.Sleep(35 * time.Second)

	resp, err = http.Get(tasksURL + "/end-window-task")
	require.NoError(t, err)
	defer resp.Body.Close()

	var ret api.Task
	json.NewDecoder(resp.Body).Decode(&ret)

	assert.False(t, ret.Enabled, "Task must auto-disable after EndAt")
	assert.Equal(t, int64(0), int64(ret.CronEntryID), "CronEntryID must be cleared after EndAt")
}

func TestUpdateTaskRespectsNewStartAt(t *testing.T) {
	clearTasks(t)
	createTask(t) // from your existing helper

	newStart := time.Now().Add(3 * time.Second)

	patch := api.TaskSnapshopPatch{
		StartAt: &newStart,
	}

	body, _ := json.Marshal(patch)

	req, err := http.NewRequest(http.MethodPatch, tasksURL+"/test-task", bytes.NewReader(body))
	require.NoError(t, err)
	req.Header.Set(api.ContentType, api.JsonMIMEType)

	resp, err := http.DefaultClient.Do(req)
	require.NoError(t, err)
	resp.Body.Close()

	resp, err = http.Get(tasksURL + "/test-task")
	require.NoError(t, err)
	defer resp.Body.Close()

	var ret api.Task
	json.NewDecoder(resp.Body).Decode(&ret)

	assert.True(t, ret.Enabled)
	assert.Equal(t, int64(0), int64(ret.CronEntryID), "CronEntryID must be cleared after updating StartAt into the future")
}
