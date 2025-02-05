# TimerManager

`TimerManager` manages and schedules tasks using cron expressions. It provides a flexible and persistent system for executing scheduled tasks, with features for task management, execution history, and HTTP endpoints for interaction.

## Features

- Add, update, remove, and list scheduled tasks.
- Persistent task storage and execution history.
- Configurable maximum history log size.
- HTTP endpoints for managing tasks and viewing execution history.
- Supports custom task functions and tracks their execution status.
- Handles panics in task execution gracefully.

## Usage

### Initialize the TimerManager

```go
package main

import (
    "log"
    "timers"
)

func main() {
    tm := timers.NewTimerManager("tasks.json", "history.json")

    // Start the scheduler
    if err := tm.Start(); err != nil {
        log.Fatalf("Failed to start TimerManager: %v", err)
    }

    defer tm.Stop()

    // Example: Add a task
    err := tm.AddTask("task1", "@every 1h", "Sample task", func() {
        log.Println("Task executed")
    })
    if err != nil {
        log.Fatalf("Failed to add task: %v", err)
    }
}
```

### Task Management

#### Add a Task
```go
tm.AddTask("task1", "@every 1h", "Sample hourly task", func() {
    log.Println("Task executed")
})
```

#### Update a Task
```go
tm.UpdateTask("task1", "@every 30m", "Updated task description", func() {
    log.Println("Updated task executed")
})
```

#### Remove a Task
```go
tm.RemoveTask("task1")
```

#### List Tasks
```go
tasks := tm.ListTasks()
for _, task := range tasks {
    log.Printf("Task ID: %s, Cron: %s, Description: %s", task.ID, task.CronExpr, task.Description)
}
```

### Execution History

Retrieve the execution history:
```go
history := tm.GetExecutionHistory()
for _, record := range history {
    log.Printf("Task ID: %s, Status: %s, Timestamp: %v", record.TaskID, record.Status, record.Timestamp)
}
```

### HTTP Handlers

Expose task management and history functionality via HTTP:

```go
http.HandleFunc("/tasks", tm.ListTasksHandler)
http.HandleFunc("/tasks/add", tm.AddTaskHandler)
http.HandleFunc("/tasks/update", tm.UpdateTaskHandler)
http.HandleFunc("/tasks/remove", tm.RemoveTaskHandler)
http.HandleFunc("/tasks/history", tm.ExecutionHistoryHandler)

log.Fatal(http.ListenAndServe(":8080", nil))
```

### Cron Expressions

`TimerManager` uses the [robfig/cron](https://github.com/robfig/cron) library for scheduling. Refer to its documentation for details on supported cron expressions.

### Persistence

- Task data is saved to the file specified during `TimerManager` initialization.
- Execution history is maintained in a separate file.

### Logging

This package integrates with the `logging` module from the `fusion` project for structured logging. Replace `logging.GetLogger()` with your preferred logging mechanism if needed.

## HTTP Endpoints

| Endpoint              | Method | Description              |
|-----------------------|--------|--------------------------|
| `/tasks`              | GET    | List all tasks.          |
| `/tasks/add`          | POST   | Add a new task.          |
| `/tasks/update?id=<id>` | PUT    | Update an existing task. |
| `/tasks/remove?id=<id>` | DELETE | Remove a task by ID.     |
| `/tasks/history`      | GET    | View execution history.  |

### Example Requests

#### Add a Task
```bash
curl -X POST -H "Content-Type: application/json" \
    -d '{"id":"task1","cron_expr":"@hourly","description":"Sample task"}' \
    http://localhost:8080/tasks/add
```

#### List Tasks
```bash
curl -X GET http://localhost:8080/tasks
```

#### Update a Task
```bash
curl -X PUT -H "Content-Type: application/json" \
    -d '{"cron_expr":"@every 30m","description":"Updated task"}' \
    http://localhost:8080/tasks/update?id=task1
```

#### Remove a Task
```bash
curl -X DELETE http://localhost:8080/tasks/remove?id=task1
```

#### Get Execution History
```bash
curl -X GET http://localhost:8080/tasks/history
```
