# Fusion Time Machine System

> **Note:** The legacy `/snapshots` API has been renamed to `/time-machine`. The underlying behaviour is unchanged; only the endpoint paths and handler names have been updated.

The Fusion cluster includes a distributed time machine system that provides a
strongly consistent, restore-based mechanism for managing configuration and
state across all nodes. Time machine entries act as authoritative state images that can be
created, stored, activated, and synchronized across the cluster.

This document explains:
- What snapshots are
- How they are created, activated, and deleted
- How epoch-based versioning guarantees consistency
- How state updates interact with snapshots
- How REST APIs should be used
- How cluster nodes converge on state using gossip + versioning

---

## What Is a Snapshot?

A **snapshot** is a complete serialized copy of the system state on a node,
stored locally in BoltDB under the `snapshots` bucket.

A snapshot contains:

```json
{
  "version": { "epoch": 4, "counter": 2001, "node_id": "fusion_abc123" },
  "timestamp": "UTC",
  "checksum": "sha256...",
  "state": {
    "key1": { "data": ..., "version": ... },
    "key2": { "data": ..., "version": ... }
  }
}
```

Each node stores snapshots locally. Snapshot names are user-defined (e.g.
"default", "baseline", "release_2024").

---

## Snapshot Lifecycle

### 1. Create time machine entry

```
POST /time-machine/<name>
```

- Creates a time machine entry locally on the node.
- Broadcasts `NotifyOpSnapCreate(name)` to the cluster.
- Memberlist gossip eventually delivers the create event to all nodes.
- Each node creates the same entry locally.

Time machine creation is *eventually consistent*.

---

### 2. Activate time machine entry

```
POST /time-machine/activate/<name>
```

Time machine activation is **authoritative**.

Activation performs:

#### A. Load snapshot data from BoltDB  
#### B. Replace the in-memory state *exactly* with the snapshot contents  
(no merging; no overlay)

#### C. Increment the **epoch**

If old epoch = `N`, new epoch = `N + 1`.  
Lamport counter resets to 0.

The epoch boundary ensures:
- Old updates are rejected.
- MergeRemoteState cannot overwrite snapshot restore.
- Cluster converges on the new state.

#### D. Broadcast `NotifyOpSnapActivate(name)`  
All other nodes:
- Load the same snapshot
- Replace full in-memory state
- Bump epoch
- Converge on the same state

---

### 3. Delete time machine entry

```
DELETE /time-machine/<name>
```

- Deletes entry from local BoltDB
- Broadcasts `NotifyOpSnapDelete`
- All nodes delete the entry locally

The `"default"` entry cannot be deleted.

---

## Epoch System

Fusion uses an **epoch + Lamport counter** hybrid version system:

```go
type Version struct {
    Epoch   int64
    Counter int64
    NodeID  string
}
```

- **Epoch** defines global boundaries (snapshot activation).
- **Counter** provides causal ordering inside an epoch.
- **NodeID** helps break ties and trace origin.

### Epoch rules:
- Epoch always increases when a snapshot is activated.
- Updates with lower epoch are rejected as stale.
- Updates with higher epoch cause full state adoption.
- Updates with equal epoch follow Lamport ordering (`max + 1`).

This prevents stale gossip from corrupting restored snapshot state.

---

## State Updates: POST vs PATCH

Fusion intentionally separates **full-state replacement** from **partial updates**.

### POST /value — Replace Entire State

```
POST /value
{
  "foo": 111,
  "bar": 222
}
```

Semantics:
- Completely replace current state with provided map.
- Equivalent to a full configuration push.
- Used for:
  - Snapshot restore
  - Config imports
  - Full-state updates

### PATCH /value — Partial Update (Merge)

```
PATCH /value
{
  "foo": 999
}
```

Semantics:
- Modify only the provided keys.
- Merge into existing state.
- Server handles epoch + Lamport version assignment automatically.

Use `PATCH` when updating individual state keys.

---

## Querying State

### Full state:
```
GET /value
```

### Single key:
```
GET /value?key=foo
```

Returns:

```json
{ "exists": true, "value": 999 }
```

If not present:

```json
{ "exists": false }
```

---

## Gossip + Merge System

Fusion uses memberlist gossip for state propagation.

Rules:

### If `remoteEpoch < localEpoch`
Reject update.

### If `remoteEpoch > localEpoch`
Adopt remote state fully (`ReplaceFullState`)  
Adopt remote epoch.

### If epochs match
Merge keys using Lamport ordering (`max + 1`).

Snapshot activation uses this mechanism to ensure consistent cluster-wide restore.

---

## REST API Summary

### Time Machine Management
```
POST   /time-machine/<name>           (create)
GET    /time-machine                  (list)
POST   /time-machine/activate/<name>  (activate)
DELETE /time-machine/<name>           (delete)
```

### State Management
```
POST   /value      (FULL state replace)
PATCH  /value      (partial merge update)
GET    /value      (full map)
GET    /value?key=foo (single key lookup)
```

### Administrative
```
GET  /admin/data   (export)
POST /admin/data   (import)
```

---

## Scene Catalog API (Snapshot Definitions, Scenes, Scene Sets)

The **Scene Catalog** is a second, independent storage system layered on top of the existing Time Machine system. Where Time Machine entries are full-state restores with epoch semantics, Scene Catalog entries are **patch-style overlays**: activating a Snapshot Definition or Scene merges its stored `data` keys onto the current DB State rather than replacing it entirely.

This makes the Scene Catalog suitable for parameter-set recall (e.g. EQ presets, gain levels) without resetting unrelated state or bumping the epoch. This should avoid invalidating ongoing same-epoch updates during the patch.

