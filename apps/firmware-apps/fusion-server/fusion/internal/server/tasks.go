package server

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"sync"
	"time"

	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/utils"

	"github.com/gorilla/mux"
	"github.com/robfig/cron/v3"
	"go.etcd.io/bbolt"
)

const (
	HistoryPath = "history.json"
	MaxHistory  = 100
)

// ExecutionRecord represents a log entry for a task execution.
type ExecutionRecord struct {
	TaskID      string    `json:"task_id"`
	Timestamp   time.Time `json:"timestamp"`
	Status      string    `json:"status"`
	Description string    `json:"description"`
}

// TaskManager manages tasks and provides execution history with rotation.
type TaskManager struct {
	node             string
	persistence      *Persistence
	cron             *cron.Cron
	tasks            map[string]*api.Task
	taskFuncs        map[string]func()
	executionHistory []ExecutionRecord
	mu               sync.Mutex
	historyFilePath  string
	running          bool
}

// NewTaskManager initializes and returns a new TaskManager with persistence.
func NewTaskManager(config *api.AppConfig, persistence *Persistence) *TaskManager {
	return &TaskManager{
		node:             config.NodeName,
		persistence:      persistence,
		cron:             cron.New(),
		tasks:            make(map[string]*api.Task),
		taskFuncs:        make(map[string]func()),
		executionHistory: make([]ExecutionRecord, 0),
		historyFilePath:  HistoryPath,
	}
}

// AddTask adds a new timer task and persists it.
func (tm *TaskManager) AddTask(task *api.Task, taskFunc func()) error {

	tm.mu.Lock()
	defer tm.mu.Unlock()

	logger := logging.GetLogger()

	if _, exists := tm.tasks[task.ID]; exists {
		return fmt.Errorf("task with ID '%s' already exists", task.ID)
	}

	// Wrap the taskFunc to track execution history
	trackedTaskFunc := tm.wrapTask(task, taskFunc)

	entryID, err := tm.cron.AddFunc(task.CronExpr, trackedTaskFunc)
	if err != nil {
		logger.Error("Failed to add task '%s': %v", task.ID, err)
		return err
	}

	task.CronEntryID = entryID
	tm.tasks[task.ID] = task
	tm.taskFuncs[task.ID] = trackedTaskFunc

	return tm.saveTasks()
}

// UpdateTask updates an existing timer task.
func (tm *TaskManager) UpdateTask(task *api.Task, taskFunc func()) error {
	tm.mu.Lock()
	defer tm.mu.Unlock()

	logger := logging.GetLogger()

	_, exists := tm.tasks[task.ID]
	if !exists {
		return fmt.Errorf("no task found with ID '%s'", task.ID)
	}

	tm.cron.Remove(task.CronEntryID)

	// Wrap the new taskFunc to track execution history
	trackedTaskFunc := tm.wrapTask(task, taskFunc)

	entryID, err := tm.cron.AddFunc(task.CronExpr, trackedTaskFunc)
	if err != nil {
		logger.Error("Failed to update task '%s': %v", task.ID, err)
		return err
	}
	task.Enabled = true
	task.CronEntryID = entryID
	tm.tasks[task.ID] = task
	tm.taskFuncs[task.ID] = trackedTaskFunc

	return tm.saveTasks()
}

// RemoveTask removes a task by its ID.
func (tm *TaskManager) RemoveTask(id string) error {
	tm.mu.Lock()
	defer tm.mu.Unlock()

	task, exists := tm.tasks[id]
	if !exists {
		return fmt.Errorf("no task found with ID '%s'", id)
	}

	tm.cron.Remove(task.CronEntryID)
	delete(tm.tasks, id)
	delete(tm.taskFuncs, id)

	return tm.saveTasks()
}

// ListTasks returns a list of all tasks currently managed by the TaskManager.
func (tm *TaskManager) ListTasks() []api.Task {
	tm.mu.Lock()
	defer tm.mu.Unlock()

	var taskList []api.Task
	for _, task := range tm.tasks {
		taskList = append(taskList, *task)
	}

	return taskList
}

