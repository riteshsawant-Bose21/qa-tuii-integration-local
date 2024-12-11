package timers

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"sync"
	"time"

	"fusion/internal/logging"

	"github.com/robfig/cron/v3"
)

const (
	contentType     = "Content-Type"
	jsonContentType = "application/json"
	maxHistory      = 100
)

// TimerTask represents a task with a unique ID, a cron expression, and a function to execute.
type TimerTask struct {
	ID          string `json:"id"`
	CronExpr    string `json:"cron_expr"`
	Description string `json:"description"`
	EntryID     cron.EntryID
}

// ExecutionRecord represents a log entry for a task execution.
type ExecutionRecord struct {
	TaskID      string    `json:"task_id"`
	Timestamp   time.Time `json:"timestamp"`
	Status      string    `json:"status"`
	Description string    `json:"description"`
}

// TimerManager manages tasks and provides execution history with rotation.
type TimerManager struct {
	c                *cron.Cron
	tasks            map[string]*TimerTask
	taskFuncs        map[string]func()
	executionHistory []ExecutionRecord
	mu               sync.Mutex
	filePath         string
	historyFilePath  string
}

// NewTimerManager initializes and returns a new TimerManager with persistence.
func NewTimerManager(filePath, historyFilePath string) *TimerManager {
	return &TimerManager{
		c:                cron.New(),
		tasks:            make(map[string]*TimerTask),
		taskFuncs:        make(map[string]func()),
		executionHistory: make([]ExecutionRecord, 0),
		filePath:         filePath,
		historyFilePath:  historyFilePath,
	}
}

// AddTask adds a new timer task and persists it.
func (tm *TimerManager) AddTask(id, cronExpr, description string, taskFunc func()) error {

	tm.mu.Lock()
	defer tm.mu.Unlock()

	logger := logging.GetLogger()

	if _, exists := tm.tasks[id]; exists {
		logger.Warn("Task with ID '%s' already exists", id)
		return fmt.Errorf("task with ID '%s' already exists", id)
	}

	// Wrap the taskFunc to track execution history
	wrappedTaskFunc := tm.wrapTask(id, taskFunc)

	entryID, err := tm.c.AddFunc(cronExpr, wrappedTaskFunc)
	if err != nil {
		logger.Error("Failed to add task '%s': %v", id, err)
		return err
	}

	tm.tasks[id] = &TimerTask{
		ID:          id,
		CronExpr:    cronExpr,
		Description: description,
		EntryID:     entryID,
	}
	tm.taskFuncs[id] = wrappedTaskFunc

	logger.Info("Task '%s' added with cron expression '%s'", id, cronExpr)

	return tm.saveTasks()
}

// UpdateTask updates an existing timer task.
func (tm *TimerManager) UpdateTask(id, cronExpr, description string, taskFunc func()) error {
	tm.mu.Lock()
	defer tm.mu.Unlock()

	logger := logging.GetLogger()

	task, exists := tm.tasks[id]
	if !exists {
		logger.Warn("No task found with ID '%s'", id)
		return fmt.Errorf("no task found with ID '%s'", id)
	}

	tm.c.Remove(task.EntryID)

	// Wrap the new taskFunc to track execution history
	wrappedTaskFunc := tm.wrapTask(id, taskFunc)

	entryID, err := tm.c.AddFunc(cronExpr, wrappedTaskFunc)
	if err != nil {
		logger.Error("Failed to update task '%s': %v", id, err)
		return err
	}

	task.CronExpr = cronExpr
	task.Description = description
	task.EntryID = entryID
	tm.taskFuncs[id] = wrappedTaskFunc

	logger.Info("Task '%s' updated with new cron expression '%s'", id, cronExpr)

	return tm.saveTasks()
}

// RemoveTask removes a task by its ID.
func (tm *TimerManager) RemoveTask(id string) error {
	tm.mu.Lock()
	defer tm.mu.Unlock()

	logger := logging.GetLogger()

	task, exists := tm.tasks[id]
	if !exists {
		logger.Warn("No task found with ID '%s'", id)
		return fmt.Errorf("no task found with ID '%s'", id)
	}

	tm.c.Remove(task.EntryID)
	delete(tm.tasks, id)
	delete(tm.taskFuncs, id)

	logger.Info("Task '%s' removed successfully", id)

	return tm.saveTasks()
}

// ListTasks returns a list of all tasks currently managed by the TimerManager.
func (tm *TimerManager) ListTasks() []TimerTask {
	tm.mu.Lock()
	defer tm.mu.Unlock()

	var taskList []TimerTask
	for _, task := range tm.tasks {
		taskList = append(taskList, *task)
	}

	return taskList
}

// wrapTask wraps a task function to track execution history and handle panics.
func (tm *TimerManager) wrapTask(id string, taskFunc func()) func() {
	logger := logging.GetLogger()

	return func() {
		defer func() {
			if r := recover(); r != nil {
				tm.recordExecution(id, "failed", fmt.Sprintf("Panic: %v", r))
				logger.Error("Task '%s' failed with panic: %v", id, r)
			}
		}()
		taskFunc()
		tm.recordExecution(id, "success", "Task executed successfully")
		logger.Info("Task '%s' executed successfully", id)
	}
}

