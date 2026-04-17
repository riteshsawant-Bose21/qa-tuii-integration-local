# Fusion Server Stress Tester

A standalone Go CLI tool that measures update propagation latency and loss across direct writes, WebSocket listeners, and UDP listeners against a running fusion-server instance.

## What it does

1. **Writer** sends sequential `patch_config` updates (incrementing `settings.audio.GAIN.gain` from 1 upward)
2. **WebSocket listeners** subscribe to `config_update` push notifications
3. **UDP listeners** register via `{"action":"get"}` handshake and receive broadcasts
4. All observations are correlated by gain value to compute propagation latency, missed updates, duplicates, and out-of-order delivery

## Build

```bash
cd apps/firmware-apps/fusion-server/tools/stress_tester
GOWORK=off go build -o stress_tester .
```

> **Note:** This is a standalone module not listed in the parent `go.work` file.
> The `GOWORK=off` flag disables workspace mode so `go build` resolves dependencies from this module's own `go.mod`.

## Usage

### Basic (same-node, defaults)

```bash
./stress_tester
```

Defaults: 3 WS listeners, 5 UDP listeners, 100 updates/sec, 3000 total updates, writer via WebSocket.

### With CLI flags

```bash
./stress_tester \
  -writer-host 192.168.2.131:8080 \
  -ws-hosts 192.168.2.131:8080 \
  -udp-server-host 192.168.2.131:7947 \
  -rate 500 \
  -total 5000 \
  -output results.json
```

### Cross-node testing

```bash
./stress_tester \
  -writer-host 192.168.2.131:8080 \
  -ws-hosts 192.168.2.132:8080,192.168.2.133:8080 \
  -ws-count 4 \
  -udp-server-host 192.168.2.132:7947 \
  -udp-count 3 \
  -rate 200 \
  -total 1000
```

### Soak mode

```bash
./stress_tester \
  -soak \
  -soak-duration 30m \
  -rate 100
```

### Burst mode

```bash
./stress_tester \
  -burst \
  -burst-multiplier 5.0 \
  -rate 200 \
  -total 3000
```

### Using a config file

```bash
./stress_tester -config test_config.json
```

CLI flags override config file values.

## Configuration

All settings are configurable via JSON file, CLI flags, or both.

| Setting | CLI Flag | Default | Description |
|---------|----------|---------|-------------|
| `writer_mode` | `-writer-mode` | `ws` | Writer transport: `ws` or `http` |
| `writer_host` | `-writer-host` | `localhost:8080` | Writer target host:port |
| `ws_listener_hosts` | `-ws-hosts` | `["localhost:8080"]` | WS listener targets (comma-separated for CLI) |
| `ws_listener_count` | `-ws-count` | `3` | Number of WebSocket listeners |
| `udp_listener_bind_ips` | `-udp-bind-ips` | `["0.0.0.0"]` | Local IPs to bind UDP sockets |
| `udp_listener_count` | `-udp-count` | `5` | Number of UDP listeners |
| `udp_port` | `-udp-port` | `7947` | UDP server port |
| `udp_server_host` | `-udp-server-host` | `localhost:7947` | UDP server host:port |
| `updates_per_second` | `-rate` | `100` | Send rate |
| `burst_mode` | `-burst` | `false` | Enable bursty sending |
| `burst_multiplier` | `-burst-multiplier` | `5.0` | Burst sub-rate multiplier |
| `total_updates` | `-total` | `3000` | Updates in bounded mode |
| `soak_mode` | `-soak` | `false` | Run for a duration instead |
| `soak_duration` | `-soak-duration` | `30m` | Soak mode duration |
| `start_gain` | `-start-gain` | `1` | Starting gain value |
| `grace_period` | `-grace` | `5m` | Post-send wait for late arrivals |
| `adaptive_grace` | `-adaptive-grace` | `true` | End grace early when done |
| `listener_startup_timeout` | `-startup-timeout` | `10s` | Max wait for listeners to be ready |
| `output_path` | `-output` | `stress_test_report.json` | JSON report path |
| `verbosity` | `-verbosity` | `normal` | `quiet`, `normal`, or `verbose` |

### Example config file

```json
{
  "writer_mode": "ws",
  "writer_host": "192.168.2.131:8080",
  "ws_listener_hosts": ["192.168.2.131:8080", "192.168.2.132:8080"],
  "ws_listener_count": 4,
  "udp_server_host": "192.168.2.131:7947",
  "udp_listener_count": 5,
  "updates_per_second": 500,
  "total_updates": 5000,
  "output_path": "results.json",
  "verbosity": "normal"
}
```

## Output

### Console

Human-readable progress (every 5s) and a final summary table:

