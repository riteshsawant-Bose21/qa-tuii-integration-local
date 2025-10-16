package tasks

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"runtime/debug"
	"sync"
	"time"

	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/persistence"
	"fusion/internal/utils"

	"github.com/robfig/cron/v3"
)

const (
	HistoryPath = "history.json"
	MaxHistory  = 100
)

// ExecutionRecord represents a log entry for a task execution.
type ExecutionRecord struct {
	Description string    `json:"description"`
	Status      string    `json:"status"`
	TaskID      string    `json:"task_id"`
	Timestamp   time.Time `json:"timestamp"`
}

// TaskFunc is a task function that take a context
type TaskFunc func(context.Context) error

// TaskManager manages tasks and provides execution history with rotation.
type TaskManager struct {
	cron             *cron.Cron
	executionHistory []ExecutionRecord
	historyFilePath  string
	mu               sync.Mutex
	node             string
	persistence      *persistence.Persistence
	running          bool
	taskFuncs        map[string]func()
	tasks            map[string]*api.Task
	actionFactories  map[api.TaskType]func(*api.Task) func()
}

// NewTaskManager initializes and returns a new TaskManager with persistence.
func NewTaskManager(config *api.AppConfig, persistence *persistence.Persistence) *TaskManager {
	tm := &TaskManager{
		cron:             cron.New(),
		executionHistory: make([]ExecutionRecord, 0),
		historyFilePath:  HistoryPath,
		node:             config.NodeName,
		persistence:      persistence,
		taskFuncs:        make(map[string]func()),
		tasks:            make(map[string]*api.Task),
	}

	tm.actionFactories = map[api.TaskType]func(*api.Task) func(){
		api.TaskTypeSnapshot: func(t *api.Task) func() {
			snapID := t.Params[api.SnapshotIDKey]
			return tm.wrapTask(t, tm.taskActivateSnapshotFunc(snapID))
		},
		api.TaskTypeAudioPlayback: func(t *api.Task) func() {
			path := t.Params[api.MessageIDKey]
			return tm.wrapTask(t, tm.taskPlayAudioFunc(t, path))
		},
	}
	return tm
}

func (tm *TaskManager) AddTask(t *api.Task) error {
	tm.mu.Lock()
	defer tm.mu.Unlock()

	if _, ok := tm.tasks[t.ID]; ok {
		return fmt.Errorf("task %q exists", t.ID)
	}

	factory, ok := tm.actionFactories[t.Type]
	if !ok {
		return fmt.Errorf("unknown task type %q", t.Type)
	}

	// Build the closure
	tracked := factory(t)
	entryID, err := tm.cron.AddFunc(t.CronExpr, tracked)
	if err != nil {
		return err
	}
	t.CronEntryID = entryID
	tm.tasks[t.ID] = t
	return tm.saveTasks()
}

// UpdateTask updates an existing timer task.
func (tm *TaskManager) UpdateTask(task *api.Task, taskFunc TaskFunc) error {
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

func (tm *TaskManager) UpdateTaskFromCluster(task *api.Task) error {
	taskFunc, err := tm.makeTaskFunc(task)
	if err != nil {
		return fmt.Errorf("unable to generate task func: %w", err)
	}
	return tm.UpdateTask(task, taskFunc)
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
		Description: task.Description,
		Status:      status,
		TaskID:      task.ID,
		Timestamp:   time.Now(),
	}

	tm.executionHistory = append(tm.executionHistory, record)
	if len(tm.executionHistory) > MaxHistory {
		tm.executionHistory = tm.executionHistory[len(tm.executionHistory)-MaxHistory:]
	}

	err := tm.saveHistory()
	if err != nil {
		logging.GetLogger().Error("Error saving history: %v", err)
	}
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

	if err := tm.registerEnabledTasks(); err != nil {
		return err
	}

	tm.cron.Start()

	tm.running = true

	return nil
}

// Stop stops the TaskManager's scheduler.
func (tm *TaskManager) Stop() {

	tm.cron.Stop()
	tm.running = false
}