// RecordExecution records a task execution log entry with rotation.
func (tm *TaskManager) RecordExecution(task *api.Task, status string) {
	tm.mu.Lock()
	defer tm.mu.Unlock()

	record := ExecutionRecord{
		TaskID:      task.ID,
		Timestamp:   time.Now(),
		Status:      status,
		Description: task.Description,
	}

	tm.executionHistory = append(tm.executionHistory, record)
	if len(tm.executionHistory) > MaxHistory {
		tm.executionHistory = tm.executionHistory[len(tm.executionHistory)-MaxHistory:]
	}

	_ = tm.saveHistory()
}

// GetExecutionHistory retrieves the execution history.
func (tm *TaskManager) GetExecutionHistory() []ExecutionRecord {
	tm.mu.Lock()
	defer tm.mu.Unlock()

	return tm.executionHistory
}

// Start starts the TaskManager's scheduler.
func (tm *TaskManager) Start() error {

	if err := tm.loadTasks(); err != nil {
		return err
	}

	if err := tm.loadHistory(); err != nil {
		return err
	}

	tm.cron.Start()

	tm.running = true

	return nil
}

// Stop stops the TaskManager's scheduler.
func (tm *TaskManager) Stop() {

	tm.cron.Stop()

	logger := logging.GetLogger()

	for id := range tm.tasks {
		err := tm.RemoveTask(id)
		if err != nil {
			logger.Warn("Failed to remove task '%s': %v", id, err)
		}
	}

	tm.running = false
}

// HandleGetTasks handles HTTP GET requests to list all tasks.
func (tm *TaskManager) HandleGetTasks(w http.ResponseWriter, r *http.Request) {

	if !utils.IsGetRequest(r) {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	tm.mu.Lock()
	tasks := make([]api.Task, 0, len(tm.tasks))
	for _, task := range tm.tasks {
		tasks = append(tasks, *task)
	}
	tm.mu.Unlock()

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(tasks)
}

// HandleCreateTask handles HTTP POST requests to add a new task.
func (tm *TaskManager) HandleCreateTask(w http.ResponseWriter, r *http.Request) {

	if !utils.IsPostRequest(r) {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading request body: %v", err), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	var task api.Task
	if err := json.Unmarshal(body, &task); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
		return
	}

	if task.ID == "" || task.CronExpr == "" || task.Description == "" || task.SnapshotID == "" {
		http.Error(w, "Task ID, cron expression, snapshot ID and description are required", http.StatusBadRequest)
		return
	}

	exists, err := tm.persistence.TaskExists(task)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error checking task existence: %v", err), http.StatusInternalServerError)
		return
	}
	if exists {
		http.Error(w, "Task already exists", http.StatusConflict)
		return
	}

	err = tm.AddTask(&task, tm.taskActivateSnapshotFunc(task.SnapshotID))
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.WriteHeader(http.StatusCreated)

	json.NewEncoder(w).Encode(map[string]string{
		"status": "created",
		"id":     task.ID,
	})
}

