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

## Notes

- The UDP multipass-based tests in `fusion_test.go` are skipped when
  `FUSION_TEST_LOCAL=1` is set.
- Use your LAN IP instead of `127.0.0.1` if testing from another machine.
