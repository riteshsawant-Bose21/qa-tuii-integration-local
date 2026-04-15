# device_id_probe

Small UDP helper used by the multipass cluster regression test for device ID updates.

## Purpose

`device_id_probe` runs on a Fusion VM, registers as a UDP client against the local
`fusion-server`, waits for `device_update` messages, ACKs them, and reports whether
it observed a specific expected device ID.

The main test using it is:

- `fusion/test/cluster_test.go`
- `TestDeviceIDUpdate_UDPStaysLocal_WebSocketSeesCluster`

That test uses this helper to verify:

- local device ID updates are delivered over UDP only to the local observer
- remote nodes do not receive the same UDP device ID update
- WebSocket notifications still propagate cluster-wide

## Build

The test cross-compiles this helper from macOS for the Multipass VMs with:

```sh
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -o /tmp/device_id_probe ./tools/device_id_probe/main.go
```

No `arm-builder`, Python, or extra runtime dependencies are required.

## Runtime contract

Arguments:

```text
device_id_probe <server_ip> <port> <expected_device_id> [timeout_seconds]
```

Example:

```sh
/tmp/device_id_probe 127.0.0.1 7947 my-device-id 8
```

Output:

- first prints `ready` after the initial UDP registration handshake succeeds
- then prints one final JSON line

Example success:

```json
{"status":"matched","device_id":"my-device-id","expected_device_id":"my-device-id","last_seen":"my-device-id"}
```

Example timeout:

```json
{"status":"timeout","expected_device_id":"my-device-id","last_seen":""}
```