// HandleGetTask handles HTTP GET requests to get a single task
func (tm *TaskManager) HandleGetTask(w http.ResponseWriter, r *http.Request) {

	if !utils.IsGetRequest(r) {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	id, err := extractTaskID(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	task, err := tm.fetchTask(id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(task)
}

// HandleUpdateTask handles HTTP PUT requests to update an existing task.
func (tm *TaskManager) HandleUpdateTask(w http.ResponseWriter, r *http.Request) {

	if !utils.IsPutRequest(r) {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	id, err := extractTaskID(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading request body: %v", err), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	var task api.Task
	if err := json.Unmarshal(body, &task); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
		return
	}
	task.ID = id

	if task.CronExpr == "" || task.Description == "" {
		http.Error(w, "Cron expression and description are required", http.StatusBadRequest)
		return
	}

	if err = tm.UpdateTask(&task, tm.taskActivateSnapshotFunc(task.SnapshotID)); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
}

// HandleDeleteTask handles HTTP DELETE requests to remove a task by ID.
func (tm *TaskManager) HandleDeleteTask(w http.ResponseWriter, r *http.Request) {

	if !utils.IsDeleteRequest(r) {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	id, err := extractTaskID(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	err = tm.RemoveTask(id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
}

// HandleGetHistory handles HTTP GET requests to retrieve the execution history.
func (tm *TaskManager) HandleGetHistory(w http.ResponseWriter, r *http.Request) {

	if !utils.IsGetRequest(r) {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	tm.mu.Lock()
	history := tm.executionHistory
	tm.mu.Unlock()

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(history)
}

// HandleClearHistory handles HTTP DELETE requests to clear the execution history.
func (tm *TaskManager) HandleClearHistory(w http.ResponseWriter, r *http.Request) {

	if !utils.IsDeleteRequest(r) {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	tm.mu.Lock()
	tm.executionHistory = make([]ExecutionRecord, 0)
	tm.mu.Unlock()
}

// HandleEnableTask handles HTTP POST requests to enable a task
func (tm *TaskManager) HandleEnableTask(w http.ResponseWriter, r *http.Request) {

	if !utils.IsPostRequest(r) {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	_, err := extractTaskID(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading request body: %v", err), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	var task api.Task
	if err := json.Unmarshal(body, &task); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
		return
	}
	exists, err := tm.persistence.SnapshotExists(task.SnapshotID)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error checking snapshot existence: %v", err), http.StatusInternalServerError)
		return
	}
	if exists {
		http.Error(w, "Snapshot already exists", http.StatusConflict)
		return
	}

	if err = tm.UpdateTask(&task, tm.taskActivateSnapshotFunc(task.SnapshotID)); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
}

// HandleEnableTask handles HTTP POST requests to enable a task
func (tm *TaskManager) HandleDisableTask(w http.ResponseWriter, r *http.Request) {

	if !utils.IsPostRequest(r) {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	id, err := extractTaskID(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	task, err := tm.fetchTask(id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}

	tm.cron.Remove(task.CronEntryID)
	task.CronEntryID = 0
	task.Enabled = false

	tm.saveTasks()
}

// taskActivateSnapshotFunc creates a task function that applies a snapshot.
func (tm *TaskManager) taskActivateSnapshotFunc(name string) func() {
	return func() {
		logger := logging.GetLogger()
		logger.Debug("Activating snapshot %s on %s", name, name)

		// Activate the snapshot only on the instance
		if err := tm.persistence.ActivateSnapshot(name); err != nil {
			logger.Error("Snapshot apply task for '%s' failed: %v", name, err)

		} else {
			logger.Debug("Snapshot '%s' activated successfully via task", name)
		}
	}
}

// wrapTask wraps a task function to track execution history and handle panics.
func (tm *TaskManager) wrapTask(task *api.Task, taskFunc func()) func() {
	logger := logging.GetLogger()

	return func() {
		defer func() {
			if r := recover(); r != nil {
				tm.RecordExecution(task, "failed")
				logger.Error("Task '%s' failed with panic: %v", task.ID, r)
			}
		}()
		taskFunc()
		tm.RecordExecution(task, "success")
	}
}

// saveTasks saves the current tasks
func (tm *TaskManager) saveTasks() error {
	return tm.persistence.SaveTasks(tm.tasks)
}

// loadTasks loads tasks from the persistence file and schedules them.
func (tm *TaskManager) loadTasks() error {
	tm.mu.Lock()
	defer tm.mu.Unlock()

	tasks, err := tm.persistence.LoadTasks()
	if err != nil {
		return err
	}

	tm.tasks = tasks

	return nil
}

// saveHistory saves the execution history to a file.
func (tm *TaskManager) saveHistory() error {
	data, err := json.MarshalIndent(tm.executionHistory, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(tm.historyFilePath, data, 0644)
}

// loadHistory loads the execution history from a file.
func (tm *TaskManager) loadHistory() error {
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

// extractTaskID pulls the “id” var from mux and returns a proper error if it’s missing.
func extractTaskID(r *http.Request) (string, error) {
	id := mux.Vars(r)["id"]
	if id == "" {
		return "", fmt.Errorf("task ID is required")
	}
	return id, nil
}

// fetchTask loads a task by ID from the boltdb and returns it (or an error).
func (tm *TaskManager) fetchTask(id string) (*api.Task, error) {
	var task api.Task
	err := tm.persistence.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(tasksBucketName))
		if b == nil {
			return fmt.Errorf("tasks bucket not found")
		}
		data := b.Get([]byte(id))
		if data == nil {
			return fmt.Errorf("task '%s' not found", id)
		}
		return json.Unmarshal(data, &task)
	})
	if err != nil {
		return nil, err
	}
	return &task, nil
}
