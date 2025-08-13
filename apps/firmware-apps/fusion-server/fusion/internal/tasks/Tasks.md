# TaskManager

`TaskManager` manages and schedules tasks using cron expressions. 
It provides a flexible and persistent system for executing scheduled tasks, 
with features for task management, execution history, and HTTP endpoints for interaction.

## Features

- Add, update, remove, and list scheduled tasks.
- Persistent task storage and execution history.
- Configurable maximum history log size.
- HTTP endpoints for managing tasks and viewing execution history.
- Supports custom task functions and tracks their execution status.
- Handles panics in task execution gracefully.

## Usage

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

### Cron Expressions

`TaskManager` uses the [robfig/cron](https://github.com/robfig/cron) library for scheduling. 
Refer to its documentation for details on supported cron expressions.

```
*    *    *    *    *    *
|    |    |    |    |    |
|    |    |    |    |    +---- Year (optional, some systems)
|    |    |    |    +---- Day of the Week (0 - 6) (Sunday = 0 or 7)
|    |    |    +---- Month (1 - 12)
|    |    +---- Day of the Month (1 - 31)
|    +---- Hour (0 - 23)
+---- Minute (0 - 59)
```

## Common Cron Expressions

### Basic Time Intervals

- `@every 1h` → Run every **hour.**
- `@every 30s` → Run every **30 seconds.**
- `@every 10m` → Run every **10 minutes.**

### Scheduled Execution

- `0 * * * *`  → Run **every hour at minute 0** (e.g., 1:00, 2:00, etc.).
- `0 12 * * *` → Run **every day at 12:00 PM (noon).**
- `0 18 * * 5` → Run **very Friday at 6:00 PM.**
- `0 0 1 * *`  → Run at **midnight on the 1st day of every month.**

### Multiple Values & Ranges
- `0 9,17 * * *` → Run at **9 AM and 5 PM.**
- `0 9-17 * * *` → Run every hour from **9 AM to 5 PM.**
- `*/15 * * * *` → Run every **15 minutes.**

### Special Shorthand Expressions
- `@hourly` → `0 * * * *` (Run every hour)
- `@daily` or `@midnight` → `0 0 * * *` (Run every day at midnight)
- `@weekly` → `0 0 * * 0` (Run every Sunday at midnight)
- `@monthly` → `0 0 1 * *` (Run on the 1st of every month)
- `@yearly` or `@annually` → `0 0 1 1 *` (Run on January 1st at midnight)

### Persistence

- Task data is saved to the file specified during `TaskManager` initialization.
- Execution history is maintained in a separate file.


## HTTP Endpoints

| Endpoint                  | Method | Description              |
|---------------------------|--------|--------------------------|
| `/tasks`                  | GET    | List all tasks.          |
| `/tasks`                  | POST   | Add a new task.          |
| `/tasks/:id`              | GET    | Get task.          |
| `/tasks/:id`              | PUT    | Update an existing task. |
| `/tasks/:id`              | DELETE | Remove a task by ID.     |
| `/tasks/history`          | GET    | View execution history.  |
| `/tasks/history`          | DELETE | Clear execution history. |

### Example Requests

#### Add a Task
```bash
curl -X POST -H "Content-Type: application/json" \
    -d '{"id":"task1","cron_expr":"@hourly","description":"Sample task"}' \
    http://localhost:8080/tasks
```

#### Run every hour
```
curl -X PUT -H "Content-Type: application/json" \
     -d '{"cron_expr":"@hourly","description":"Runs every hour"}' \
     http://localhost:8080/tasks/task2
```

#### Run every day at 3:30 PM
```
curl -X PUT -H "Content-Type: application/json" \
     -d '{"cron_expr":"30 15 * * *","description":"Runs at 3:30 PM daily"}' \
     http://localhost:8080/tasks/task3
```

#### Run every Monday at 8 AM
```
curl -X PUT -H "Content-Type: application/json" \
     -d '{"cron_expr":"0 8 * * 1","description":"Runs every Monday at 8 AM"}' \
     http://localhost:8080/tasks/task4
```

#### Run every M-W-F at 12 PM
```
curl -X PUT -H "Content-Type: application/json" \
     -d '{"cron_expr":"0 12 * * 1,3,5","description":"Runs every Monday, Wednesday, and Friday at 12 PM"}' \
     http://localhost:8080/tasks/task5
```

#### Run every 10 minutes
```
curl -X PUT -H "Content-Type: application/json" \
     -d '{"cron_expr":"*/10 * * * *","description":"Runs every 10 minutes"}' \
     http://localhost:8080/tasks/task5
```

#### List Tasks
```bash
curl -X GET http://localhost:8080/tasks
```

#### Update a Task
```bash
curl -X PUT -H "Content-Type: application/json" \
    -d '{"cron_expr":"@every 30m","description":"Updated task"}' \
    http://localhost:8080/tasks/task1
```

#### Remove a Task
```bash
curl -X DELETE http://localhost:8080/tasks/task1
```

#### Get Execution History
```bash
curl -X GET http://localhost:8080/tasks/history
```

#### Clear Execution History
```bash
curl -X DELETE http://localhost:8080/tasks/history
```
