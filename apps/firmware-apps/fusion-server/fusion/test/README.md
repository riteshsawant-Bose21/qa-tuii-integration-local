# Fusion Test Suite (Local UDP)

This directory contains integration tests that can run against a local,
native `fusion-server` binary (macOS included) without multipass.

## Prerequisites

1) Start a local server:

```
./build/fusion-server_darwin_arm64 --local
```

2) Verify it is listening:

- UDP: `:7947`
- HTTP: `:8080`

## Run UDP Tests Locally

From the module root (`fusion/`):

```
FUSION_TEST_LOCAL=1 \
FUSION_TEST_NODES=127.0.0.1:8080 \
FUSION_TEST_VIP=127.0.0.1:8080 \
FUSION_UDP_ADDR=127.0.0.1:7947 \
go test -v --race ./test -run UDP
```

### ACK/Retry Tests (Opt-in)

```
FUSION_TEST_LOCAL=1 \
FUSION_TEST_NODES=127.0.0.1:8080 \
FUSION_TEST_VIP=127.0.0.1:8080 \
FUSION_UDP_ADDR=127.0.0.1:7947 \
FUSION_UDP_ACK_TEST=1 \
go test -v --race ./test -run BroadcastAckStopsRetries
```

```
FUSION_TEST_LOCAL=1 \
FUSION_TEST_NODES=127.0.0.1:8080 \
FUSION_TEST_VIP=127.0.0.1:8080 \
FUSION_UDP_ADDR=127.0.0.1:7947 \
FUSION_UDP_RETRY_TEST=1 \
go test -v --race ./test -run BroadcastRetriesWithoutAck
```

### Stale Client Test (Opt-in)

This test waits ~12 seconds to allow the server stale TTL to expire, then
asserts the client is pruned (no broadcast received).

```
FUSION_TEST_LOCAL=1 \
FUSION_TEST_NODES=127.0.0.1:8080 \
FUSION_TEST_VIP=127.0.0.1:8080 \
FUSION_UDP_ADDR=127.0.0.1:7947 \
FUSION_UDP_STALE_TEST=1 \
go test -v --race ./test -run StaleClientPruned
```

### UDP Observer Latency Diagnostic (Opt-in, Local)

This diagnostic is useful on macOS, where Multipass cannot return UDP observer
traffic from the VM back to the host test process.

1. From the repo root, build and start a local server with UDP diagnostics enabled:

```bash
./build-fusion-server --target darwin
FUSION_UDP_DIAGNOSTICS=1 ./build/fusion-server --local
```

2. From the module root (`fusion/`), run the latency diagnostic against the local server:

```bash
FUSION_TEST_LOCAL=1 \
FUSION_TEST_NODES=127.0.0.1:8080 \
FUSION_TEST_VIP=127.0.0.1:8080 \
FUSION_UDP_ADDR=127.0.0.1:7947 \
FUSION_UDP_OBSERVER_LATENCY_TEST=1 \
go test -v --race ./test -run TestFusionUDP_ObserverLatencyDiagnostic
```

Notes:
- `FUSION_UDP_DIAGNOSTICS=1` enables `/cluster/udp/status`, which the test samples while load is running.
- `FUSION_UDP_ADDR=127.0.0.1:7947` disables the macOS Multipass skip path and forces the test to target the local UDP server.
- This validates the single-node local observer path. It does not reproduce full multi-node Multipass network behavior.

### Multi-Node UDP Chaos Test (Opt-in, Multipass)

This test simulates many virtual UDP devices over a 3+ node cluster and injects:
- packet loss
- dropped connections
- reconnect behavior
- jitter/burst traffic
- occasional malformed payloads

From module root (`fusion/`), run:

```bash
FUSION_UDP_CHAOS_TEST=1 \
FUSION_TEST_NODES=http://192.168.2.2:8080,http://192.168.2.3:8080,http://192.168.2.4:8080 \
FUSION_UDP_VIRTUAL_DEVICES=120 \
FUSION_UDP_TEST_DURATION=30s \
FUSION_UDP_PACKET_LOSS=0.25 \
FUSION_UDP_DISCONNECT_RATE=0.05 \
go test -v --race ./test -run ChaosMesh
```

Key knobs:
- `FUSION_UDP_NODES`: explicit UDP targets (`ip:port,ip:port,...`). If omitted, the test derives UDP node addresses from `FUSION_TEST_NODES` and uses UDP port `7947`.
- `FUSION_UDP_VIRTUAL_DEVICES`: number of virtual clients.
- `FUSION_UDP_TEST_DURATION`: test duration (`30s`, `60s`, etc).
- `FUSION_UDP_PACKET_LOSS`: intentional send-drop probability (`0..1`).
- `FUSION_UDP_DISCONNECT_RATE`: connection drop probability per loop (`0..1`).
- `FUSION_UDP_BURST_CHANCE`: chance of burst sends (`0..1`).
- `FUSION_UDP_BURST_MAX_EXTRA`: max extra packets per burst.
- `FUSION_UDP_SEND_MIN` / `FUSION_UDP_SEND_MAX`: per-device send interval bounds.
- `FUSION_UDP_RECONNECT_MIN` / `FUSION_UDP_RECONNECT_MAX`: reconnect delay bounds.

## Run Snapshot + Scene Catalog Tests

The integration tests are now split across:
- `snapshot_test.go` for **Time Machine** tests
- `scene_catalog_test.go` for **Scene Catalog** tests

