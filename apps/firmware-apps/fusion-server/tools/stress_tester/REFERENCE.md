# Stress Tester Reference

Detailed usage, configuration, output format, and parameter documentation for the stress tester.
See [README.md](README.md) for a quick-start overview.

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

### With CPU profiling enabled

```bash
./stress_tester \
  -config configs/mixed_topology.json \
  -profile
```

By default, `-profile` infers unique node hosts from `writer_host`, `ws_listener_hosts`, and `udp_server_host`, then targets each host on port `9090` using `POST /debug/profile/start` before the run and `POST /debug/profile/stop` on exit.

Override the exact debug endpoints with `-profile-hosts host:port,...` when the profiling port differs from `9090`.

## Configuration

All settings are configurable via JSON file, CLI flags, or both.

| Setting | CLI Flag | Default | Description |
|---------|----------|---------|-------------|
| `writer_mode` | `-writer-mode` | `ws` | Writer transport: `ws` or `http` |
| `writer_host` | `-writer-host` | `localhost:8080` | Writer target host:port |
| `enable_profiling` | `-profile` | `false` | Start CPU profiling before the run and stop it on exit |
| `profile_hosts` | `-profile-hosts` | inferred | Explicit `host:port` targets for profiling endpoints |
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
  "enable_profiling": true,
  "profile_hosts": ["192.168.2.131:9090", "192.168.2.132:9090"],
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

When profiling is enabled, the JSON report also includes `profile_results` with start/stop status and the profile path returned by each target.

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
| `writer_mode` | `string` | `"ws"` | Transport protocol for sending patch updates. **`ws`** sends WebSocket `patch_config` messages to the `/ws` endpoint. **`http`** sends admin HTTP `PATCH /state` requests on port `9090` for the same host. WebSocket mode is recommended as it matches the primary client protocol and avoids per-request TCP overhead. |
| `writer_host` | `string` | `"localhost:8080"` | The `host:port` of the fusion-server node that receives all writes. For `writer_mode: "http"`, the tool rewrites this host to port `9090` automatically and sends requests to the admin API. In cross-node tests, point this at one node and listeners at different nodes to measure cluster propagation. |
| `enable_profiling` | `bool` | `false` | When `true`, the tool starts CPU profiling on each target node before creating listeners or sending traffic, and stops profiling on exit. |
| `profile_hosts` | `[]string` | inferred from targets on port `9090` | Optional explicit debug endpoint `host:port` list for profiling. If omitted, the tool infers unique hosts from `writer_host`, `ws_listener_hosts`, and `udp_server_host`, then rewrites them to port `9090`. |

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

## Notes

- UDP listeners always send ACKs to prevent retransmission noise in measurements
- The writer consumes WebSocket responses in a background goroutine to prevent backpressure
- Send timestamps are stored in memory (`map[int]time.Time`); ~150MB for 30min soak at 1000/sec
- In soak mode, gain increments forever until the duration expires
