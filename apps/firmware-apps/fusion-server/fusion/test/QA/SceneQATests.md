These manual tests should allow you as a human to prove that snapshots, scenes, and scene-sets are working as expected.

I've created some basic unit tests, but I have a tendency to want to assert that a feature works correctly using my own eyes and brain. By using these `curl` commands, you can also do exactly that.

**Setup**

From the `fusion-server` directory:

```sh
# Build
./build-fusion-server

# Run
./scripts/multipass/launch --instances 3
```

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
curl -i -sS "$VIP/snapshots"
```

```bash
curl -i -sS "$VIP/scenes"
```

```bash
curl -i -sS "$VIP/scene-sets"
```

```bash
curl -i -sS "$VIP/scene-catalog"
```

**2) Activate snapshot and verify DB state patch**
```bash
curl -i -sS -X POST "$VIP/snapshots/activate/snapshot-test-01"
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
curl -i -sS -X POST "$VIP/snapshots/activate/snapshot-test-01"
```

```bash
curl -i -sS "$VIP/value?key=feature_probe"
```

**5) Negative-path checks**
```bash
curl -i -sS -X POST "$VIP/snapshots/activate/does-not-exist"
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

**6) Delete specific snapshot / scene / scene-set by ID**
```bash
curl -i -sS -X DELETE "$VIP/snapshots/snapshot-test-01"
```

```bash
curl -i -sS "$VIP/snapshots"
```

Expect `snapshot-test-01` to be removed from the `snapshots` array.

```bash
curl -i -sS -X DELETE "$VIP/scenes/scene-evening-01"
```

```bash
curl -i -sS "$VIP/scenes"
```

```bash
curl -i -sS -X POST "$VIP/scene-sets/current-scene" \
  -H "Content-Type: application/json" \
  -d '{
    "set_id": "scene-set-test-01"
  }'
```

Expect `scene-evening-01` to be removed from the `scenes` array. If it was current, `current_scene.scene_id` should be empty.

```bash
curl -i -sS -X DELETE "$VIP/scene-sets/scene-set-test-01"
```

```bash
curl -i -sS "$VIP/scene-sets"
```

Expect `scene-set-test-01` to be removed from the `scene_sets` array.

```bash
curl -i -sS -X DELETE "$VIP/snapshots/does-not-exist"
curl -i -sS -X DELETE "$VIP/scenes/does-not-exist"
curl -i -sS -X DELETE "$VIP/scene-sets/does-not-exist"
```

Expect `404` for each missing ID.

**7) Re-create definitions for delete-all checks**
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

**8) Delete all snapshot definitions**
```bash
curl -i -sS -X DELETE "$VIP/snapshots"
```

```bash
curl -i -sS "$VIP/snapshots"
```

Expect an empty `snapshots` array.

**9) Delete all scene-sets (also removes all scenes in those sets)**
```bash
curl -i -sS -X DELETE "$VIP/scene-sets"
```

```bash
curl -i -sS "$VIP/scene-sets"
```

```bash
curl -i -sS "$VIP/scenes"
```

Expect empty `scene_sets` and `scenes` arrays.

**10) Replication checks on each node**
```bash
curl -i -sS "$NODE1/snapshots"
curl -i -sS "$NODE2/snapshots"
curl -i -sS "$NODE3/snapshots"
```

```bash
curl -i -sS "$NODE1/scene-sets"
curl -i -sS "$NODE2/scene-sets"
curl -i -sS "$NODE3/scene-sets"
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

---

# Automated Integration Tests

```sh
FUSION_TEST_VIP=192.168.2.100:8080 FUSION_TEST_NODES=192.168.2.150:8080,192.168.2.151:8080,192.168.2.152:8080 go test -v ./test -run '^TestSceneCatalog' -count=1
```