// GetTasks handles HTTP GET requests to list all tasks.
func (tm *TaskManager) GetTasks(w http.ResponseWriter, r *http.Request) {

	if !utils.RequireGet(w, r) {
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

// GetTask handles HTTP GET requests to get a single task
func (tm *TaskManager) GetTask(w http.ResponseWriter, r *http.Request) {

	if !utils.RequireGet(w, r) {
		return
	}

	id, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	task, err := tm.getTask(id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(task)
}

// DeleteTask handles HTTP DELETE requests to remove a task by ID.
func (tm *TaskManager) DeleteTask(w http.ResponseWriter, r *http.Request) {

	if !utils.RequireDelete(w, r) {
		return
	}

	id, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	err = tm.RemoveTask(id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// GetHistory handles HTTP GET requests to retrieve the execution history.
func (tm *TaskManager) GetHistory(w http.ResponseWriter, r *http.Request) {

	if !utils.RequireGet(w, r) {
		return
	}

	tm.mu.Lock()
	history := tm.executionHistory
	tm.mu.Unlock()

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(history)
}

// ClearHistory handles HTTP DELETE requests to clear the execution history.
func (tm *TaskManager) ClearHistory(w http.ResponseWriter, r *http.Request) {

	if !utils.RequireDelete(w, r) {
		return
	}

	tm.mu.Lock()
	tm.executionHistory = make([]ExecutionRecord, 0)
	tm.mu.Unlock()

	w.WriteHeader(http.StatusNoContent)
}

// EnableTask handles HTTP POST requests to enable a task
func (tm *TaskManager) EnableTask(w http.ResponseWriter, r *http.Request) {

	if !utils.RequirePost(w, r) {
		return
	}

	id, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	task, err := tm.getTask(id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}

	if task.CronEntryID != 0 {
		tm.cron.Remove(task.CronEntryID)
	}

	f, err := tm.makeTaskFunc(task)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	entryID, err := tm.cron.AddFunc(task.CronExpr, tm.wrapTask(task, f))
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	task.Enabled = true
	task.CronEntryID = entryID

	tm.saveTasks()

	w.WriteHeader(http.StatusNoContent)
}

// DisableTask handles HTTP POST requests to disable a task
func (tm *TaskManager) DisableTask(w http.ResponseWriter, r *http.Request) {

	if !utils.RequirePost(w, r) {
		return
	}

	id, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	task, err := tm.getTask(id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}

	tm.cron.Remove(task.CronEntryID)
	task.CronEntryID = 0
	task.Enabled = false

	tm.saveTasks()

	w.WriteHeader(http.StatusNoContent)
}

// wrapTask wraps a task function to track execution history and handle panics.
func (tm *TaskManager) wrapTask(task *api.Task, fn TaskFunc) func() {

	logger := logging.GetLogger()

	return func() {
		defer func() {
			if r := recover(); r != nil {
				tm.RecordExecution(task, "failed")
				logger.Error("Task '%s' panic: %v\n%s", task.ID, r, debug.Stack())
			}
		}()
		ctx := context.Background()
		if err := fn(ctx); err != nil {
			tm.RecordExecution(task, "failed")
			logger.Error("Task '%s' error: %v", task.ID, err)
			return
		}
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

// registerEnabledTasks registers enabled tasks
func (tm *TaskManager) registerEnabledTasks() error {
	for _, t := range tm.tasks {
		if !t.Enabled {
			continue
		}
		f, err := tm.makeTaskFunc(t)
		if err != nil {
			return fmt.Errorf("task %s: %w", t.ID, err)
		}
		entryID, err := tm.cron.AddFunc(t.CronExpr, tm.wrapTask(t, f))
		if err != nil {
			return fmt.Errorf("task %s: %w", t.ID, err)
		}
		t.CronEntryID = entryID
	}

	return nil
}

// fetchTask loads a task by ID from the boltdb and returns it (or an error).
func (tm *TaskManager) getTask(id string) (*api.Task, error) {

	task, err := tm.persistence.GetTask(id)
	if err != nil {
		return nil, err
	}
	return task, nil
}

func (tm *TaskManager) makeTaskFunc(task *api.Task) (TaskFunc, error) {
	switch task.Type {

	case api.TaskTypeSnapshot:
		id := task.Params[api.SnapshotIDKey]
		if id == "" {
			return nil, fmt.Errorf("missing '%s'", api.SnapshotIDKey)
		}
		return tm.taskActivateSnapshotFunc(id), nil

	case api.TaskTypeAudioPlayback:
		id := task.Params[api.MessageIDKey]
		if id == "" {
			return nil, fmt.Errorf("missing '%s'", api.MessageIDKey)
		}
		return tm.taskPlayAudioFunc(task, id), nil

	default:
		return nil, fmt.Errorf("unsupported task type %q", task.Type)
	}
}