---

### Key Concepts

**Snapshot Definition**  
A named blob of settings stored by ID. Activation patches `data` over DB State. Fire-and-forget — the ID is not tracked after activation.

**Scene**  
Like a Snapshot Definition but the current active Scene ID is tracked per Scene Set. Scenes are always nested inside a Scene Set.

**Scene Set**  
A named collection of Scenes. One scene in the set can be active at a time. The server maintains `current_scene_id` for each set independently.

---

### Creating / Updating Definitions

Snapshot Definitions and Scene Sets are written via the existing `/value` endpoint using the `snapshots` and `scene_sets` root keys. The write is a **clobber upsert** — if a definition with the same ID already exists, it is overwritten.

```sh
# Store snapshot definitions alongside other config (or alone via PATCH)
PATCH /value
{
  "snapshots": [
    {
      "id": "snap-morning-01",
      "name": "Morning Baseline",
      "data": { "channels.1.gain_db": -6.0 }
    }
  ],
  "scene_sets": [
    {
      "set_id": "set-dayparts-01",
      "name": "Channel 1 Dayparts",
      "default_scene": "scene-morning-01",
      "scenes": [
        {
          "id": "scene-morning-01",
          "name": "Morning",
          "data": { "channels.1.gain_db": -6.0 }
        },
        {
          "id": "scene-evening-01",
          "name": "Evening",
          "data": { "channels.1.gain_db": -12.0 }
        }
      ]
    }
  ]
}
```

`snapshots` and `scene_sets` keys are **extracted before** normal config processing. Any other root keys in the same payload continue through the standard state update path.

---

### REST API: Scene Catalog Endpoints (port 8080)

#### Activate a Snapshot Definition

```
POST /snapshots/activate
{ "id": "<snapshot-id>" }
```

- Loads the stored snapshot definition
- Merges `data` onto DB State via `Patch` semantics (no epoch bump)
- Broadcasts `snapshot_v2_activate` to the cluster
- Returns **204** on success, **400** if `id` is missing, **404** if not found

#### Activate a Scene (within a Scene Set)

```
POST /scene-sets/activate
{ "set_id": "<set-id>", "scene_id": "<scene-id>" }
```

- Validates that `scene_id` belongs to `set_id` (returns **409** if not)
- Merges scene `data` onto DB State
- Updates `current_scene_id` for that set in persistent storage
- Broadcasts `scene_activate` to the cluster
- Returns **204** on success, **400** if fields missing, **404** if set not found, **409** if scene not a member

#### Query Current Scene

```
POST /scene-sets/current-scene
{ "set_id": "<set-id>" }
```

Response:
```json
{
  "set_id": "set-dayparts-01",
  "current_scene": {
    "scene_id": "scene-morning-01",
    "name": "Morning"
  }
}
```

Returns **200** with empty `scene_id` / `name` if no scene has been activated yet for that set.  
Returns **404** if the set does not exist.

#### List Snapshot Definitions

```
GET /snapshots/list
```

Returns all stored snapshot definitions (full objects including `id`, `name`, `data`).

#### List All Scenes (flat)

```
GET /scenes/list
```

Returns all scenes across all scene sets as a flat list.

#### List Scene Sets

```
GET /scene-sets/list
```

Returns all stored scene sets (full objects including nested scenes and `current_scene_id`).

#### List Full Scene Catalog

```
GET /scene-catalog-list
```

Returns both snapshot definitions and scene sets in one response:
```json
{
  "snapshots": [ ... ],
  "scene_sets": [ ... ]
}
```

---

### Cluster Replication

Scene Catalog definitions and activations are propagated across cluster nodes using the gossip pipeline.

| Operation | Notify Op | What is replicated |
|---|---|---|
| Write snapshot defs | `snapshot_defs_upsert` | `[]SnapshotDefinition` persisted on all nodes |
| Write scene sets | `scene_sets_upsert` | `[]SceneSet` persisted on all nodes |
| Activate snapshot def | `snapshot_v2_activate` | Config state travels via existing `config_update` broadcast |
| Activate scene | `scene_activate` | Config state via `config_update`; `current_scene_id` updated on all nodes |

Definition writes check `message.Node == localNode` in the hub to avoid double-write on the originating node.

---

## Cluster Convergence Guarantees

Fusion guarantees:

- Snapshot activation produces a **globally consistent state**.
- Epoch boundaries ensure stale updates cannot overwrite restored state.
- State is eventually identical across all nodes.
- Memberlist gossip provides replica convergence with small delays.
- Snapshot create/delete are eventually consistent.
- Snapshot activation is effectively atomic across cluster.

---

## Test Coverage

The system is validated through tests for:

- Snapshot creation/activation/deletion
- Snapshot propagation across cluster
- Snapshot restore correctness (exact state restore)
- Epoch propagation and convergence
- Rejection of pre-epoch stale updates
- Acceptance of same-epoch updates
- Value propagation across nodes
- Nested/path-based key lookup behavior
- Snapshot import/export

Additional tests recommended:
- Node rejoin after snapshot activation
- Node offline during snapshot activation
- Racing snapshot activations
- Partition simulation

---

## Summary

Fusion’s snapshot system provides:

- Strong consistency through epoch boundaries
- Clean separation between full-state and partial updates
- Robust cluster convergence via memberlist and lamport clocks
- Reliable restore semantics through ReplaceFullState()
- REST endpoints aligned with expected behaviors (POST vs PATCH)
- An efficient, scalable model for distributing configuration and state

Snapshots act as **authoritative, immutable points in time**, and epoch increments guarantee safe restoration even under high cluster activity.
