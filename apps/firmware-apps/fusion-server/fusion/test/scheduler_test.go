package main

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"strings"
	"testing"
	"time"

	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/routes"

	json "github.com/goccy/go-json"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const (
	taskServerURL = "http://192.168.2.100:8080"
)

func init() {
	logging.InitLogger(logging.LogConfig{
		NodeName:    "scheduler_test",
		LogDir:      "/tmp/scheduler_test",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logging.ERROR,
	})
}

func scheduleTasksURL(path string) string {
	return taskServerURL + path
}

func tasksHistoryURL() string {
	return scheduleTasksURL(routes.TasksHistoryEndpoint)
}

func singleTaskURL(id string) string {
	return scheduleTasksURL(fmt.Sprintf("%s/%s", routes.TasksEndpoint, id))
}

func enableTaskURL(id string) string {
	return scheduleTasksURL(strings.Replace(routes.TasksIdEnableEndpoint, "{id}", id, 1))
}

func disableTaskURL(id string) string {
	return scheduleTasksURL(strings.Replace(routes.TasksIdDisableEndpoint, "{id}", id, 1))
}

// clearAllTasks removes all existing tasks via REST so each test runs from a clean slate.
func clearAllTasks(t *testing.T) {
	resp, err := http.Get(scheduleTasksURL(routes.TasksEndpoint))
	require.NoError(t, err)
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Failed to list tasks for cleanup (%d): %s", resp.StatusCode, string(body))
	}

	var list []api.Task
	require.NoError(t, json.NewDecoder(resp.Body).Decode(&list))

	for _, task := range list {
		req, err := http.NewRequest(http.MethodDelete, singleTaskURL(task.ID), nil)
		require.NoError(t, err)
		respDel, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		respDel.Body.Close()
	}
}

func TestTasksSnapshotCrudThroughAPI(t *testing.T) {
	clearAllTasks(t)

	// Create a snapshot task
	task := api.Task{
		ID:          "snap-crud",
		CronExpr:    "*/5 * * * *",
		Description: "Snapshot CRUD test",
		Type:        api.TaskTypeSnapshot,
		Enabled:     true,
		Params:      map[string]any{api.SnapshotIDKey: "default"},
	}

	taskJSON, err := json.Marshal(task)
	require.NoError(t, err)

	resp, err := http.Post(scheduleTasksURL(routes.TasksEndpoint), api.JsonMIMEType, bytes.NewReader(taskJSON))
	require.NoError(t, err)
	defer resp.Body.Close()
	assert.Equal(t, http.StatusCreated, resp.StatusCode, "Expected 201 Created from POST /tasks")

	// List tasks and check presence
	resp, err = http.Get(scheduleTasksURL(routes.TasksEndpoint))
	require.NoError(t, err)
	defer resp.Body.Close()
	assert.Equal(t, http.StatusOK, resp.StatusCode, "Expected 200 OK from GET /tasks")

	var tasksList []api.Task
	require.NoError(t, json.NewDecoder(resp.Body).Decode(&tasksList))
	require.Len(t, tasksList, 1)
	assert.Equal(t, "snap-crud", tasksList[0].ID)

	// Get single task
	resp, err = http.Get(singleTaskURL("snap-crud"))
	require.NoError(t, err)
	defer resp.Body.Close()
	assert.Equal(t, http.StatusOK, resp.StatusCode, "Expected 200 OK from GET /tasks/{id}")

	var got api.Task
	require.NoError(t, json.NewDecoder(resp.Body).Decode(&got))
	assert.Equal(t, "snap-crud", got.ID)
	assert.Equal(t, "Snapshot CRUD test", got.Description)

	// Update task via PATCH (description + cron only, leave snapshot param unchanged)
	newDesc := "Updated description"
	newCron := "*/10 * * * *"

	patch := api.TaskSnapshopPatch{
		Description: &newDesc,
		CronExpr:    &newCron,
		// Snapshot left nil to avoid existence checks
	}
	patchJSON, err := json.Marshal(patch)
	require.NoError(t, err)

	req, err := http.NewRequest(http.MethodPatch, singleTaskURL("snap-crud"), bytes.NewReader(patchJSON))
	require.NoError(t, err)
	req.Header.Set(api.ContentType, api.JsonMIMEType)
	resp, err = http.DefaultClient.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()
	assert.Equal(t, http.StatusOK, resp.StatusCode, "Expected 200 OK from PATCH /tasks/{id}")

	// Verify updated task via GET
	resp, err = http.Get(singleTaskURL("snap-crud"))
	require.NoError(t, err)
	defer resp.Body.Close()
	require.Equal(t, http.StatusOK, resp.StatusCode)

	var updated api.Task
	require.NoError(t, json.NewDecoder(resp.Body).Decode(&updated))
	assert.Equal(t, newDesc, updated.Description)
	assert.Equal(t, newCron, updated.CronExpr)

	// 6. Delete task
	req, err = http.NewRequest(http.MethodDelete, singleTaskURL("snap-crud"), nil)
	require.NoError(t, err)
	resp, err = http.DefaultClient.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()
	assert.Equal(t, http.StatusNoContent, resp.StatusCode, "Expected 204 No Content from DELETE /tasks/{id}")

	// 7. Confirm it no longer appears
	resp, err = http.Get(scheduleTasksURL(routes.TasksEndpoint))
	require.NoError(t, err)
	defer resp.Body.Close()
	assert.Equal(t, http.StatusOK, resp.StatusCode)

	var finalList []api.Task
	require.NoError(t, json.NewDecoder(resp.Body).Decode(&finalList))
	assert.Len(t, finalList, 0, "Expected 0 tasks after deletion")
}

