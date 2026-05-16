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
| `configs/http_writer.json` | HTTP PATCH writer | Uses admin HTTP `PATCH /state` on port `9090` instead of WebSocket for writes. Useful for comparing transport overhead. |
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

# HTTP writer — compare admin HTTP PATCH overhead vs WebSocket writer
./stress_tester -config configs/http_writer.json

# Mixed topology — full cluster coverage: writer on .131, listeners on all 3 nodes
./stress_tester -config configs/mixed_topology.json

# Mixed topology with quiet output — same test, summary only
./stress_tester -config configs/mixed_topology.json -verbosity quiet

# Enable CPU profiling on inferred node targets (same hosts, port 9090)
./stress_tester -config configs/mixed_topology.json -profile

# Enable CPU profiling on explicit debug endpoints
./stress_tester -config configs/mixed_topology.json -profile \
  -profile-hosts 192.168.2.131:9090,192.168.2.132:9090,192.168.2.133:9090
```

For detailed usage, configuration reference, output format, and parameter documentation, see [REFERENCE.md](REFERENCE.md).
