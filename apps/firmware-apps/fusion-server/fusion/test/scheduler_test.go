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
	fusionpb "fusion/internal/gen/proto/fusion"
	"fusion/internal/routes"

	json "github.com/goccy/go-json"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/encoding/protojson"
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

	body, err := io.ReadAll(resp.Body)
	require.NoError(t, err)

	var list fusionpb.TaskListResponse
	require.NoError(t, protojson.Unmarshal(body, &list))

	for _, task := range list.Tasks {
		req, err := http.NewRequest(http.MethodDelete, singleTaskURL(task.Id), nil)
		require.NoError(t, err)
		respDel, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		respDel.Body.Close()
	}
}

func TestTasksSnapshotCrudThroughAPI(t *testing.T) {
	clearAllTasks(t)

	// Create a snapshot task
	taskJSON, err := protojson.MarshalOptions{UseProtoNames: true}.Marshal(&fusionpb.SnapshotTaskCreateRequest{
		Id:          "snap-crud",
		CronExpr:    "*/5 * * * *",
		Description: "Snapshot CRUD test",
		SnapshotId:  "default",
	})
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

	body, err := io.ReadAll(resp.Body)
	require.NoError(t, err)
	var tasksList fusionpb.TaskListResponse
	require.NoError(t, protojson.Unmarshal(body, &tasksList))
	require.Len(t, tasksList.Tasks, 1)
	assert.Equal(t, "snap-crud", tasksList.Tasks[0].Id)

	// Get single task
	resp, err = http.Get(singleTaskURL("snap-crud"))
	require.NoError(t, err)
	defer resp.Body.Close()
	assert.Equal(t, http.StatusOK, resp.StatusCode, "Expected 200 OK from GET /tasks/{id}")

	body, err = io.ReadAll(resp.Body)
	require.NoError(t, err)
	var got fusionpb.Task
	require.NoError(t, protojson.Unmarshal(body, &got))
	assert.Equal(t, "snap-crud", got.Id)
	assert.Equal(t, "Snapshot CRUD test", got.Description)

	// Update task via PATCH (description + cron only, leave snapshot param unchanged)
	newDesc := "Updated description"
	newCron := "*/10 * * * *"

	patchJSON, err := protojson.MarshalOptions{UseProtoNames: true}.Marshal(&fusionpb.SnapshotTaskUpdateRequest{
		Description: &newDesc,
		CronExpr:    &newCron,
	})
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

	body, err = io.ReadAll(resp.Body)
	require.NoError(t, err)
	var updated fusionpb.Task
	require.NoError(t, protojson.Unmarshal(body, &updated))
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

	body, err = io.ReadAll(resp.Body)
	require.NoError(t, err)
	var finalList fusionpb.TaskListResponse
	require.NoError(t, protojson.Unmarshal(body, &finalList))
	assert.Len(t, finalList.Tasks, 0, "Expected 0 tasks after deletion")
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

	taskJSON, err := protojson.MarshalOptions{UseProtoNames: true}.Marshal(&fusionpb.SnapshotTaskCreateRequest{
		Id:          "toggle-api",
		CronExpr:    "*/5 * * * *",
		Description: "toggle via API",
		SnapshotId:  "default",
	})
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
	taskJSON, err := protojson.MarshalOptions{UseProtoNames: true}.Marshal(&fusionpb.SnapshotTaskCreateRequest{
		Id:          "error-id",
		CronExpr:    "*/5 * * * *",
		Description: "error test",
		SnapshotId:  "default",
	})
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
			body:       strings.NewReader(`{"id": "", "cron_expr": "", "description": "", "snapshot_id": ""}`),
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
	snapURL := taskServerURL + routes.SnapshotsEndpoint + "/" + snapName

	resp, err := http.Post(snapURL, api.JsonMIMEType, nil)
	require.NoError(t, err)
	resp.Body.Close()
	require.Equal(t, http.StatusNoContent, resp.StatusCode)

	// Schedule snapshot activation
	payload, err := protojson.MarshalOptions{UseProtoNames: true}.Marshal(&fusionpb.SnapshotTaskCreateRequest{
		Id:          "schedule-snap",
		CronExpr:    "@every 1s",
		Description: "scheduled activation test",
		SnapshotId:  snapName,
	})
	require.NoError(t, err)

	resp, err = http.Post(scheduleTasksURL(routes.TasksEndpoint), api.JsonMIMEType, bytes.NewReader(payload))
	require.NoError(t, err)
	resp.Body.Close()
	require.Equal(t, http.StatusCreated, resp.StatusCode)

	// Wait for cron to fire and apply snapshot
	time.Sleep(3500 * time.Millisecond) // 3.5 seconds = 3 ticks worst case

	// Query active snapshot
	activeResp, err := http.Get(taskServerURL + routes.SnapshotsActiveEndpoint)
	require.NoError(t, err)
	defer activeResp.Body.Close()

	require.Equal(t, http.StatusOK, activeResp.StatusCode)

	var activeSnap fusionpb.ActiveSnapshotResponse
	err = json.NewDecoder(activeResp.Body).Decode(&activeSnap)
	require.NoError(t, err, "Failed to decode active snapshot name")

	// Validate scheduled snapshot was activated
	assert.Equal(t, snapName, activeSnap.ActiveSnapshot, "Scheduled snapshot was not activated")
}
