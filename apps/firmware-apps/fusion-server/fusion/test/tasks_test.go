package main

import (
	"bytes"
	"fmt"
	"fusion/internal/api"
	fusionpb "fusion/internal/gen/proto/fusion"
	"fusion/internal/routes"
	"fusion/internal/tasks"
	"io"
	"net/http"
	"strings"
	"testing"
	"time"

	json "github.com/goccy/go-json"
	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const (
	tasksServerURL = "http://192.168.2.100:8080"
	tasksURL       = tasksServerURL + routes.TasksEndpoint
	testTaskId     = "test-task"
	snapshotID     = "test-snapshot"
)

var protoJSONMarshalOptions = protojson.MarshalOptions{UseProtoNames: true}

func marshalProtoMessage(t *testing.T, msg proto.Message) []byte {
	t.Helper()
	data, err := protoJSONMarshalOptions.Marshal(msg)
	require.NoError(t, err)
	return data
}

func decodeTaskListResponse(t *testing.T, body io.Reader) *fusionpb.TaskListResponse {
	t.Helper()
	data, err := io.ReadAll(body)
	require.NoError(t, err)

	var resp fusionpb.TaskListResponse
	require.NoError(t, protojson.Unmarshal(data, &resp))
	return &resp
}

func decodeTaskResponse(t *testing.T, body io.Reader) *fusionpb.Task {
	t.Helper()
	data, err := io.ReadAll(body)
	require.NoError(t, err)

	var task fusionpb.Task
	require.NoError(t, protojson.Unmarshal(data, &task))
	return &task
}

func newSnapshotTaskRequest(id, snapshot, cronExpr, description string) *fusionpb.SnapshotTaskCreateRequest {
	return &fusionpb.SnapshotTaskCreateRequest{
		Id:          id,
		CronExpr:    cronExpr,
		Description: description,
		SnapshotId:  snapshot,
	}
}

// clearTasks retrieves all tasks from the live server and deletes each one.
// This ensures tests run against a clean slate.
func clearTasks(t *testing.T) {
	resp, err := http.Get(tasksURL)
	require.NoError(t, err)
	defer resp.Body.Close()

	tasksResp := decodeTaskListResponse(t, resp.Body)

	for _, task := range tasksResp.Tasks {
		req, err := http.NewRequest(http.MethodDelete, tasksURL+"/"+task.Id, nil)
		require.NoError(t, err)
		respDel, err := http.DefaultClient.Do(req)
		require.NoError(t, err)
		respDel.Body.Close()
	}
}

func createTask(t *testing.T) {
	taskJSON := marshalProtoMessage(t, newSnapshotTaskRequest(testTaskId, "default", "*/5 * * * *", "Test task description"))

	resp, err := http.Post(tasksURL, api.JsonMIMEType, bytes.NewReader(taskJSON))
	require.NoError(t, err)
	defer resp.Body.Close()
}

// clearHistory clears the execution history on the live server.
func clearHistory(t *testing.T) {
	req, err := http.NewRequest(http.MethodDelete, tasksServerURL+routes.TasksHistoryEndpoint, nil)
	require.NoError(t, err)

	resp, err := http.DefaultClient.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()

	require.Equal(t, http.StatusNoContent, resp.StatusCode)
}

// fetchHistory fetches the current execution history.
func fetchHistory(t *testing.T) []tasks.ExecutionRecord {
	resp, err := http.Get(tasksServerURL + routes.TasksHistoryEndpoint)
	require.NoError(t, err)
	defer resp.Body.Close()

	require.Equal(t, http.StatusOK, resp.StatusCode)

	var history []tasks.ExecutionRecord
	err = json.NewDecoder(resp.Body).Decode(&history)
	require.NoError(t, err)

	return history
}

func TestTaskManagerEndpoints(t *testing.T) {
	// Clean up any existing tasks on the live server.
	clearTasks(t)

	t.Run("AddTaskHandler", func(t *testing.T) {
		taskJSON := marshalProtoMessage(t, newSnapshotTaskRequest(testTaskId, "default", "*/5 * * * *", "Test task description"))

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

		tasksResp := decodeTaskListResponse(t, resp.Body)
		assert.Len(t, tasksResp.Tasks, 1, "Expected 1 task in the list")
		assert.Equal(t, testTaskId, tasksResp.Tasks[0].Id, "Task ID should match")
	})

	t.Run("UpdateTaskHandler", func(t *testing.T) {

		// Update the test-task with new data.
		desc := "Updated task description"
		cron := "*/10 * * * *"
		snap := "default"

		taskJSON := marshalProtoMessage(t, &fusionpb.SnapshotTaskUpdateRequest{
			Description: &desc,
			CronExpr:    &cron,
			SnapshotId:  &snap,
		})

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

		tasksResp := decodeTaskListResponse(t, resp.Body)
		assert.Len(t, tasksResp.Tasks, 0, "Expected 0 tasks in the list after removal")
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

		disabledTask := decodeTaskResponse(t, respGet.Body)
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

		enabledTask := decodeTaskResponse(t, respGet2.Body)
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

	body := marshalProtoMessage(t, &fusionpb.SnapshotTaskCreateRequest{
		Id:          "future-task",
		CronExpr:    "* * * * *",
		Description: "test future start window",
		StartAt:     timestamppb.New(start),
		SnapshotId:  "default",
	})
	resp, err := http.Post(tasksURL, api.JsonMIMEType, bytes.NewReader(body))
	require.NoError(t, err)
	resp.Body.Close()
	require.Equal(t, http.StatusCreated, resp.StatusCode)

	resp, err = http.Get(tasksURL + "/future-task")
	require.NoError(t, err)
	defer resp.Body.Close()

	ret := decodeTaskResponse(t, resp.Body)

	assert.True(t, ret.Enabled)
	assert.False(t, ret.Scheduled, "Task should not be scheduled before StartAt")
}

func TestTaskAutoDisablesAfterEndAt(t *testing.T) {
	clearTasks(t)

	end := time.Now().Add(2 * time.Second)

	body := marshalProtoMessage(t, &fusionpb.SnapshotTaskCreateRequest{
		Id:          "end-window-task",
		CronExpr:    "* * * * *",
		Description: "test end window",
		EndAt:       timestamppb.New(end),
		SnapshotId:  "default",
	})
	resp, err := http.Post(tasksURL, api.JsonMIMEType, bytes.NewReader(body))
	require.NoError(t, err)
	resp.Body.Close()
	require.Equal(t, http.StatusCreated, resp.StatusCode)

	// Wait for EndAt + window manager evaluation
	time.Sleep(35 * time.Second)

	resp, err = http.Get(tasksURL + "/end-window-task")
	require.NoError(t, err)
	defer resp.Body.Close()

	ret := decodeTaskResponse(t, resp.Body)

	assert.False(t, ret.Enabled, "Task must auto-disable after EndAt")
	assert.False(t, ret.Scheduled, "Task should be unscheduled after EndAt")
}

func TestUpdateTaskRespectsNewStartAt(t *testing.T) {
	clearTasks(t)
	createTask(t)

	newStart := time.Now().Add(3 * time.Second)

	body := marshalProtoMessage(t, &fusionpb.SnapshotTaskUpdateRequest{
		StartAt: timestamppb.New(newStart),
	})

	req, err := http.NewRequest(http.MethodPatch, tasksURL+"/test-task", bytes.NewReader(body))
	require.NoError(t, err)
	req.Header.Set(api.ContentType, api.JsonMIMEType)

	resp, err := http.DefaultClient.Do(req)
	require.NoError(t, err)
	resp.Body.Close()

	resp, err = http.Get(tasksURL + "/test-task")
	require.NoError(t, err)
	defer resp.Body.Close()

	ret := decodeTaskResponse(t, resp.Body)

	assert.True(t, ret.Enabled)
	assert.False(t, ret.Scheduled, "Task should be unscheduled after updating StartAt into the future")
}

func TestTaskSchedulesAfterStartAt(t *testing.T) {
	clearTasks(t)

	snapID := fmt.Sprintf("test-snap-%d", time.Now().UnixNano())
	createSnapshot(t, snapID)

	start := time.Now().Add(2 * time.Second)

	body := marshalProtoMessage(t, &fusionpb.SnapshotTaskCreateRequest{
		Id:          "start-window-task",
		CronExpr:    "* * * * *",
		Description: "test start window",
		StartAt:     timestamppb.New(start),
		SnapshotId:  snapID,
	})
	resp, err := http.Post(tasksURL, api.JsonMIMEType, bytes.NewReader(body))
	require.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, http.StatusCreated, resp.StatusCode)

	time.Sleep(35 * time.Second)

	resp, err = http.Get(tasksURL + "/start-window-task")
	require.NoError(t, err)
	defer resp.Body.Close()

	ret := decodeTaskResponse(t, resp.Body)

	assert.True(t, ret.Enabled)
}

func createSnapshot(t *testing.T, id string) {
	url := tasksServerURL + "/snapshots/" + id
	req, err := http.NewRequest(http.MethodPost, url, nil)
	require.NoError(t, err)

	resp, err := http.DefaultClient.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()

	require.Equal(t, http.StatusCreated, resp.StatusCode, "Snapshot must be created before scheduling tasks")
}

// ===== Recurrence tests =====

// Test that a task with a recurring window that lies completely in the future
// does not execute before the window opens (no history entries).
func TestRecurringWindowSkipsOutsideTimeWindow(t *testing.T) {
	clearTasks(t)
	clearHistory(t)

	now := time.Now()
	start := now.Add(2 * time.Minute)
	end := now.Add(4 * time.Minute)

	recurrence := &fusionpb.RecurringWindow{
		StartTime: fmt.Sprintf("%02d:%02d", start.Hour(), start.Minute()),
		EndTime:   fmt.Sprintf("%02d:%02d", end.Hour(), end.Minute()),
		Days:      []int32{int32(now.Weekday())},
	}

	snapID := fmt.Sprintf("recurrence-future-%d", now.UnixNano())
	createSnapshot(t, snapID)

	taskID := "recurrence-future-window"
	body := marshalProtoMessage(t, &fusionpb.SnapshotTaskCreateRequest{
		Id:          taskID,
		CronExpr:    "*/5 * * * * *",
		Description: "recurrence future window",
		Recurrence:  recurrence,
		SnapshotId:  snapID,
	})
	resp, err := http.Post(tasksURL, api.JsonMIMEType, bytes.NewReader(body))
	require.NoError(t, err)
	defer resp.Body.Close()
	require.Equal(t, http.StatusCreated, resp.StatusCode)

	// Wait long enough for several cron ticks, but still before the start time.
	time.Sleep(70 * time.Second)

	history := fetchHistory(t)
	for _, rec := range history {
		if rec.TaskID == taskID {
			t.Fatalf("task %s should not execute before recurring window opens, but history entry was found: %+v", taskID, rec)
		}
	}
}

// Test that the day-of-week filter in RecurringWindow is respected.
// We create a window that is "open" all day, but on the wrong weekday.
func TestRecurringWindowRespectsDaysOfWeek(t *testing.T) {
	clearTasks(t)
	clearHistory(t)

	now := time.Now()
	// Choose a weekday that is NOT today.
	wrongDay := (int(now.Weekday()) + 1) % 7

	recurrence := &fusionpb.RecurringWindow{
		StartTime: "00:00",
		EndTime:   "23:59",
		Days:      []int32{int32(wrongDay)},
	}

	snapID := fmt.Sprintf("recurrence-wrong-day-%d", now.UnixNano())
	createSnapshot(t, snapID)

	taskID := "recurrence-wrong-day"
	body := marshalProtoMessage(t, &fusionpb.SnapshotTaskCreateRequest{
		Id:          taskID,
		CronExpr:    "*/5 * * * * *",
		Description: "recurrence wrong weekday",
		Recurrence:  recurrence,
		SnapshotId:  snapID,
	})
	resp, err := http.Post(tasksURL, api.JsonMIMEType, bytes.NewReader(body))
	require.NoError(t, err)
	defer resp.Body.Close()
	require.Equal(t, http.StatusCreated, resp.StatusCode)

	// Even though the time-of-day window is open, the wrong day-of-week
	// should prevent any executions.
	time.Sleep(40 * time.Second)

	history := fetchHistory(t)
	for _, rec := range history {
		if rec.TaskID == taskID {
			t.Fatalf("task %s should not execute on a non-matching weekday, but history entry was found: %+v", taskID, rec)
		}
	}
}

// Test that a task with a recurring window that covers "now" actually executes
// at least once while the window is open.
func TestRecurringWindowAllowsExecutionInsideWindow(t *testing.T) {
	clearTasks(t)
	clearHistory(t)

	now := time.Now()
	startStr := fmt.Sprintf("%02d:%02d", now.Hour(), now.Minute())
	end := now.Add(3 * time.Minute)
	endStr := fmt.Sprintf("%02d:%02d", end.Hour(), end.Minute())

	recurrence := &fusionpb.RecurringWindow{
		StartTime: startStr,
		EndTime:   endStr,
		Days:      []int32{int32(now.Weekday())},
	}

	snapID := fmt.Sprintf("recurrence-active-%d", now.UnixNano())
	createSnapshot(t, snapID)

	taskID := "recurrence-active-window"
	body := marshalProtoMessage(t, &fusionpb.SnapshotTaskCreateRequest{
		Id:          taskID,
		CronExpr:    "*/5 * * * * *",
		Description: "recurrence active window",
		Recurrence:  recurrence,
		SnapshotId:  snapID,
	})
	resp, err := http.Post(tasksURL, api.JsonMIMEType, bytes.NewReader(body))
	require.NoError(t, err)
	defer resp.Body.Close()
	require.Equal(t, http.StatusCreated, resp.StatusCode)

	// Wait long enough for several cron ticks while we are inside the window.
	time.Sleep(70 * time.Second)

	history := fetchHistory(t)
	found := false
	for _, rec := range history {
		if rec.TaskID == taskID {
			found = true
			break
		}
	}

	if !found {
		t.Fatalf("expected at least one execution for task %s inside recurring window, but none were found; history: %#v", taskID, history)
	}
}
