# UDP JSON Observer

A lightweight JSON value monitor that receives normal configuration updates over
UDP and tracks nested object paths, array indices, and wildcard patterns.

When a server-side configuration update is too large for a safe UDP datagram,
the server sends a small `config_pull_required` UDP notification instead. The
observer then pulls the full current config with a dependency-free POSIX
HTTP/1.0 `GET /value` request. Normal small updates still stay on UDP.

## Dependencies

Main binary:
- C++17 compiler
- pthreads
- jsoncpp
- spdlog headers

Tests:
- googletest

The observer does not link libcurl. The HTTP fallback is implemented with POSIX
sockets.

## Building for ARM64

### Create a Builder Instance
```bash
multipass launch -n arm-builder -c 2 -m 4G -d 10G --cloud-init - << EOF
#cloud-config
package_update: true
package_upgrade: false
packages:
 - g++
 - build-essential
 - libjsoncpp-dev
 - libspdlog-dev
 - libgtest-dev

runcmd:
 - which g++
 - g++ --version
 - ld --version
EOF
```

### Setup Build Environment
```bash
# Create the target directory
multipass exec arm-builder -- mkdir -p observer

# Copy the source to the instance and build
multipass transfer observer.* arm-builder:observer/
multipass exec arm-builder -- bash -c "cd observer; make arm64"

# Copy the binary to fusion1
multipass transfer arm-builder:observer/build/arm64/observer /tmp
multipass transfer /tmp/observer fusion1:/tmp
multipass exec fusion1 -- sudo mv /tmp/observer /usr/local/bin
```

## Usage

Basic syntax:
```bash
/usr/local/bin/observer <server_ip> <port> <path>
```
The `port` argument is the Fusion UDP port, normally `7947`. The HTTP fallback
uses port `8080`.

The `--verbose` argument enables debug output.

The observer supports several path notation formats:

### Simple Key Path
Monitor a nested object value:
```bash
/usr/local/bin/observer 127.0.0.1 7947 settings.audio.volume
```

### Array Index Path
Monitor a specific array element:
```bash
/usr/local/bin/observer 127.0.0.1 7947 settings.audio.peq1.gain[2]
```

### Combined Object and Array Path
Monitor nested array elements within objects:
```bash
/usr/local/bin/observer 127.0.0.1 7947 devices[0].channel.volume
/usr/local/bin/observer 127.0.0.1 7947 mixer.inputs[3].effects[1].param
```

## Path Format

The path can include:
- Dot notation for object properties: `parent.child.property`
- Array indices in square brackets: `array[0]`
- Any combination of objects and arrays: `parent.array[0].child.items[2].value`

## Example Output

When monitoring a path, changes will be displayed with timestamps:

```
14:23:45 settings.audio.volume changed from: 0.5 to: 0.7
14:23:47 settings.audio.peq1.gain[2] changed from: -6.0 to: -3.0
14:23:50 devices[0].channel.volume changed from: 0.8 to: 0.6
```

## Oversized Updates

UDP messages are bounded by datagram size. When Fusion detects that a config
broadcast would exceed the UDP payload limit, it sends a compact notification:

```json
{
  "_fusion_op": "config_pull_required",
  "_fusion_epoch": 1,
  "_fusion_version": 42
}
```

On receipt, `UDPValueMonitor`:
- validates the Lamport epoch/version ordering
- performs `GET /value` against the same server IP on HTTP port `8080`
- applies the returned config to local watchers
- ACKs the UDP notification only after the HTTP pull succeeds

## Running Tests

The observer tests include pure unit tests plus UDP monitor tests that spin up
fake UDP and HTTP servers. They do not require `fusion-server` to be running.

Run all observer tests:
```bash
make -C tools/observer test
```

Run only the basic UDP monitor test:
```bash
GTEST_FILTER=UDPValueMonitorTest.AsynchronousUpdatesAndNetworking \
make -C tools/observer test
```

Run only the config-pull fallback test:
```bash
GTEST_FILTER=UDPValueMonitorTest.ConfigPullRequiredPullsFullConfigOverHTTP \
make -C tools/observer test
```

Run the fusion-server integration test with a local server:

```bash
# From the fusion-server repo root, build and start a local server.
make build-darwin-arm64
./build/fusion-server_darwin_arm64 --local
```

In another terminal:

```bash
FUSION_UDP_INTEGRATION=1 \
FUSION_UDP_ADDR=127.0.0.1:7947 \
GTEST_FILTER=UDPValueMonitorTest.IntegrationWithFusionServer \
make -C tools/observer test
```

Run the live oversized-update integration test, which verifies that a real
fusion-server emits `config_pull_required` and the observer pulls `/value`:

```bash
FUSION_UDP_INTEGRATION=1 \
FUSION_UDP_ADDR=127.0.0.1:7947 \
GTEST_FILTER=UDPValueMonitorTest.IntegrationOversizedUpdatePullsConfigFromFusionServer \
make -C tools/observer test
```

Run the live delete integration test, which seeds a value through HTTP,
calls real `DELETE /value`, and verifies the observer receives the UDP clear:

```bash
FUSION_UDP_INTEGRATION=1 \
FUSION_UDP_ADDR=127.0.0.1:7947 \
GTEST_FILTER=UDPValueMonitorTest.IntegrationDeleteValueBroadcastClearsObserverState \
make -C tools/observer test
```

## Notes

- Array indices start at 0
- Invalid array indices will be reported as errors
- The observer automatically creates missing objects and arrays in the path
- Arrays are automatically resized to accommodate the specified index