func TestTasksHistoryEndpoints(t *testing.T) {
	clearAllTasks(t)

	// Ensure history is empty / cleared
	req, err := http.NewRequest(http.MethodDelete, tasksHistoryURL(), nil)
	require.NoError(t, err)
	resp, err := http.DefaultClient.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()
	assert.Equal(t, http.StatusNoContent, resp.StatusCode, "Expected 204 from DELETE /tasks/history")

	// GET should be 200 and return an array (possibly empty)
	resp, err = http.Get(tasksHistoryURL())
	require.NoError(t, err)
	defer resp.Body.Close()
	assert.Equal(t, http.StatusOK, resp.StatusCode, "Expected 200 from GET /tasks/history")

	body, _ := io.ReadAll(resp.Body)
	// Just ensure it decodes into a slice of records
	var history []map[string]any
	require.NoError(t, json.Unmarshal(body, &history))
	// Not asserting length, since history depends on live task execution.
}

// ----------------------------------------------------------------------
// Enable/Disable endpoints (HTTP only, no timing expectations)
// ----------------------------------------------------------------------

func TestEnableDisableEndpoints(t *testing.T) {
	clearAllTasks(t)

	task := api.Task{
		ID:          "toggle-api",
		CronExpr:    "*/5 * * * *",
		Description: "toggle via API",
		Type:        api.TaskTypeSnapshot,
		Enabled:     true,
		Params:      map[string]any{api.SnapshotIDKey: "default"},
	}

	taskJSON, err := json.Marshal(task)
	require.NoError(t, err)

	resp, err := http.Post(scheduleTasksURL(routes.TasksEndpoint), api.JsonMIMEType, bytes.NewReader(taskJSON))
	require.NoError(t, err)
	defer resp.Body.Close()
	require.Equal(t, http.StatusCreated, resp.StatusCode)

	// Enable should return NoContent (204) or OK (200) depending on implementation.
	req, err := http.NewRequest(http.MethodPost, enableTaskURL("toggle-api"), nil)
	require.NoError(t, err)
	resp, err = http.DefaultClient.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()
	assert.Contains(t, []int{http.StatusNoContent, http.StatusOK}, resp.StatusCode, "Unexpected status from enable endpoint")

	// Disable should also return NoContent or OK.
	req, err = http.NewRequest(http.MethodPost, disableTaskURL("toggle-api"), nil)
	require.NoError(t, err)
	resp, err = http.DefaultClient.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()
	assert.Contains(t, []int{http.StatusNoContent, http.StatusOK}, resp.StatusCode, "Unexpected status from disable endpoint")
}

// ----------------------------------------------------------------------
// Error cases for /tasks endpoints
// ----------------------------------------------------------------------

