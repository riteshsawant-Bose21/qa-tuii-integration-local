# TaskManager  
A deterministic, window-aware cron scheduler for Fusion Server

The **TaskManager** is the scheduling engine responsible for running timed tasks inside the Fusion Server.  
It manages creation, persistence, execution, enabling/disabling, and lifecycle rules for scheduled tasks.  
It supports cron expressions, optional time-window constraints (`StartAt` and `EndAt`), snapshot activation tasks, and audio message playback tasks.

---

## Features

- Cron-based scheduling using **robfig/cron/v3** (standard **5-field** cron syntax)
- Optional **StartAt** timestamp — delays scheduling until the window opens
- Optional **EndAt** timestamp — automatically disables the task once expired
- Periodic window-evaluation loop to attach/detach cron entries appropriately
- Automatic removal of expired tasks
- Persistent task storage and execution history
- Panic-safe execution wrapper
- HTTP API for CRUD, enable/disable, and task-type-specific operations
- Supports:
  - **Snapshot tasks** (activates stored snapshots)
  - **Message tasks** (trigger audio playback)
- Works correctly in distributed cluster deployments

---

# Cron Expression Support

The TaskManager supports **standard robfig/cron/v3 5-field cron syntax**:

```
MINUTE HOUR DOM MONTH DOW
```

Examples:

```
* * * * *        # every minute
*/5 * * * *      # every 5 minutes
0 8 * * 1        # every Monday at 08:00
15 10 * * *      # every day at 10:15
```

Seconds-precision cron (`*/1 * * * * *`) is **not supported**.

---

# StartAt and EndAt Semantics

Each task may optionally define **StartAt** and **EndAt** timestamps.  
These modify *when* the cron job is allowed to run.

## StartAt Behavior

- If **StartAt is unset** (`time.Time{}`):
  - Task is scheduled immediately.

- If **StartAt is in the future**:
  - Task is enabled but **not scheduled**
  - `CronEntryID = 0`
  - Task does not run
  - Once the server time passes StartAt:
    - The window manager attaches the cron entry
    - Task then follows its cron schedule

## EndAt Behavior

- If **EndAt is unset**:
  - Task never auto-disables.

- If **EndAt is set**:
  - Task runs normally until EndAt
  - After EndAt passes:
    - Task is automatically disabled
    - Cron entry is removed
    - Task will not run again unless explicitly re-enabled

## Combined Window Behavior

| StartAt | EndAt | Before StartAt | Between Window | After EndAt |
|---------|--------|----------------|----------------|--------------|
| unset | unset | scheduled | scheduled | scheduled forever |
| future | unset | not scheduled | scheduled | scheduled forever |
| unset | future | scheduled | scheduled | auto-disabled |
| future | future | not scheduled | scheduled | auto-disabled |

---

# Internal Architecture

The TaskManager consists of three cooperating systems:

## 1. Cron Scheduler (robfig/cron)

- Schedules task execution based on cron expressions  
- Does not consider StartAt/EndAt; time windows are enforced externally  

## 2. Window Manager

A background goroutine periodically evaluates all tasks:

- Attaches cron entries when StartAt becomes valid
- Removes cron entries after EndAt passes
- Ensures correct scheduling even after server restarts

## 3. Execution Wrapper (`wrapTask`)

Every cron execution passes through a wrapper that:

- Rejects task execution before StartAt
- Disables task when EndAt has passed
- Logs execution history
- Recovers from panics
- Ensures failures do not stop the scheduler

---

# Task Lifecycle

### Creation
- Task is validated and persisted.
- If StartAt <= now → cron entry is created immediately.
- If StartAt > now → cron entry deferred until window opens.

### Execution
- Cron fires according to schedule.
- Execution is gated by wrapTask to enforce the time window.

### Update
- Old cron entry removed.
- New cron entry attached if inside valid window.
- StartAt/EndAt changes immediately affect scheduling.

### Disable
- Cron entry removed.
- Task.Enabled = false (persisted).

### Enable
- Task.Enabled = true
- Cron entry attached if inside window.

---

# Persistence

The TaskManager stores:

- Task definitions  
- Enabled/disabled state  
- StartAt / EndAt  
- CronExpr  
- Task type and parameters  
- Execution history (rotated log)

CronEntryID is **never persisted**; it is restored automatically on startup.

---

# HTTP API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/tasks` | List all tasks |
| POST | `/tasks` | Create a new task |
| GET | `/tasks/:id` | Retrieve a task |
| PATCH | `/tasks/:id` | Update a task |
| DELETE | `/tasks/:id` | Delete a task |
| POST | `/tasks/:id/enable` | Enable a task |
| POST | `/tasks/:id/disable` | Disable a task |
| GET | `/tasks/history` | Retrieve execution history |

Snapshot and message tasks have additional type-specific endpoints.

---

# Task Types

## Snapshot Task

Triggers a snapshot activation:

```
type: "snapshot"
params: {
    "snapshot_id": "<id>"
}
```

Snapshot ID **must exist** for the task to be scheduled.

## Message Task

Triggers audio message playback:

```
type: "message"
params: {
    "message": "<audio id>",
    "priority": 50,
    "zones": "all"
}
```

Used internally by the audio subsystem to coordinate timed message playback.

---

# Execution History

The TaskManager records:

- Task ID  
- Status: `"success"` or `"failed"`  
- Timestamp  
- Description  

History is persisted and rotated at `MaxHistory`.

---

# Limitations

- Cron granularity is limited to **minutes**
- StartAt/EndAt window enforcement depends on periodic evaluation
- Snapshot tasks cannot be scheduled if the snapshot does not exist
- All nodes must have synchronized clocks (chrony or ntpd recommended)

---

# Operational Notes

These design considerations remain important for production:

### Node Time Synchronization

Because scheduling is time-based, nodes must maintain tight clock sync (chrony/ntpd).  
This is especially important for distributed audio or scheduled snapshot activations.

### Missed-Windows Behavior (“Catch-Up”)

Currently, if a node is offline during a window:

- It does **not** replay missed events  
- This is intentional: Fusion operates under an “autonomous real-time node” model

A future enhancement could make this configurable per-task.

### Node Selector Rules (Future Feature)

It may be useful to allow tasks to target only certain node roles:

```
role=player
site=lobby
```

This is not yet implemented.

---

# Conclusion

The TaskManager is a full-featured, window-aware scheduling subsystem that reliably executes, persists, and controls tasks in a distributed audio environment. Its behavior is governed by cron expressions plus optional time windows, ensuring predictable and safe operation across restarts and cluster events.