They validate both:
- **Time Machine** behavior (`/time-machine/*`): create/activate/update/delete, epoch consistency, convergence
- **Scene Catalog** behavior (`/snapshots/*`, `/scene-sets/*`, `/scenes/list`, `/scene-catalog-list`)

By default, tests target `http://192.168.2.100:8080`. You can override with:
- `FUSION_TEST_VIP` (e.g. `127.0.0.1:8080`)
- `FUSION_TEST_NODES` (e.g. `127.0.0.1:8080`)
- `FUSION_TEST_ADMIN` (optional; defaults to the `FUSION_TEST_VIP` host on port `9090`, so you only need to set this if your admin port is on a different host)

### Prerequisites (non-UDP tests)

If you are only testing Time Machine / Scene Catalog (not UDP), do this first:

1) Build a fresh local binary (recommended every test run)

From `fusion-server/` root:

```bash
make build-darwin-arm64
```

2) Start local server

```bash
./build/fusion-server_darwin_arm64 --local
```

3) Confirm HTTP is up

```bash
curl -s http://127.0.0.1:8080/metadata | head
```

4) Run tests from module root (`fusion/`) with both env vars set

**Only Run Time-Machine Tests**

```bash
FUSION_TEST_VIP=127.0.0.1:8080 \
FUSION_TEST_NODES=127.0.0.1:8080 \
go test -v --race ./test -run TimeMachine
```

*Footnote:* The three Time Machine epoch-convergence tests (`TestTimeMachineActivationBumpsEpoch`, `TestTimeMachineRejectOldEpochUpdatesAfterActivation`, `TestTimeMachineNewEpochUpdatesApply`) are cluster-only and auto-skip in local single-node runs.

**Only Run Scene Catalog Tests**

```bash
FUSION_TEST_VIP=127.0.0.1:8080 \
FUSION_TEST_NODES=127.0.0.1:8080 \
go test -v --race ./test -run SceneCatalog
```

### Test All Three (Without Cluster)

This includes UDP + Time Machine + Scene Catalog tests in `./test`:

```bash
FUSION_TEST_LOCAL=1 \
FUSION_TEST_VIP=127.0.0.1:8080 \
FUSION_TEST_NODES=127.0.0.1:8080 \
FUSION_UDP_ADDR=127.0.0.1:7947 \
go test -v --race ./test
```

Run a single test while debugging:

```bash
go test -v --race ./test -run TestSceneCatalogListAll
```

### Requirements / Caveats

- Most Snapshot/Scene Catalog tests run fine against a single local node when `FUSION_TEST_VIP=127.0.0.1:8080` and `FUSION_TEST_NODES=127.0.0.1:8080` are both set.
- Cluster-wide tests require 2+ nodes and are now auto-skipped when cluster membership is unavailable or single-node.
- Restart-based tests need a restart script (`FUSION_RESTART_SCRIPT`) or `fusion/scripts/multipass/restart-fusion.sh`; otherwise they auto-skip.

### Cluster-wide tests: when do they run vs skip?

Cluster-wide Time Machine tests run only when all of the following are true:

1) `FUSION_TEST_VIP` points to a live cluster VIP/API
2) `GET <VIP>/cluster/members` succeeds
3) The members response contains at least **2 nodes**

If any of those fail, cluster-only tests are skipped by design.

Current scope note:
- `TimeMachine` includes dedicated cluster/restart assertions.
- `SceneCatalog` currently validates API and state behavior through the VIP path, but does **not yet** include dedicated cross-node replication assertions (for example, verifying persisted definitions/current-scene on each individual node).

Restart-based tests run only when a restart script is available:
- `FUSION_RESTART_SCRIPT=/abs/path/to/restart-fusion.sh`, or
- default path exists: `fusion/scripts/multipass/restart-fusion.sh`

### How to set up and run cluster-wide tests

From repo root (`fusion-server/`), bring up a 3-node cluster:

```bash
./build-fusion-server
./scripts/multipass/launch --instances 3
```

Verify VIP and membership:

```bash
curl -s http://192.168.2.100:8080/cluster/members | jq
```

From module root (`fusion/`), run cluster-wide Time Machine tests:

```bash
FUSION_TEST_VIP=192.168.2.100:8080 \
FUSION_TEST_NODES=192.168.2.104:8080,192.168.2.105:8080,192.168.2.106:8080 \
FUSION_RESTART_SCRIPT=../scripts/multipass/restart-fusion.sh \
go test -count=1 -v --race ./test -run TimeMachine
```

### Test Everything Including Cluster Tests

With a running 2+ node cluster and restart script available, run:

```bash
FUSION_TEST_VIP=192.168.2.100:8080 \
FUSION_TEST_NODES=192.168.2.2:8080,192.168.2.3:8080,192.168.2.4:8080 \
FUSION_RESTART_SCRIPT=../scripts/multipass/restart-fusion.sh \
FUSION_UDP_ADDR=192.168.2.100:7947 \
go test -count=1 -v --race ./test
```

(The `-count=1` is for when you change the environment variables - my multipass will increment the IPs every time I run it. Without this flag, you'll get cached test results).

That is the full-coverage path (UDP + Time Machine + Scene Catalog + cluster/restart cases).

## Notes

- The UDP multipass-based tests in `fusion_test.go` are skipped when
  `FUSION_TEST_LOCAL=1` is set.
- Use your LAN IP instead of `127.0.0.1` if testing from another machine.
