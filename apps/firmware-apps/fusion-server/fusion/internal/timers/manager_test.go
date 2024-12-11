package timers

import (
	"fusion/internal/logging"
	"os"
	"strconv"
	"testing"

	"github.com/stretchr/testify/assert"
)

// MockLogger is a simple logger for testing purposes
type MockLogger struct {
	messages []string
}

func (ml *MockLogger) Debug(format string, args ...interface{}) {
	ml.log("DEBUG", format, args...)
}

func (ml *MockLogger) Info(format string, args ...interface{}) {
	ml.log("INFO", format, args...)
}

func (ml *MockLogger) Warn(format string, args ...interface{}) {
	ml.log("WARN", format, args...)
}

func (ml *MockLogger) Error(format string, args ...interface{}) {
	ml.log("ERROR", format, args...)
}

func (ml *MockLogger) Close() {}

func (ml *MockLogger) log(level string, format string, _ ...interface{}) {
	ml.messages = append(ml.messages, level+": "+format)
}

func TestTimerManager(t *testing.T) {

	logging.InitLogger(logging.LogConfig{
		NodeName:    "TimeManager",
		LogDir:      "/tmp/test_manager_test",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logging.DEBUG,
	})

	mockLogger := &MockLogger{}

	// Create temporary files for testing
	taskFile, err := os.CreateTemp("", "tasks_*.json")
	assert.NoError(t, err)
	defer os.Remove(taskFile.Name())
	mockLogger.Info("CreateTemp")
	historyFile, err := os.CreateTemp("", "history_*.json")
	assert.NoError(t, err)
	defer os.Remove(historyFile.Name())

	// Initialize TimerManager
	manager := NewTimerManager(taskFile.Name(), historyFile.Name())
	mockLogger.Info("NewTimerManager")

	// Start the TimerManager and ensure cleanup
	err = manager.Start()
	assert.NoError(t, err)
	defer manager.Stop() // Ensure the cron scheduler stops

	// Add a test task
	taskID := "test-task"
	err = manager.AddTask(taskID, "*/5 * * * *", "Test task", func() {
		mockLogger.Info("Task '%s' executed", taskID)
	})
	assert.NoError(t, err)

	print("AddedTask\n")
	// Verify task is added
	tasks := manager.ListTasks()
	assert.Len(t, tasks, 1)

	// Simulate an execution
	manager.recordExecution(taskID, "success", "Task executed successfully")

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
	// Create temporary files for testing
	taskFile, err := os.CreateTemp("", "tasks_*.json")
	assert.NoError(t, err)
	defer os.Remove(taskFile.Name())

	historyFile, err := os.CreateTemp("", "history_*.json")
	assert.NoError(t, err)
	defer os.Remove(historyFile.Name())

	// Initialize TimerManager with a mock logger
	mockLogger := &MockLogger{}
	manager := NewTimerManager(taskFile.Name(), historyFile.Name())

	// Start the TimerManager
	err = manager.Start()
	assert.NoError(t, err)
	defer manager.Stop()

	// Add tasks to generate history
	for i := 0; i < maxHistory+10; i++ {
		taskID := "task-" + strconv.Itoa(i)
		err = manager.AddTask(taskID, "*/5 * * * *", "Test task", func() {
			mockLogger.Info("Task '%s' executed", taskID)
		})
		assert.NoError(t, err)

		// Simulate a single execution
		manager.recordExecution(taskID, "success", "Task executed successfully")
	}

	// Verify history rotation
	history := manager.GetExecutionHistory()
	assert.Len(t, history, maxHistory)

	// Verify oldest records are dropped
	for i := 0; i < 10; i++ {
		assert.NotContains(t, history, "task-"+strconv.Itoa(i))
	}
}
