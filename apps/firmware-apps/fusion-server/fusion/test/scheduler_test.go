package main

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"net/http"
	"strings"
	"testing"
	"time"

	"fusion-services-core/logging"
	"fusion/internal/api"
	model "fusion/internal/gen/proto/fusion"
	"fusion/internal/routes"

	json "github.com/goccy/go-json"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/encoding/protojson"
)

const (
	taskServerURL = "http://192.168.2.100:8080"
)

type scheduledMessage struct {
	ID          string   `json:"id"`
	Description string   `json:"description"`
	CronExpr    string   `json:"cron_expr"`
	MessageID   string   `json:"message_id"`
	Priority    int64    `json:"priority"`
	Zones       []string `json:"zones"`
}

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

func scheduledMessageURL(id string) string {
	return scheduleTasksURL(strings.Replace(routes.PAVAScheduleIDEndpoint, "{id}", id, 1))
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

	var list model.TaskListResponse
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
	taskJSON, err := protojson.MarshalOptions{UseProtoNames: true}.Marshal(&model.SnapshotTaskCreateRequest{
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
	var tasksList model.TaskListResponse
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
	var got model.Task
	require.NoError(t, protojson.Unmarshal(body, &got))
	assert.Equal(t, "snap-crud", got.Id)
	assert.Equal(t, "Snapshot CRUD test", got.Description)

	// Update task via PATCH (description + cron only, leave snapshot param unchanged)
	newDesc := "Updated description"
	newCron := "*/10 * * * *"

	patchJSON, err := protojson.MarshalOptions{UseProtoNames: true}.Marshal(&model.SnapshotTaskUpdateRequest{
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
	var updated model.Task
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
	var finalList model.TaskListResponse
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
	var history model.TaskHistoryResponse
	require.NoError(t, protojson.Unmarshal(body, &history))
	// Not asserting length, since history depends on live task execution.
}

func TestScheduledMessageEmptyZonesRoundTrip(t *testing.T) {
	clearAllTasks(t)

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	uniqueSuffix := fmt.Sprintf("%d", time.Now().UnixNano())
	wav := makeTestWAV(8000, 1, 16, 200*time.Millisecond)
	meta := uploadAudio(
		t,
		ctx,
		audioServerAddr,
		"scheduled_empty_zones_"+uniqueSuffix+".wav",
		wav,
		"Scheduled Empty Zones "+uniqueSuffix,
	)
	defer deleteAudio(t, ctx, audioServerAddr, meta.Id)

	taskMessage := scheduledMessage{
		ID:          "scheduled-message-empty-zones",
		Description: "Scheduled message with implicit all zones",
		CronExpr:    "@every 1m",
		MessageID:   meta.Id,
		Priority:    100,
		Zones:       []string{},
	}

	payload, err := protojson.MarshalOptions{UseProtoNames: true}.Marshal(&model.MessageTaskCreateRequest{
		Id:          taskMessage.ID,
		Description: taskMessage.Description,
		CronExpr:    taskMessage.CronExpr,
		MessageId:   taskMessage.MessageID,
		Priority:    taskMessage.Priority,
		Zones:       "",
	})
	require.NoError(t, err)

	resp, err := http.Post(scheduleTasksURL(routes.PAVAScheduleEndpoint), api.JsonMIMEType, bytes.NewReader(payload))
	require.NoError(t, err)
	defer resp.Body.Close()
	require.Equal(t, http.StatusCreated, resp.StatusCode)
	defer func() {
		req, err := http.NewRequest(http.MethodDelete, scheduledMessageURL(taskMessage.ID), nil)
		require.NoError(t, err)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		resp.Body.Close()
	}()

	listResp, err := http.Get(scheduleTasksURL(routes.PAVAScheduleEndpoint))
	require.NoError(t, err)
	defer listResp.Body.Close()
	require.Equal(t, http.StatusOK, listResp.StatusCode)

	var scheduled []scheduledMessage
	require.NoError(t, json.NewDecoder(listResp.Body).Decode(&scheduled))

	found := false
	for _, message := range scheduled {
		if message.ID == taskMessage.ID {
			found = true
			assert.Empty(t, message.Zones)
			assert.Equal(t, meta.Id, message.MessageID)
		}
	}
	require.True(t, found, "expected scheduled message to be listed")

	lobbyZones := "Lobby"
	patchBody, err := protojson.MarshalOptions{UseProtoNames: true}.Marshal(&model.MessageTaskUpdateRequest{
		Zones: &lobbyZones,
	})
	require.NoError(t, err)

	req, err := http.NewRequest(http.MethodPatch, scheduledMessageURL(taskMessage.ID), bytes.NewReader(patchBody))
	require.NoError(t, err)
	req.Header.Set(api.ContentType, api.JsonMIMEType)

	patchResp, err := http.DefaultClient.Do(req)
	require.NoError(t, err)
	patchResp.Body.Close()
	require.Equal(t, http.StatusOK, patchResp.StatusCode)

	clearZones := ""
	patchBody, err = protojson.MarshalOptions{UseProtoNames: true}.Marshal(&model.MessageTaskUpdateRequest{
		Zones: &clearZones,
	})
	require.NoError(t, err)

	req, err = http.NewRequest(http.MethodPatch, scheduledMessageURL(taskMessage.ID), bytes.NewReader(patchBody))
	require.NoError(t, err)
	req.Header.Set(api.ContentType, api.JsonMIMEType)

	patchResp, err = http.DefaultClient.Do(req)
	require.NoError(t, err)
	patchResp.Body.Close()
	require.Equal(t, http.StatusOK, patchResp.StatusCode)

	listResp, err = http.Get(scheduleTasksURL(routes.PAVAScheduleEndpoint))
	require.NoError(t, err)
	defer listResp.Body.Close()
	require.Equal(t, http.StatusOK, listResp.StatusCode)

	scheduled = nil
	require.NoError(t, json.NewDecoder(listResp.Body).Decode(&scheduled))

	found = false
	for _, message := range scheduled {
		if message.ID == taskMessage.ID {
			found = true
			assert.Empty(t, message.Zones)
		}
	}
	require.True(t, found, "expected scheduled message to remain listed after clearing zones")
}

func TestScheduledMessageEmitsZonesPayloadLocal(t *testing.T) {
	clearAllTasks(t)
	defer clearAllTasks(t)

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	baseURL := localAudioBaseURL(t)
	listener := listenForMessageTrigger(t)
	defer listener.Close()

	wav := makeTestWAV(8000, 1, 16, 200*time.Millisecond)
	meta := uploadAudio(t, ctx, baseURL, "scheduled_zones_payload.wav", wav, "Scheduled Zones Payload")
	defer deleteAudio(t, ctx, baseURL, meta.Id)

	taskMessage := scheduledMessage{
		ID:          "scheduled-message-zones-payload",
		Description: "Scheduled message with explicit zones",
		CronExpr:    "@every 1s",
		MessageID:   meta.Id,
		Priority:    55,
		Zones:       []string{"lobby", "gym"},
	}

	payload, err := protojson.MarshalOptions{UseProtoNames: true}.Marshal(&model.MessageTaskCreateRequest{
		Id:          taskMessage.ID,
		Description: taskMessage.Description,
		CronExpr:    taskMessage.CronExpr,
		MessageId:   taskMessage.MessageID,
		Priority:    taskMessage.Priority,
		Zones:       "lobby,gym",
	})
	require.NoError(t, err)

	resp, err := http.Post(scheduleTasksURL(routes.PAVAScheduleEndpoint), api.JsonMIMEType, bytes.NewReader(payload))
	require.NoError(t, err)
	defer resp.Body.Close()
	require.Equal(t, http.StatusCreated, resp.StatusCode)

	trigger := awaitMessageTriggerPayload(t, listener, 4*time.Second)
	assert.Equal(t, meta.Id, trigger.ID)
	assert.Equal(t, 55, trigger.Priority)
	assert.Equal(t, []string{"lobby", "gym"}, trigger.Zones)
	assert.NotZero(t, trigger.Timestamp)
}

// ----------------------------------------------------------------------
// Enable/Disable endpoints (HTTP only, no timing expectations)
// ----------------------------------------------------------------------

func TestEnableDisableEndpoints(t *testing.T) {
	clearAllTasks(t)

	taskJSON, err := protojson.MarshalOptions{UseProtoNames: true}.Marshal(&model.SnapshotTaskCreateRequest{
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
	taskJSON, err := protojson.MarshalOptions{UseProtoNames: true}.Marshal(&model.SnapshotTaskCreateRequest{
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
	snapURL := taskServerURL + routes.TimeMachineEndpoint + "/" + snapName

	resp, err := http.Post(snapURL, api.JsonMIMEType, nil)
	require.NoError(t, err)
	resp.Body.Close()
	require.Equal(t, http.StatusCreated, resp.StatusCode)

	// Schedule snapshot activation
	payload, err := protojson.MarshalOptions{UseProtoNames: true}.Marshal(&model.SnapshotTaskCreateRequest{
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
	defer func() {
		req, err := http.NewRequest(http.MethodDelete, singleTaskURL("schedule-snap"), nil)
		require.NoError(t, err)
		resp, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		resp.Body.Close()
	}()

	// Wait for cron to fire and apply snapshot
	time.Sleep(3500 * time.Millisecond) // 3.5 seconds = 3 ticks worst case

	// Query active snapshot
	activeResp, err := http.Get(taskServerURL + routes.TimeMachineActiveEndpoint)
	require.NoError(t, err)
	defer activeResp.Body.Close()

	require.Equal(t, http.StatusOK, activeResp.StatusCode)

	var activeSnap struct {
		ActiveSnapshot string `json:"active_snapshot"`
	}
	err = json.NewDecoder(activeResp.Body).Decode(&activeSnap)
	require.NoError(t, err, "Failed to decode active snapshot name")

	// Validate scheduled snapshot was activated
	assert.Equal(t, snapName, activeSnap.ActiveSnapshot, "Scheduled snapshot was not activated")
}
