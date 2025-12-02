package tasks

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"os"
	"runtime/debug"
	"sync"
	"time"

	json "github.com/goccy/go-json"

	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/persistence"
	"fusion/internal/pubsub"
	"fusion/internal/utils"

	"github.com/robfig/cron/v3"
)

const (
	HistoryPath = "history.json"
	MaxHistory  = 100
)

var ErrTaskNotFound = errors.New("task not found")

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
	hub              *pubsub.Hub
	running          bool
	taskFuncs        map[string]func()
	tasks            map[string]*api.Task
	actionFactories  map[api.TaskType]func(*api.Task) func()
}

// NewTaskManager initializes and returns a new TaskManager with persistence.
func NewTaskManager(config *api.AppConfig, persistence *persistence.Persistence, hub *pubsub.Hub) *TaskManager {
	tm := &TaskManager{
		cron: cron.New(
			cron.WithParser(
				cron.NewParser(
					cron.SecondOptional |
						cron.Descriptor |
						cron.Minute |
						cron.Hour |
						cron.Dom |
						cron.Month |
						cron.Dow,
				),
			),
		),
		executionHistory: make([]ExecutionRecord, 0),
		historyFilePath:  HistoryPath,
		node:             config.NodeName,
		persistence:      persistence,
		hub:              hub,
		taskFuncs:        make(map[string]func()),
		tasks:            make(map[string]*api.Task),
	}

	tm.actionFactories = map[api.TaskType]func(*api.Task) func(){
		api.TaskTypeSnapshot: func(t *api.Task) func() {
			return tm.wrapTask(t, tm.taskActivateSnapshotFunc(t))
		},
		api.TaskTypeMessage: func(t *api.Task) func() {
			return tm.wrapTask(t, tm.taskTriggerMessageFunc(t))
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
		return ErrTaskNotFound
	}

	tm.cron.Remove(task.CronEntryID)

	// Wrap the new taskFunc to track execution history
	wrappedTaskFunc := tm.wrapTask(task, taskFunc)

	entryID, err := tm.cron.AddFunc(task.CronExpr, wrappedTaskFunc)
	if err != nil {
		logger.Error("[TASKS] Failed to update task '%s': %v", task.ID, err)
		return err
	}
	task.Enabled = true
	task.CronEntryID = entryID
	tm.tasks[task.ID] = task
	tm.taskFuncs[task.ID] = wrappedTaskFunc

	logger.Debug("[TASKS] Update task '%s': %v", task.ID, task)

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

	tasks := make([]api.Task, 0, len(tm.tasks))
	for _, task := range tm.tasks {
		tasks = append(tasks, *task)
	}

	return tasks
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
func (tm *TaskManager) Start() {

	logger := logging.GetLogger()

	if tm.running {
		logger.Warn("[TASKS] TaskManager already running")
		return
	}

	if err := tm.LoadTasks(); err != nil {
		logger.Fatal("[TASKS] %v", err)
	}

	if err := tm.loadHistory(); err != nil {
		logger.Fatal("[TASKS] %v", err)
	}

	if err := tm.registerEnabledTasks(); err != nil {
		logger.Fatal("[TASKS] %v", err)
	}

	tm.cron.Start()

	tm.running = true

	logger.Info("[TASKS] TaskManager running")
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

	tasks := tm.ListTasks()

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(tasks)
}

// GetTaskHandler handles HTTP GET requests to get a single task
func (tm *TaskManager) GetTaskHandler(w http.ResponseWriter, r *http.Request) {

	if !utils.RequireGet(w, r) {
		return
	}

	id, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	task, err := tm.GetTask(id)
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

	task, err := tm.GetTask(id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}

	if task.Enabled {
		w.WriteHeader(http.StatusNoContent)
		return
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

	tm.mu.Lock()
	defer tm.mu.Unlock()
	tm.tasks[id] = task

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

	task, err := tm.GetTask(id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}

	tm.cron.Remove(task.CronEntryID)
	task.CronEntryID = 0
	task.Enabled = false

	tm.mu.Lock()
	defer tm.mu.Unlock()
	tm.tasks[id] = task

	tm.saveTasks()

	w.WriteHeader(http.StatusNoContent)
}

// wrapTask wraps a task function to track execution history and handle panics.
func (tm *TaskManager) wrapTask(task *api.Task, fn TaskFunc) func() {
	logger := logging.GetLogger()

	return func() {
		//now := time.Now()

		// // Enforce start window
		// if !task.StartAt.IsZero() && now.Before(task.StartAt) {
		// 	logger.Debug("[TASKS] Skipping task '%s': before start time %s", task.ID, task.StartAt)
		// 	return
		// }

		// // Enforce end window
		// if !task.EndAt.IsZero() && now.After(task.EndAt) {
		// 	logger.Debug("[TASKS] Skipping task '%s': after end time %s", task.ID, task.EndAt)
		// 	return
		// }

		// if !task.EndAt.IsZero() && now.After(task.EndAt) {
		// 	logger.Debug("[TASKS] Auto-disabling task '%s' after end time", task.ID)
		// 	task.Enabled = false
		// 	tm.cron.Remove(task.CronEntryID)
		// 	task.CronEntryID = 0

		// 	tm.mu.Lock()
		// 	tm.tasks[task.ID] = task
		// 	tm.mu.Unlock()

		// 	tm.saveTasks()
		// 	return
		// }

		defer func() {
			if r := recover(); r != nil {
				tm.RecordExecution(task, "failed")
				logger.Error("[TASKS] Task '%s' panic: %v\n%s", task.ID, r, debug.Stack())
			}
		}()

		ctx := context.Background()
		if err := fn(ctx); err != nil {
			tm.RecordExecution(task, "failed")
			logger.Error("[TASKS] Task '%s' error: %v", task.ID, err)
			return
		}

		tm.RecordExecution(task, "success")
	}
}

// saveTasks saves the current tasks
func (tm *TaskManager) saveTasks() error {
	return tm.persistence.SaveTasks(tm.tasks)
}

// LoadTasks loads tasks from the persistence file and schedules them.
func (tm *TaskManager) LoadTasks() error {
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

// GetTask loads a task by ID from the boltdb and returns it (or an error).
func (tm *TaskManager) GetTask(id string) (*api.Task, error) {
	tm.mu.Lock()
	defer tm.mu.Unlock()

	task, ok := tm.tasks[id]
	if !ok {
		return nil, ErrTaskNotFound
	}
	return task, nil
}

func (tm *TaskManager) makeTaskFunc(task *api.Task) (TaskFunc, error) {
	switch task.Type {

	case api.TaskTypeMessage:
		id := task.Params[api.MessageIDKey]
		if id == "" {
			return nil, fmt.Errorf("missing '%s'", api.MessageIDKey)
		}

		return tm.taskTriggerMessageFunc(task), nil

	case api.TaskTypeSnapshot:
		id := task.Params[api.SnapshotIDKey]
		if id == "" {
			return nil, fmt.Errorf("missing '%s'", api.SnapshotIDKey)
		}
		return tm.taskActivateSnapshotFunc(task), nil

	default:
		return nil, fmt.Errorf("unsupported task type %q", task.Type)
	}
}