// recordExecution records a task execution log entry with rotation.
func (tm *TimerManager) recordExecution(taskID, status, description string) {
	tm.mu.Lock()
	defer tm.mu.Unlock()

	record := ExecutionRecord{
		TaskID:      taskID,
		Timestamp:   time.Now(),
		Status:      status,
		Description: description,
	}

	tm.executionHistory = append(tm.executionHistory, record)
	if len(tm.executionHistory) > maxHistory {
		tm.executionHistory = tm.executionHistory[len(tm.executionHistory)-maxHistory:]
	}

	_ = tm.saveHistory()
}

// saveTasks saves the current tasks to a file for persistence.
func (tm *TimerManager) saveTasks() error {

	tasksToSave := make([]TimerTask, 0, len(tm.tasks))
	for _, task := range tm.tasks {
		task.EntryID = 0
		tasksToSave = append(tasksToSave, *task)
	}

	data, err := json.MarshalIndent(tasksToSave, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(tm.filePath, data, 0644)
}

// saveHistory saves the execution history to a file.
func (tm *TimerManager) saveHistory() error {
	data, err := json.MarshalIndent(tm.executionHistory, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(tm.historyFilePath, data, 0644)
}

// loadTasks loads tasks from the persistence file and schedules them.
func (tm *TimerManager) loadTasks() error {
	tm.mu.Lock()
	defer tm.mu.Unlock()

	data, err := os.ReadFile(tm.filePath)
	if err != nil {
		if os.IsNotExist(err) {
			tm.tasks = make(map[string]*TimerTask)
			return nil
		}
		return err
	}

	if len(data) == 0 {
		tm.tasks = make(map[string]*TimerTask)
		return nil
	}

	var loadedTasks []TimerTask
	if err := json.Unmarshal(data, &loadedTasks); err != nil {
		return err
	}

	for _, task := range loadedTasks {
		tm.tasks[task.ID] = &task
	}

	return nil
}

// loadHistory loads the execution history from a file.
func (tm *TimerManager) loadHistory() error {
	tm.mu.Lock()
	defer tm.mu.Unlock()

	data, err := os.ReadFile(tm.historyFilePath)
	if err != nil {
		if os.IsNotExist(err) {
			tm.executionHistory = make([]ExecutionRecord, 0)
			return nil
		}
		return err
	}

	if len(data) == 0 {
		tm.executionHistory = make([]ExecutionRecord, 0)
		return nil
	}

	return json.Unmarshal(data, &tm.executionHistory)
}

// GetExecutionHistory retrieves the execution history.
func (tm *TimerManager) GetExecutionHistory() []ExecutionRecord {
	tm.mu.Lock()
	defer tm.mu.Unlock()

	return tm.executionHistory
}

// Start starts the TimerManager's scheduler.
func (tm *TimerManager) Start() error {
	if err := tm.loadTasks(); err != nil {
		return err
	}
	if err := tm.loadHistory(); err != nil {
		return err
	}
	tm.c.Start()
	return nil
}

// Stop stops the TimerManager's scheduler.
func (tm *TimerManager) Stop() {
	tm.c.Stop()
}

// ListTasksHandler handles HTTP GET requests to list all tasks.
func (tm *TimerManager) ListTasksHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	tm.mu.Lock()
	tasks := make([]TimerTask, 0, len(tm.tasks))
	for _, task := range tm.tasks {
		tasks = append(tasks, *task)
	}
	tm.mu.Unlock()

	w.Header().Set(contentType, jsonContentType)
	json.NewEncoder(w).Encode(tasks)
}

// AddTaskHandler handles HTTP POST requests to add a new task.
func (tm *TimerManager) AddTaskHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading request body: %v", err), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	var task TimerTask
	if err := json.Unmarshal(body, &task); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
		return
	}

	if task.ID == "" || task.CronExpr == "" || task.Description == "" {
		http.Error(w, "Task ID, cron expression, and description are required", http.StatusBadRequest)
		return
	}

	err = tm.AddTask(task.ID, task.CronExpr, task.Description, func() {
		fmt.Printf("Task '%s' executed\n", task.ID)
	})
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.WriteHeader(http.StatusCreated)
}

// UpdateTaskHandler handles HTTP PUT requests to update an existing task.
func (tm *TimerManager) UpdateTaskHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	id := r.URL.Query().Get("id")
	if id == "" {
		http.Error(w, "Task ID is required", http.StatusBadRequest)
		return
	}

	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading request body: %v", err), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	var task TimerTask
	if err := json.Unmarshal(body, &task); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
		return
	}

	if task.CronExpr == "" || task.Description == "" {
		http.Error(w, "Cron expression and description are required", http.StatusBadRequest)
		return
	}

	err = tm.UpdateTask(id, task.CronExpr, task.Description, func() {
		fmt.Printf("Task '%s' updated and executed\n", id)
	})
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.WriteHeader(http.StatusOK)
}

// RemoveTaskHandler handles HTTP DELETE requests to remove a task by ID.
func (tm *TimerManager) RemoveTaskHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	id := r.URL.Query().Get("id")
	if id == "" {
		http.Error(w, "Task ID is required", http.StatusBadRequest)
		return
	}

	err := tm.RemoveTask(id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.WriteHeader(http.StatusOK)
}

// ExecutionHistoryHandler handles HTTP GET requests to retrieve the execution history.
func (tm *TimerManager) ExecutionHistoryHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	tm.mu.Lock()
	history := tm.executionHistory
	tm.mu.Unlock()

	w.Header().Set(contentType, jsonContentType)
	json.NewEncoder(w).Encode(history)
}
