package tasks

import (
	"context"
	"testing"
	"time"

	"fusion/internal/api"
	"fusion-services-core/logging"
)

type mockTM struct {
	TaskManager
	disabledTasks []string
}

func runWrapped(tm *mockTM, task *api.Task, now time.Time) (called bool) {
	fn := func(ctx context.Context) error {
		called = true
		return nil
	}

	wrapped := tm.wrapTask(task, fn)

	// Inject a fake time using time.Now mocking pattern:
	nowFunction = func() time.Time { return now }
	defer func() { nowFunction = time.Now }()

	wrapped()
	return
}

var nowFunction = time.Now

func init() {
	logging.InitLogger(logging.LogConfig{
		NodeName:    "test",
		LogDir:      "/tmp",
		MaxFileSize: 1,
		MaxFiles:    1,
		LogLevel:    logging.ERROR,
	})
}

func TestWrapTask_AllowsExecutionInsideRecurringWindow(t *testing.T) {
	tm := &mockTM{}

	task := &api.Task{
		ID:          "rec-win",
		Description: "test recurring window",
		Type:        api.TaskTypeMessage,
		Enabled:     true,
		Recurrence: &api.RecurringWindow{
			StartTime: "09:00",
			EndTime:   "17:00",
			Days:      []int{1, 2, 3, 4, 5}, // Mon–Fri
		},
	}

	// Wednesday 10:00 AM (inside window)
	now := time.Date(2024, 1, 3, 10, 0, 0, 0, time.UTC) // Wednesday

	called := runWrapped(tm, task, now)
	if !called {
		t.Fatal("Expected wrapped task to execute inside recurring window")
	}
}

func TestWrapTask_RespectsDayOfWeek(t *testing.T) {
	tm := &mockTM{}

	task := &api.Task{
		ID:          "dow",
		Description: "test dow",
		Type:        api.TaskTypeMessage,
		Enabled:     true,
		Recurrence: &api.RecurringWindow{
			StartTime: "09:00",
			EndTime:   "17:00",
			Days:      []int{1}, // Monday only
		},
	}

	// Tuesday 10:00 AM
	now := time.Date(2024, 1, 2, 10, 0, 0, 0, time.UTC) // Tuesday

	called := runWrapped(tm, task, now)
	if called {
		t.Fatal("Expected wrapped task to skip on non-matching weekday")
	}
}

func TestWrapTask_ExecutesWhenNoWindows(t *testing.T) {
	tm := &mockTM{}

	task := &api.Task{
		ID:      "simple",
		Type:    api.TaskTypeMessage,
		Enabled: true,
	}

	now := time.Now()

	called := runWrapped(tm, task, now)
	if !called {
		t.Fatal("Expected wrapped task to run when no windows are defined")
	}
}
