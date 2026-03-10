# Fusion Cluster Architecture

This document describes the current Fusion cluster system as implemented in the source code.  
It replaces the earlier memberlist‑focused documentation with an accurate, up‑to‑date overview of how nodes discover each other, synchronize configuration state, manage snapshots, and integrate with VIP failover.

## Overview

Fusion uses a gossip‑based membership protocol (Hashicorp Memberlist) combined with a virtual IP (VIP) managed by Keepalived/VRRP.  
The VIP acts as the authoritative discovery point for all nodes.  
Memberlist handles cluster membership, failure detection, and push/pull state transfer, while higher‑level Fusion features (snapshots, tasks, audio sync) ride on top of the cluster messaging layer.

## Node Startup Flow

Each node starts with a static configuration (`AppConfig`) specifying:

- `Network Inteface` - passed as a startup argument
- `NodeName` - its a randomized name in the code
- Whether the node is running as a local/standalone instance
- Each node expects an interface being passed
- The network interface is used for VRRP events
- The cluster will bind to the IP address on the given interface

During startup:

- Keepalived is monitored for VIP gain/loss events.
- The node parses its local keepalived config to determine the VIP.
- A VRRP listener reports new VIP holders.
- The node’s own VIP state is updated and broadcast to local processes.

If the node is the first instance in the cluster, it will start alone.  
If not, the node performs cluster discovery.

## Cluster Discovery via VIP

Instead of a static seed list, Fusion discovers peers using the VIP:

1. Query the admin API on:  
   `http://VIP:HTTP_PORT/cluster/members`
2. Filter for alive nodes.
3. Join the cluster using their memberlist addresses.
4. Retry until success or until the VIP becomes reachable.

If the VIP is not yet up (e.g., the node is the new master), the node will gracefully handle the failure and bootstrap the cluster alone.

## VIP Handling

Fusion integrates tightly with Keepalived:

- The active node holding the VIP becomes the authoritative discovery endpoint.
- Nodes listen for VRRP events to detect:
  - VIP gained locally
  - VIP lost locally
  - VIP moved to another node

Changes are broadcast to localhost via a small UDP notifier so other subsystems (API server, tasks, persistence) can react.

The VIP string is canonicalized to pure IPv4.

## Memberlist Configuration

Fusion configures memberlist with:

- Tuned gossip intervals
- Custom suspicion multiplier
- Extended failure detection parameters
- A `ClusterDelegate` used for all state synchronization and cluster messaging

Bind and advertise address/port come directly from `AppConfig`.

## Cluster Delegate

The `ClusterDelegate` is the heart of the cluster synchronization logic. It implements:

### Metadata Exchange (`NodeMeta`)
Provides node ID and current state version.

### Incoming Messages (`NotifyMsg`)
Handles cluster‑wide operations:

- Configuration updates (Lamport‑style versioning)
- Snapshot create/delete/activate/save
- Task create/update/delete
- Audio file sync and metadata removal

### State Transfer (`LocalState` / `MergeRemoteState`)
During push/pull (periodic or join):

- Epoch mismatches are resolved deterministically.
- Newer epochs overwrite local state.
- Equal epochs merge on a per‑key basis.
- All merges mark persistence dirty.

### Clock Skew + Sync Latency Tracking
Incoming messages include timestamps.  
The delegate computes:

- Detected skew per node (large future timestamps)
- End‑to‑end latency in milliseconds
- Pruned historical metrics over time

## Persistence Interactions

Most cluster‑level operations translate to persistence actions:

- Applying configuration updates
- Syncing audio files from peers during initial startup
- Saving/deleting snapshots
- Marking state as dirty so background flusher can persist to disk

State changes resulting from cluster messages are rebroadcast to observers via the Hub.

## Network and Sync Metrics

Fusion records:

- Sync latencies for all NotifyMsg operations
- Clock skew events
- Network latencies (ICMP‑style probe store)
- Cluster health values derived from member state

These metrics are exposed through the admin API for monitoring and diagnostics.

## Audio Synchronization

During startup, a node attempts to synchronize its audio metadata and missing files from one peer:

- Requests `/pava/messages` from a peer
- Downloads metadata and reconstructs local audio files
- Reconciles orphaned files and stale metadata

This ensures a consistent audio library across nodes.

## Snapshot Management Across the Cluster

Snapshot operations propagate via NotifyMsg:

- `SnapCreate`
- `SnapSave`
- `SnapActivate`
- `SnapDelete`

Activation includes:

- Epoch bump
- Full state replacement
- Metadata update
- Observer notification

The cluster converges automatically because versioning rules ensure updates are ordered.

## Task Synchronization

Task creation, modification, and deletion are cluster‑wide operations:

- A task added on one node is reflected on all others.
- Updates carry the full task struct.
- Disable/enable operations are synchronized through the same mechanism.

## Transport Abstraction

`ClusterTransport` decouples the pubsub system from memberlist.  
The cluster delegate still uses full memberlist APIs, but higher‑level components interact only through the abstract interface.

This permits future transports (static peers, WebSocket mesh, etc.) without rewriting pubsub.

## Admin API Interaction

Many cluster functions query other nodes through the admin API:

- Cluster membership
- Metrics
- Device information
- Snapshot listing

The fetch helpers automatically choose between local and remote + decode the JSON.

## Failure Handling

Memberlist provides:

- Direct and indirect probes
- Suspect timers
- Dead node marking
- Automatic reintegration upon recovery

Combined with VRRP, the system remains stable even under:

- Node failures
- VIP transitions
- Network instability

## Summary

Fusion’s cluster architecture is built on:

- Memberlist for robust distributed membership
- VIP‑based discovery and failover
- A powerful delegate that synchronizes all shared state (config, tasks, snapshots, audio)
- Local persistence ensuring durability
- Metrics and clock‑skew tracking for diagnostics

Fusion nodes dynamically join, merge state, survive failures, and converge on consistent distributed state without any central server.