```
[5s] sent=500  gain=500  ws_rx=1480  udp_rx=2470

═══════════════════════════════════════════════════════════════
  STRESS TEST SUMMARY
═══════════════════════════════════════════════════════════════
  Duration:       10.234s
  Writer mode:    ws
  Target rate:    100 updates/sec
  Sent:           1000  (last gain = 1000)

  WebSocket Listeners
  ─────────────────────────────────────────────────────────────
  Name             Recv   Miss   Dup   OoO    P50ms    P95ms    P99ms Latest?
  ws-1              998      2     0     0     1.23     3.45     5.67 ✓
  ws-2             1000      0     0     0     1.10     3.20     5.00 ✓
  ws-3              999      1     0     0     1.15     3.30     5.40 ✓

  UDP Listeners
  ─────────────────────────────────────────────────────────────
  Name             Recv   Miss   Dup   OoO    P50ms    P95ms    P99ms Latest?
  udp-1             995      5     0     0     2.50     8.00    12.00 ✓
  ...

───────────────────────────────────────────────────────────────
  AGGREGATE
───────────────────────────────────────────────────────────────
  Listeners:      8 total
  Received:       7988 total
  Missed:         12 total
  ...
═══════════════════════════════════════════════════════════════
```

### JSON report

Machine-readable `stress_test_report.json` with full `RunResult` including per-listener `LatencyStats`, `MissingGains`, and aggregate data.

## Exit codes

| Code | Meaning |
|------|---------|
| 0 | All listeners received the latest value |
| 1 | Configuration or runtime error |
| 2 | One or more listeners did NOT receive the latest value |

## Matching logic

- Updates are correlated by **gain value only** — no message ID required
- Duplicate = same gain received more than once on the same listener
- Out-of-order = gain value lower than the highest previously seen
- Missing intermediate = gain values in `[start_gain..last_sent_gain]` not received
- Latest value error = listener did not receive the final sent gain

## Parameter Reference

Detailed explanation of every configuration parameter:

### Writer Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `writer_mode` | `string` | `"ws"` | Transport protocol for sending patch updates. **`ws`** sends WebSocket `patch_config` messages to the `/ws` endpoint. **`http`** sends HTTP `PATCH /value` requests. WebSocket mode is recommended as it matches the primary client protocol and avoids per-request TCP overhead. |
| `writer_host` | `string` | `"localhost:8080"` | The `host:port` of the fusion-server node that receives all writes. This is the node whose state is mutated. In cross-node tests, point this at one node and listeners at different nodes to measure cluster propagation. |

### WebSocket Listener Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `ws_listener_hosts` | `[]string` | `["localhost:8080"]` | List of fusion-server `host:port` targets for WebSocket listeners. Listeners are distributed across these hosts in round-robin order. For same-node tests use a single entry matching `writer_host`. For cross-node tests, list remote nodes to measure cluster propagation latency. |
| `ws_listener_count` | `int` | `3` | Total number of WebSocket listener connections to create. Each listener connects to a host from `ws_listener_hosts` (round-robin), sends a `config` subscribe message, and records every `config_update` push. Set to `0` to disable WebSocket listeners entirely. |

### UDP Listener Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `udp_listener_bind_ips` | `[]string` | `["0.0.0.0"]` | Local IP addresses to bind UDP listener sockets to. Each listener binds on an ephemeral port on one of these IPs (round-robin). Use `0.0.0.0` to bind on all interfaces, or specify a specific NIC IP if needed. |
| `udp_listener_count` | `int` | `5` | Total number of UDP listener sockets to create. Each registers with the fusion-server by sending a `{"action":"get"}` handshake, then receives all `config_update` broadcasts. Always sends ACK replies to prevent retransmission noise. Set to `0` to disable UDP listeners. |
| `udp_port` | `int` | `7947` | The port number of the fusion-server's UDP endpoint. Only used if `udp_server_host` doesn't already include a port. |
| `udp_server_host` | `string` | `"localhost:7947"` | The `host:port` of the fusion-server UDP endpoint that listeners register with and receive broadcasts from. For cross-node UDP testing, point this at a different node than `writer_host`. |

### Send Rate Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `updates_per_second` | `int` | `100` | Target send rate. In even mode, a `time.Ticker` fires at `1s / updates_per_second` intervals for smooth, evenly-spaced sends. In burst mode, this is the *average* target rate — actual instantaneous rate will be higher during bursts and zero during pauses. Typical test values: `100` (gentle), `500` (moderate), `1000` (stress). |
| `burst_mode` | `bool` | `false` | When `true`, sends updates in rapid sub-bursts instead of evenly-spaced ticks. Each burst fires at `burst_multiplier × updates_per_second` rate for a fraction of a second, then pauses for the remainder to maintain the average rate. Useful for testing how the server handles bursty traffic patterns. |
| `burst_multiplier` | `float64` | `5.0` | How much faster than the nominal rate to send during burst windows. A value of `5.0` means bursts are sent at 5× the normal rate for 1/5 of a second, then the writer pauses for 4/5 of a second. Must be `> 1.0` when burst mode is enabled. Higher values create spikier traffic. |

