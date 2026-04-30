These manual tests let you verify the new scheduler support for Scene Catalog activation (`scene_snapshot` and `scene_activate`) using `curl`.

This is intended for human verification when you want to confirm behavior directly on live nodes.

## Setup

From the `fusion-server` directory:

```sh
# Build
./build-fusion-server

# Run
./scripts/multipass/launch --instances 3
```

Always use default **fusion** instance name.
Delete and re-deploy if asked.

Set up node IPs to match your Multipass/cluster environment.

```bash
VIP="http://192.168.2.100:8080"
NODE1="http://192.168.2.84:8080"
NODE2="http://192.168.2.85:8080"
NODE3="http://192.168.2.86:8080"
```

```bash
curl -i -sS "$VIP/health"
```

```bash
curl -i -sS "$VIP/cluster/members"
```

## 1) Seed snapshot definitions + scene set data

```bash
curl -i -sS -X PATCH "$VIP/value" \
  -H "Content-Type: application/json" \
  -d '{
    "snapshots": [
      {
        "id": "sched-snapshot-01",
        "name": "Scheduled Snapshot",
        "data": {
          "feature_probe": {
            "mode": "scheduled-snapshot",
            "level": 101
          }
        }
      }
    ],
    "scene_sets": [
      {
        "set_id": "sched-scene-set-01",
        "name": "Scheduler Scene Set",
        "default_scene": "sched-scene-day-01",
        "scenes": [
          {
            "id": "sched-scene-day-01",
            "name": "Day",
            "data": {
              "feature_probe": {
                "mode": "scheduled-day",
                "level": 201
              }
            }
          },
          {
            "id": "sched-scene-night-01",
            "name": "Night",
            "data": {
              "feature_probe": {
                "mode": "scheduled-night",
                "level": 202
              }
            }
          }
        ]
      }
    ]
  }'
```

```bash
curl -i -sS "$VIP/scene-catalog-list"
```

## 2) Create a scheduled Scene Snapshot activation task

```bash
curl -i -sS -X POST "$VIP/tasks" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "qa-scene-snapshot-task",
    "description": "Run scene snapshot every 10s",
    "type": "scene_snapshot",
    "cron_expr": "@every 10s",
    "params": {
      "snapshot_definition_id": "sched-snapshot-01"
    }
  }'
```

```bash
curl -i -sS "$VIP/tasks/qa-scene-snapshot-task"
```

Wait ~10-15 seconds, then verify task history and patched value:

```bash
curl -i -sS "$VIP/tasks/history"
```

```bash
curl -i -sS "$VIP/value?key=feature_probe"
```

Expected: `feature_probe.mode` becomes `scheduled-snapshot`.

## 3) Create a scheduled Scene activation task (explicit set + scene)

```bash
curl -i -sS -X POST "$VIP/tasks" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "qa-scene-activate-task",
    "description": "Run scene activation every 12s",
    "type": "scene_activate",
    "cron_expr": "@every 12s",
    "params": {
      "set_id": "sched-scene-set-01",
      "scene_id": "sched-scene-night-01"
    }
  }'
```

```bash
curl -i -sS "$VIP/tasks/qa-scene-activate-task"
```

Wait ~12-20 seconds, then verify scene and value state:

```bash
curl -i -sS -X POST "$VIP/scene-sets/current-scene" \
  -H "Content-Type: application/json" \
  -d '{"set_id":"sched-scene-set-01"}'
```

```bash
curl -i -sS "$VIP/value?key=feature_probe"
```

Expected: current scene is `sched-scene-night-01` and `feature_probe.mode` becomes `scheduled-night`.

## 4) Disable and re-enable schedules

Disable:

```bash
curl -i -sS -X POST "$VIP/tasks/qa-scene-snapshot-task/disable"
curl -i -sS -X POST "$VIP/tasks/qa-scene-activate-task/disable"
```

Verify disabled:

```bash
curl -i -sS "$VIP/tasks/qa-scene-snapshot-task"
curl -i -sS "$VIP/tasks/qa-scene-activate-task"
```

Re-enable:

```bash
curl -i -sS -X POST "$VIP/tasks/qa-scene-snapshot-task/enable"
curl -i -sS -X POST "$VIP/tasks/qa-scene-activate-task/enable"
```

Verify enabled:

```bash
curl -i -sS "$VIP/tasks/qa-scene-snapshot-task"
curl -i -sS "$VIP/tasks/qa-scene-activate-task"
```

## 5) Patch an existing scheduled scene activation task

Switch scene to day profile:

```bash
curl -i -sS -X PATCH "$VIP/tasks/qa-scene-activate-task" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Run day scene every 12s",
    "params": {
      "set_id": "sched-scene-set-01",
      "scene_id": "sched-scene-day-01"
    }
  }'
```

Wait ~12-20 seconds and verify:

```bash
curl -i -sS -X POST "$VIP/scene-sets/current-scene" \
  -H "Content-Type: application/json" \
  -d '{"set_id":"sched-scene-set-01"}'
```

```bash
curl -i -sS "$VIP/value?key=feature_probe"
```

Expected: current scene is `sched-scene-day-01` and `feature_probe.mode` becomes `scheduled-day`.

## 6) Negative path checks

### A) Missing required field for `scene_snapshot` (`snapshot_definition_id`) -> 400

```bash
curl -i -sS -X POST "$VIP/tasks" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "qa-invalid-scene-snapshot-missing-id",
    "description": "invalid",
    "type": "scene_snapshot",
    "cron_expr": "@every 30s",
    "params": {}
  }'
```

### B) Missing required field for `scene_activate` (`set_id`) -> 400

```bash
curl -i -sS -X POST "$VIP/tasks" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "qa-invalid-scene-activate-missing-set",
    "description": "invalid",
    "type": "scene_activate",
    "cron_expr": "@every 30s",
    "params": {
      "scene_id": "sched-scene-night-01"
    }
  }'
```

### C) Unknown scene set for `scene_activate` -> 404

```bash
curl -i -sS -X POST "$VIP/tasks" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "qa-invalid-scene-activate-set-not-found",
    "description": "invalid",
    "type": "scene_activate",
    "cron_expr": "@every 30s",
    "params": {
      "set_id": "missing-set",
      "scene_id": "sched-scene-night-01"
    }
  }'
```

### D) Scene not member of set -> 409

```bash
curl -i -sS -X POST "$VIP/tasks" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "qa-invalid-scene-activate-not-member",
    "description": "invalid",
    "type": "scene_activate",
    "cron_expr": "@every 30s",
    "params": {
      "set_id": "sched-scene-set-01",
      "scene_id": "not-in-set"
    }
  }'
```

## 7) Task list and history checks

```bash
curl -i -sS "$VIP/tasks"
```

```bash
curl -i -sS "$VIP/tasks/history"
```

Optional per-node visibility check:

```bash
curl -i -sS "$NODE1/tasks"
curl -i -sS "$NODE2/tasks"
curl -i -sS "$NODE3/tasks"
```

## 8) Cleanup

```bash
curl -i -sS -X DELETE "$VIP/tasks/qa-scene-snapshot-task"
curl -i -sS -X DELETE "$VIP/tasks/qa-scene-activate-task"
```

```bash
curl -i -sS -X DELETE "$VIP/tasks/history"
```

```bash
curl -i -sS "$VIP/tasks"
```