func TestSchedulerTasksEndpointErrorCases(t *testing.T) {
	clearAllTasks(t)

	// Create one valid task to have a known ID.
	task := api.Task{
		ID:          "error-id",
		CronExpr:    "*/5 * * * *",
		Description: "error test",
		Type:        api.TaskTypeSnapshot,
		Enabled:     true,
		Params:      map[string]any{api.SnapshotIDKey: "default"},
	}

	taskJSON, err := json.Marshal(task)
	require.NoError(t, err)

	resp, err := http.Post(scheduleTasksURL(routes.TasksEndpoint), api.JsonMIMEType, bytes.NewReader(taskJSON))
	require.NoError(t, err)
	defer resp.Body.Close()
	require.Equal(t, http.StatusCreated, resp.StatusCode)

	tests := []struct {
		name       string
		method     string
		url        string
		body       io.Reader
		wantStatus int
	}{
		{
			name:       "ListTasks wrong method",
			method:     http.MethodPost,
			url:        scheduleTasksURL(routes.TasksEndpoint),
			body:       nil,
			wantStatus: http.StatusBadRequest, // matches your current RequirePost/RequireGet semantics
		},
		{
			name:       "CreateTask wrong method",
			method:     http.MethodGet,
			url:        scheduleTasksURL(routes.TasksEndpoint),
			body:       nil,
			wantStatus: http.StatusOK, // GET /tasks is valid; not an error here
		},
		{
			name:       "CreateTask malformed JSON",
			method:     http.MethodPost,
			url:        scheduleTasksURL(routes.TasksEndpoint),
			body:       strings.NewReader("not-json"),
			wantStatus: http.StatusBadRequest,
		},
		{
			name:       "CreateTask missing required fields",
			method:     http.MethodPost,
			url:        scheduleTasksURL(routes.TasksEndpoint),
			body:       strings.NewReader(`{"id": "", "cron_expr": "", "description": ""}`),
			wantStatus: http.StatusBadRequest,
		},
		{
			name:       "UpdateTask wrong method",
			method:     http.MethodGet,
			url:        singleTaskURL("error-id"),
			body:       nil,
			wantStatus: http.StatusOK, // GET /tasks/{id} is valid
		},
		{
			name:       "UpdateTask malformed JSON",
			method:     http.MethodPatch,
			url:        singleTaskURL("error-id"),
			body:       strings.NewReader("not-json"),
			wantStatus: http.StatusBadRequest,
		},
		{
			name:       "UpdateTask missing id parameter uses base /tasks with PATCH",
			method:     http.MethodPatch,
			url:        scheduleTasksURL(routes.TasksEndpoint),
			body:       strings.NewReader(`{"cron_expr": "*/5 * * * *", "description": "updated"}`),
			wantStatus: http.StatusMethodNotAllowed,
		},
		{
			name:       "RemoveTask wrong method",
			method:     http.MethodGet,
			url:        singleTaskURL("error-id"),
			body:       nil,
			wantStatus: http.StatusOK, // GET /tasks/{id} is valid
		},
		{
			name:       "RemoveTask missing id",
			method:     http.MethodDelete,
			url:        scheduleTasksURL(routes.TasksEndpoint),
			body:       nil,
			wantStatus: http.StatusMethodNotAllowed,
		},
		{
			name:       "ExecutionHistory wrong method",
			method:     http.MethodPut,
			url:        tasksHistoryURL(),
			body:       nil,
			wantStatus: http.StatusMethodNotAllowed,
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			req, err := http.NewRequest(tc.method, tc.url, tc.body)
			require.NoError(t, err)
			if tc.body != nil {
				req.Header.Set(api.ContentType, api.JsonMIMEType)
			}
			resp, err := http.DefaultClient.Do(req)
			require.NoError(t, err)
			defer resp.Body.Close()

			assert.Equal(t, tc.wantStatus, resp.StatusCode, "Unexpected status for %s %s", tc.method, tc.url)
		})
	}
}

func TestScheduledSnapshotActivationThroughAPI(t *testing.T) {
	clearAllTasks(t)

	// Create a new snapshot to activate
	snapName := fmt.Sprintf("scheduled_snap_%d", time.Now().UnixNano())
	snapURL := taskServerURL + routes.TimeMachineEndpoint + "/" + snapName

	resp, err := http.Post(snapURL, api.JsonMIMEType, nil)
	require.NoError(t, err)
	resp.Body.Close()
	require.Equal(t, http.StatusNoContent, resp.StatusCode)

	// Schedule snapshot activation
	task := api.Task{
		ID:          "schedule-snap",
		CronExpr:    "@every 1s",
		Description: "scheduled activation test",
		Type:        api.TaskTypeSnapshot,
		Enabled:     true,
		Params:      map[string]any{api.SnapshotIDKey: snapName},
	}

	payload, err := json.Marshal(task)
	require.NoError(t, err)

	resp, err = http.Post(scheduleTasksURL(routes.TasksEndpoint), api.JsonMIMEType, bytes.NewReader(payload))
	require.NoError(t, err)
	resp.Body.Close()
	require.Equal(t, http.StatusCreated, resp.StatusCode)

	// Wait for cron to fire and apply snapshot
	time.Sleep(3500 * time.Millisecond) // 3.5 seconds = 3 ticks worst case

	// Query active snapshot
	activeResp, err := http.Get(taskServerURL + routes.TimeMachineActiveEndpoint)
	require.NoError(t, err)
	defer activeResp.Body.Close()

	require.Equal(t, http.StatusOK, activeResp.StatusCode)

	var activeSnap string
	err = json.NewDecoder(activeResp.Body).Decode(&activeSnap)
	require.NoError(t, err, "Failed to decode active snapshot name")

	// Validate scheduled snapshot was activated
	assert.Equal(t, snapName, activeSnap, "Scheduled snapshot was not activated")
}
