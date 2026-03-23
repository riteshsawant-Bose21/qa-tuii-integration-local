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
