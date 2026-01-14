# Fusion Persistence & State Management
### A Consistent, Snapshot-Based, Cluster-Replicated State Architecture

This document describes the architecture and behavior of Fusion’s persistence subsystem and its in-memory state manager. Together, these modules provide strong consistency guarantees, snapshot management, metadata tracking, audio-file synchronization, and distributed convergence across the cluster.

# Overview of Components

## Persistence Layer
The Persistence layer provides durable storage using BoltDB, managing:

- Active state
- Snapshots
- Tasks
- Audio metadata
- Device metadata
- Database hashing
- Export/import of full DB content

It is storage-only. All semantic rules are defined by the StateManager.

## StateManager
The StateManager owns the runtime configuration and implements:

- Versioning with Lamport clocks and epochs  
- Patch application  
- Authoritative config update replication  
- Stale update rejection  
- Cluster consistency checks  
- Automatic data healing  
- Full-state checksum calculation

Persistence stores data permanently; the StateManager ensures correctness across nodes.

# Bucket Architecture

Persistence initializes the following BoltDB buckets:

| Bucket | Purpose |
|--------|---------|
| `active` | Last runtime-saved state for reboot recovery |
| `snapshots` | User-created complete state dumps |
| `fusion` | Metadata, including active snapshot and DB hash |
| `tasks` | All task definitions |
| `audio` | Audio metadata (files stored separately) |
| `device` | Device identity and configuration |

A fresh DB is initialized with:

- Default snapshot  
- Metadata  
- Initial active state  

# Active State & Snapshots

## Active State
The `active/state` record is the authoritative runtime state and is written using a debounce worker to reduce I/O churn.

On startup:

1. If `active/state` exists → restore it exactly (including version).  
2. Else → activate the active snapshot, then persist it.  

This ensures deterministic restarts and avoids snapshot lookups on every boot.

## Snapshots
A snapshot is a full-state capture containing:

```json
{
  "version": { "epoch": 4, "counter": 2001, "node_id": "fusion_x" },
  "timestamp": "...",
  "checksum": "...",
  "state": { ... }
}
```

### Snapshot Activation
Activating a snapshot:

1. **Bumps the epoch** (global causal boundary).  
2. **Overwrites the entire state**, deep-copying snapshot contents.  
3. **Sets every entry’s version** to the new epoch.  
4. Updates the active-snapshot metadata.  
5. Schedules a save of the active state.  

Epoch resets ensure that no stale updates can propagate across the cluster.

# Versioning Model

Each top-level state entry has a Lamport-style version:

```
Version { Epoch, Counter, NodeID }
```

Ordering:

1. Epoch  
2. Counter  
3. NodeID (tie-breaker)

### Two Types of Updates

#### Local Patch Updates (HTTP PATCH)
- Deep-merge only the changed fields  
- Compute a new authoritative snapshot for that key  
- Broadcast resulting `ConfigUpdate`  

#### Incoming ConfigUpdate (Cluster Replication)
- Overwrites the entire top-level key  
- Not a deep-merge  
- Ensures deletions are preserved  
- Uses Lamport ordering to reject stale updates  

### Stale Update Rule

If:
```
localEntry.Version >= incomingVersion
```
the update is ignored.

# Cluster Consistency & Automatic Healing

Two parallel mechanisms ensure eventual consistency:

## State Checksum Comparison
After every update, the StateManager computes a deterministic SHA-256 checksum of the entire state (`utils.JSONChecksum`).  
Nodes periodically compare checksums via HTTP requests.

## Metadata-Based Healing (`validateData`)
Every 30 seconds:

1. Collect metadata from all nodes (including DB hash and Version).  
2. If not all DB hashes match:  
   - Select the node with the greatest Version.  
   - Export that node’s full state.  
   - Import it into all outdated nodes.  

This automatically heals:

- Network partitions  
- Nodes restored from disk  
- Nodes with stale or corrupted DB contents  

## Raw-State Validation (`validateState`)
A separate loop fetches `/state` from each node and logs warnings if mismatches appear.

The actual self-healing is done via the metadata path.

# Database Hashing

A cluster-wide DB hash is computed by walking every bucket in lexicographic order and hashing:

- Bucket names  
- Keys  
- Raw JSON values  

This hash is stored in metadata and is used by the healing mechanism.

# Tasks Persistence

Features:

- The entire `tasks` bucket can be saved or replaced.  
- Individual tasks can be loaded, updated, or deleted.  
- When deleting a snapshot, all associated snapshot tasks are automatically removed.  
- The DB hash is updated after every change.  

# Audio Metadata & File Synchronization

Metadata is stored inside BoltDB, but audio files themselves live on disk.

### File Sync Algorithm

1. Download into `.part` temporary file using `O_EXCL`  
2. If `.part` already exists → another sync in progress  
3. Write file safely  
4. `rename()` atomically to final path  
5. Store metadata in DB  

This prevents file corruption when multiple nodes fetch the same asset.

# Device Info Persistence

Device info is stored as a JSON struct and supports:

- Full replace via `SetDeviceInfo`  
- Partial updates via `SetDeviceName`, `SetDeviceLocation`, etc.  
- Efficient field extraction with `json.RawMessage`  

# Export & Import

## Export
`ExportData()` produces a map containing the entire DB:

```json
{
  "active": { ... },
  "snapshots": { ... },
  "tasks": { ... }
}
```

## Import
`ImportData()`:

- Replaces bucket contents  
- Updates DB hash  
- Used by cluster healing  

# Save Debouncing

`SaveState()` is debounced via a worker goroutine to prevent excessive BoltDB writes.

`MarkDirty()` signals that a save should be scheduled.

# Startup Flow

1. Open DB (recreate if corrupted).  
2. Initialize buckets if new.  
3. Load metadata.  
4. Attempt to restore `active/state`.  
5. If missing → activate active snapshot.  
6. Set version from restored snapshot or metadata.  
7. Begin periodic consistency & validation loops.  
