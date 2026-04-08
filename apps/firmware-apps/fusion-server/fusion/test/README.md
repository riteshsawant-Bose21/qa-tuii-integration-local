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
- `FUSION_TEST_ADMIN` (optional admin URL, default `http://192.168.2.100:9090`)

From module root (`fusion/`):

```bash
FUSION_TEST_VIP=127.0.0.1:8080 \
go test -v --race ./test -run 'TimeMachine|SceneCatalog'
```

Run only Time Machine tests:

```bash
FUSION_TEST_VIP=127.0.0.1:8080 \
go test -v --race ./test -run TimeMachine
```

Run only the new Snapshot Definition + Scene Set foundation tests:

```bash
FUSION_TEST_VIP=127.0.0.1:8080 \
go test -v --race ./test -run SceneCatalog
```

Run a single test while debugging:

```bash
go test -v --race ./test -run TestSceneCatalogListAll
```

### Requirements / Caveats

- Most Snapshot/Scene Catalog tests run fine against a single local node when `FUSION_TEST_VIP=127.0.0.1:8080`.
- Cluster-wide tests require 2+ nodes and are now auto-skipped when cluster membership is unavailable or single-node.
- Restart-based tests need a restart script (`FUSION_RESTART_SCRIPT`) or `fusion/scripts/multipass/restart-fusion.sh`; otherwise they auto-skip.

## Notes

- The UDP multipass-based tests in `fusion_test.go` are skipped when
  `FUSION_TEST_LOCAL=1` is set.
- Use your LAN IP instead of `127.0.0.1` if testing from another machine.
