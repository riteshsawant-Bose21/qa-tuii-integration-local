# Fusion Server

Fusion Server is a **distributed, high-availability configuration and control system** used for audio devices and clustered compute environments. It provides **strongly consistent snapshots**, **real-time state updates**, **scheduled tasks**, **audio message playback**, **cluster membership**, **VIP failover**, **REST + BLE APIs**, and **local or multipass-based development**.

Fusion Server can be run:
- As a **distributed cluster** (Multipass or real hardware)
- As a **single-node local server** for development, BLE debugging, and Flutter integration


# Features

## Distributed Configuration Management
- Versioned, persistent key-value store
- Nested JSON updates with merge semantics
- Real-time updates over WebSockets and UDP
- Strongly consistent snapshots with epoch-based versioning
- State verification, checksums, and convergence across nodes

## High Availability
- **Memberlist** gossip-based cluster membership
- **HAProxy** load balancing  
- **Keepalived / VRRP** for Virtual IP failover (`192.168.2.100` by default)
- Automatic backend registration and health checks
- Seamless failover and state recovery

## Audio & PAVA Messaging
- Upload audio files (`/pava/messages`)
- Trigger high-priority playback notifications
- UDP broadcast of message triggers
- Scheduling of message playback (`/pava/schedule`)

## Scheduler & Tasks
- Cron-based recurring tasks
- One-shot and scheduled operations
- Task history and enable/disable controls
- Fully programmable via REST

## Snapshots (Consistency Backbone)
- Create, list, delete, and activate snapshots
- Epoch-based clustering model ensures strict ordering
- Snapshot activation resets state cluster-wide
- Full-state restore with deterministic version bumping

## Networking Interfaces
- REST API (primary control interface)
- WebSocket streaming endpoint (`/ws`)
- UDP control channel on port `7947`
- Bluetooth Low Energy (BLE) GATT service for mobile provisioning  
  - Service ID: `B053`  
  - Characteristic ID: `AD10`

## Observability
- `/metrics` for Prometheus & Grafana
- `/cluster/status` and `/cluster/latency` for live cluster health
- NTP skew detection and drift monitoring
- Internal debug endpoints and detailed logging


# Architecture Overview

```
    +----------------------------+
    |        Fusion Client       |
    |  (Flutter, Web, Mobile)    |
    +-------------+--------------+
                  |
          REST / BLE / WebSocket
                  |
                  v
+----------------------------------------+
|            Fusion Server               |
|  - State manager (BoltDB)              |
|  - Snapshot engine                     |
|  - Scheduler & tasks                   |
|  - PAVA audio & message triggers       |
|  - BLE GATT service                    |
+------------------+---------------------+
                   |
        +----------+----------+
        | UDP Control (7947)  |
        +----------+----------+
                   | 
                   v
+-------------------------------------------+
|        Cluster Transport (Memberlist)     |
| - Gossip                                  |
| - Failure detection                       |
| - State propagation                       |
+-------------------------------------------+

+-------------------------------------------+
|       HA Layer (Multipass Deployments)    |
| - Keepalived (VRRP) for VIP               |
| - HAProxy load balancing                  |
+-------------------------------------------+
```

# Running Fusion Server

## Local macOS Development

Build:

```bash
make build-darwin-arm64
```

Run:

```bash
./build/fusion-server_darwin_arm64 --local
```

Local mode:
- Disables HAProxy / Keepalived
- Memberlist runs as a 1‑node cluster
- Enables BLE (Fusion Mini)
- Provides the full REST API

See **Local.md** for detailed local debugging instructions.

# Running a Distributed Cluster (Multipass)

Make sure the build folder is empty, then run:

Build: 

```bash
./build-fusion-server
```

This will create the `fusion-server_linux_arm64` binary inside the build folder.

Launch:

```bash
./scripts/multipass/launch --instances 3
```

List:

```bash
multipass list
```

Shell:

```bash
multipass shell fusion1
```

Kill all:

```bash
./scripts/multipass/launch --kill
```

VIP:

```
http://192.168.2.100:8080
```

# Verbose mode
The service file is located at 
/lib/systemd/system/fusion-server.service

add verbose at the end of the line like

ExecStart=/usr/local/bin/fusion-server -verbose

# REST API Overview

## Configuration
- `GET /value`
- `POST /value`
- `PATCH /value`
- `DELETE /value`
- `GET /ws`

## Snapshots
- `GET /snapshots`
- `POST /snapshots/{name}`
- `POST /snapshots/{name}/activate`
- `DELETE /snapshots/{name}`

## Tasks & Scheduler
- `GET /tasks`
- `POST /tasks`
- `DELETE /tasks/{id}`
- `POST /tasks/{id}/enable`
- `GET /tasks/history`

## Audio Messaging
- `GET /pava/messages`
- `POST /pava/messages`
- `DELETE /pava/messages/{id}`
- `PUT /pava/messages/{id}/trigger`
- `GET /pava/schedule`
- `POST /pava/schedule`

Monitor triggers:

```bash
nc -u -l 7949
```

# Bluetooth (Fusion Mini)

BLE service identifiers for mobile provisioning:

- Service: **B053**
- Characteristic: **AD10**

Used by the `fusion-setup` Flutter app to scan, connect, and bridge REST operations.

# Binary Updates

Upload:

```bash
curl -X POST   -F "binary=@build/fusion-server_linux_arm64"   -F "checksum=$(shasum -a 256 build/fusion-server_linux_arm64 | cut -d ' ' -f 1)"   http://192.168.2.100:8080/version
```

Rollback:

```
POST /version
```

# Metrics & Monitoring

- `GET /metrics`
- `GET /cluster/status`
- `GET /cluster/latency/status`
- `GET /cluster/ntp-skew`

Start Prometheus:

```bash
/opt/homebrew/bin/prometheus --config.file=tools/prometheus/prometheus.yml
```

Start Grafana:

```bash
/opt/homebrew/bin/grafana server
```

# Testing

Create a cluster:

```bash
./scripts/multipass/launch --instances 3
```

Run tests:

```bash
./scripts/multipass/run-tests
```

Run a subset:

```bash
./scripts/multipass/run-tests --snapshot
```

# Troubleshooting macOS [ Tahoe ] and Multipass Issues

## SSH Connection Failed: "No route to host"

If you encounter the following error when setting up multipass instances:

```
Copying fusion-server binary...
ssh connection failed: 'Failed to connect: No route to host'
✗ Failed to copy fusion-server binary
✗ Failed to setup instance fusion1
```

**Fix**: Enable "Local Network" permissions under Privacy & Security settings for both Multipass and VS Code in macOS System Preferences.
Run UDP chaos mesh test:

```bash
./scripts/multipass/run-tests --udp-chaos
```
