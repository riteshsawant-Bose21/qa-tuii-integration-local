These manual tests should allow you as a human to prove that snapshots, scenes, and scene-sets are working as expected.

I've created some basic unit tests, but I have a tendency to want to assert that a feature works correctly using my own eyes and brain. By using these `curl` commands, you can also do exactly that.

It's also helpful if you find the automated tests failing - there seems to be a lot of tenatiousness with automated testing when it spans IPC. By following these steps here, you can verify for yourself if the test run is glitching, the test might be broken, or if you broke something when you added a feature.

**Setup**
Set up the node IPs to match what you've go running on Multipass.
(I find a fresh Multipass deployment works best).

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

**1) Create snapshot + scene-set definitions via `/value`**
```bash
curl -i -sS -X PATCH "$VIP/value" \
  -H "Content-Type: application/json" \
  -d '{
    "snapshots": [
      {
        "id": "snapshot-test-01",
        "name": "Snapshot Test",
        "data": {
          "feature_probe": {
            "mode": "snapshot",
            "level": 10
          }
        }
      }
    ],
    "scene_sets": [
      {
        "set_id": "scene-set-test-01",
        "name": "Dayparts",
        "default_scene": "scene-morning-01",
        "scenes": [
          {
            "id": "scene-morning-01",
            "name": "Morning",
            "data": {
              "feature_probe": {
                "mode": "morning",
                "level": 1
              }
            }
          },
          {
            "id": "scene-evening-01",
            "name": "Evening",
            "data": {
              "feature_probe": {
                "mode": "evening",
                "level": 9
              }
            }
          }
        ]
      }
    ]
  }'
```

```bash
curl -i -sS "$VIP/snapshots/list"
```

```bash
curl -i -sS "$VIP/scenes/list"
```

```bash
curl -i -sS "$VIP/scene-sets/list"
```

```bash
curl -i -sS "$VIP/scene-catalog-list"
```

**2) Activate snapshot and verify DB state patch**
```bash
curl -i -sS -X POST "$VIP/snapshots/activate" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "snapshot-test-01"
  }'
```

```bash
curl -i -sS "$VIP/value?key=feature_probe"
```

**3) Activate scene and verify current scene tracking**
```bash
curl -i -sS -X POST "$VIP/scene-sets/activate" \
  -H "Content-Type: application/json" \
  -d '{
    "set_id": "scene-set-test-01",
    "scene_id": "scene-evening-01"
  }'
```

```bash
curl -i -sS "$VIP/value?key=feature_probe"
```

```bash
curl -i -sS -X POST "$VIP/scene-sets/current-scene" \
  -H "Content-Type: application/json" \
  -d '{
    "set_id": "scene-set-test-01"
  }'
```

**4) Verify clobber overwrite by reusing same snapshot ID**
```bash
curl -i -sS -X PATCH "$VIP/value" \
  -H "Content-Type: application/json" \
  -d '{
    "snapshots": [
      {
        "id": "snapshot-test-01",
        "name": "Snapshot Test v2",
        "data": {
          "feature_probe": {
            "mode": "snapshot-v2",
            "level": 99
          }
        }
      }
    ]
  }'
```

```bash
curl -i -sS -X POST "$VIP/snapshots/activate" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "snapshot-test-01"
  }'
```

```bash
curl -i -sS "$VIP/value?key=feature_probe"
```

**5) Negative-path checks**
```bash
curl -i -sS -X POST "$VIP/snapshots/activate" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "does-not-exist"
  }'
```

```bash
curl -i -sS -X POST "$VIP/scene-sets/activate" \
  -H "Content-Type: application/json" \
  -d '{
    "set_id": "scene-set-test-01",
    "scene_id": "not-in-set"
  }'
```

```bash
curl -i -sS -X POST "$VIP/scene-sets/activate" \
  -H "Content-Type: application/json" \
  -d '{
    "set_id": "missing-set",
    "scene_id": "scene-morning-01"
  }'
```

**6) Replication checks on each node**
```bash
curl -i -sS "$NODE1/snapshots/list"
curl -i -sS "$NODE2/snapshots/list"
curl -i -sS "$NODE3/snapshots/list"
```

```bash
curl -i -sS "$NODE1/scene-sets/list"
curl -i -sS "$NODE2/scene-sets/list"
curl -i -sS "$NODE3/scene-sets/list"
```

```bash
curl -i -sS -X POST "$NODE1/scene-sets/current-scene" \
  -H "Content-Type: application/json" \
  -d '{"set_id":"scene-set-test-01"}'

curl -i -sS -X POST "$NODE2/scene-sets/current-scene" \
  -H "Content-Type: application/json" \
  -d '{"set_id":"scene-set-test-01"}'

curl -i -sS -X POST "$NODE3/scene-sets/current-scene" \
  -H "Content-Type: application/json" \
  -d '{"set_id":"scene-set-test-01"}'
```