### Run Boundary Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `total_updates` | `int` | `3000` | Number of updates to send in **bounded mode** (when `soak_mode` is `false`). Gain values will range from `start_gain` to `start_gain + total_updates - 1`. Ignored when soak mode is enabled. |
| `soak_mode` | `bool` | `false` | When `true`, the writer sends continuously until `soak_duration` expires instead of stopping after `total_updates`. Gain increments forever starting from `start_gain`. Use for long-running reliability tests. |
| `soak_duration` | `duration` | `"30m"` | How long to run in soak mode. Accepts Go duration strings in JSON (nanoseconds as integer). Only used when `soak_mode` is `true`. Examples: 30 minutes = `1800000000000`, 1 hour = `3600000000000`. |
| `start_gain` | `int` | `1` | The first gain value to send. Subsequent values increment by 1. Useful for resuming tests or avoiding collision with prior state. |

### Grace / Timeout Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `grace_period` | `duration` | `"5m"` | Maximum time to wait after the last send for late-arriving updates to reach all listeners. This accounts for network delays, server processing queues, and cluster gossip propagation. 5 minutes is generous; reduce for faster test turnaround if latency is known to be low. In JSON: nanoseconds integer (300000000000 = 5m). |
| `adaptive_grace` | `bool` | `true` | When `true`, the grace period ends early as soon as **all** listeners have received the final sent gain value. Polls every 2 seconds. When `false`, always waits the full `grace_period`. Recommended to leave `true` for faster test completion. |
| `listener_startup_timeout` | `duration` | `"10s"` | Maximum time to wait for all listeners to complete their handshake and be ready to receive updates. If any listener fails to become ready within this timeout, the test aborts. Increase for high-latency networks or many listeners. In JSON: nanoseconds (10000000000 = 10s). |

### Output Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `output_path` | `string` | `"stress_test_report.json"` | File path for the JSON report output. Contains the full `RunResult` struct with per-listener stats, latency percentiles, missing gains, and aggregate data. Use different paths per config to avoid overwriting. |
| `verbosity` | `string` | `"normal"` | Console output level. **`quiet`**: only the final summary table. **`normal`**: startup info, progress updates every 5s, and final summary. **`verbose`**: all of normal plus per-send/per-receive logging (very noisy at high rates). |

### Duration Values in JSON

Go `time.Duration` values in JSON are represented as **nanoseconds** (integer):

| Human | Nanoseconds |
|-------|-------------|
| 1 second | `1000000000` |
| 10 seconds | `10000000000` |
| 1 minute | `60000000000` |
| 5 minutes | `300000000000` |
| 30 minutes | `1800000000000` |
| 1 hour | `3600000000000` |

## Sample Configurations

Pre-built config files are in the `configs/` directory:

| File | Scenario | Description |
|------|----------|-------------|
| `configs/same_node.json` | Same-node baseline | Writer and all listeners target the same node (`192.168.2.131`). 100 updates/sec, 3000 total. Good starting point. |
| `configs/cross_node.json` | Cross-node propagation | Writer targets `192.168.2.131`, WS listeners on `.132` and `.133`, UDP on `.132`. Measures cluster gossip latency. |
| `configs/high_rate.json` | High-rate stress | 1000 updates/sec, 10000 total, 6 WS + 9 UDP listeners across all 3 nodes. Tests server throughput limits. |
| `configs/burst_mode.json` | Bursty traffic | 5× burst multiplier with verbose output. Tests how the server handles spiky write patterns. |
| `configs/soak_30m.json` | 30-minute soak | Runs for 30 minutes at 50/sec across 2 nodes. Tests long-running reliability and memory stability. |
| `configs/http_writer.json` | HTTP PATCH writer | Uses HTTP `PATCH /value` instead of WebSocket for writes. Useful for comparing transport overhead. |
| `configs/mixed_topology.json` | Mixed topology | Writer on `.131`, WS across all 3 nodes, UDP on `.132`. 500/sec, verbose. Full cluster coverage test. |

### Running with a sample config

```bash
# Same-node baseline — quick sanity check on a single node
./stress_tester -config configs/same_node.json

# Cross-node propagation — measure gossip latency between cluster members
./stress_tester -config configs/cross_node.json

# High-rate stress — push server throughput limits with 1000/sec across all nodes
./stress_tester -config configs/high_rate.json

# High-rate with CLI override — bump to 2000/sec from the command line
./stress_tester -config configs/high_rate.json -rate 2000

# Burst mode — observe server behavior under spiky 5× traffic bursts
./stress_tester -config configs/burst_mode.json

# 30-minute soak — long-running reliability and memory stability test
./stress_tester -config configs/soak_30m.json

# HTTP writer — compare HTTP PATCH overhead vs WebSocket writer
./stress_tester -config configs/http_writer.json

# Mixed topology — full cluster coverage: writer on .131, listeners on all 3 nodes
./stress_tester -config configs/mixed_topology.json

# Mixed topology with quiet output — same test, summary only
./stress_tester -config configs/mixed_topology.json -verbosity quiet
```

## Notes

- UDP listeners always send ACKs to prevent retransmission noise in measurements
- The writer consumes WebSocket responses in a background goroutine to prevent backpressure
- Send timestamps are stored in memory (`map[int]time.Time`); ~150MB for 30min soak at 1000/sec
- In soak mode, gain increments forever until the duration expires
