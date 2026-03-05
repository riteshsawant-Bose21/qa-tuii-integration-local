# Local Development and Debugging Guide

This document covers building, launching, and debugging `fusion-server` locally on macOS, including Bluetooth development, REST API testing, and audio message workflows.

## Building `fusion-server` for macOS

From the root of the repository:

```bash
make build-darwin-arm64
```

List all available build targets:

```bash
make help
```

Makefile targets relevant to local debugging:

```
build                  - Build for the current platform
run                    - Build and run locally
build-darwin-arm64     - Build for macOS ARM64
build-linux-arm64      - Build for Linux ARM64
build-all              - Build for all platforms
```

After a successful build, the macOS binary appears here:

```
build/fusion-server_darwin_arm64
```

## Running the Server Locally

Launch the macOS build in local mode:

```bash
./build/fusion-server_darwin_arm64 --local
```

Example output:

```
[fusion1] [INFO] [CLUSTER] Total members: 1
[fusion1] [INFO] BLE server initialized: B053 AD10
[fusion1] [INFO] UDP server listening on :7947
[fusion1] [INFO] Starting API server on :9090
[fusion1] [INFO] Starting API server on :8080
[fusion1] [INFO] fusion1 is ALIVE and RUNNING
```

Local mode disables distributed cluster features and is ideal for BLE development and REST debugging.

## Console Logging

If you see:

```
Failed to create log directory: mkdir /var/log/fusion: permission denied
```

macOS does not allow creating `/var/log/fusion` without sudo.

You may run using `sudo`, but for most debugging, console logs are sufficient and the message can be ignored.

Enable verbose logging:

```bash
./fusion-server_darwin_arm64 --local --verbose
```

## Verifying the REST API

Test that the API is running:

```bash
curl localhost:8080
```

The root endpoint lists all available API routes.

Example fields returned:

- build_time  
- endpoints  
- node_id  
- cluster_size  
- version  

REST access works identically to a full multipass deployment, except features requiring a distributed cluster are disabled.

## Using `curl` or Bruno

You can directly call all REST endpoints via `curl`.

A prebuilt Bruno API client collection is also available.  
If you want an updated Bruno collection, ask and it can be generated.

## Uploading Audio Files

Upload WAV or similar audio:

```bash
curl --request POST   --url http://localhost:8080/pava/messages   --header 'content-type: multipart/form-data'   --form display_name="Fire Drill"   --form binary=@/path/to/origin.wav   --form 'tags=Fire Drill'   --form tags=Emergencies
```

Uploaded files are stored in:

```
/var/lib/fusion/audio
```

Files placed manually in this folder are not automatically detected; they must be uploaded via REST or added to the internal DB with a maintenance tool.

## Listing Uploaded Audio Files

```bash
curl http://localhost:8080/pava/messages
```

## Triggering a Message

```bash
curl --request PUT   --url http://localhost:8080/pava/messages/:id/trigger   --header 'content-type: application/json'   --data '{
    "zones": "all",
    "priority": 100
  }'
```

Example console output from `fusion-server`:

```
Triggered message "01K8TYPMWW9HSK2QS5Y5W10ABS" at path "/var/lib/fusion/audio/01K8TYPMWW9HSK2QS5Y5W10ABS.wav" (priority 100)
```

## Monitoring Trigger Broadcasts

Run this in a terminal:

```bash
nc -u -l 7949
```

Triggered messages display a JSON structure:

```json
{
  "id": "01K8TYPMWW9HSK2QS5Y5W10ABS",
  "path": "/var/lib/fusion/audio/01K8TYPMWW9HSK2QS5Y5W10ABS.wav",
  "priority": 100,
  "zones": "all",
  "timestamp": 1761844571
}
```

## Bluetooth Debugging: Verifying Local BLE Advertising

Local builds include BLE support.

The server will print:

```
BLE server initialized: B053 AD10
```

Where:

- `B053` = service identifier  
- `AD10` = characteristic identifier  

Use **nRF Connect** on iOS to verify the BLE broadcast:

https://apps.apple.com/us/app/nrf-connect-for-mobile/id1054362403

Look for a device advertising as **Fusion Mini**.

## Flutter Debugging With BLE

Clone the example Flutter app:

```
https://github.com/BoseProfessional/fusion-setup
```

This application demonstrates:

- Scanning for `fusion-server` (Fusion Mini) over BLE  
- Connecting to the device  
- Making REST calls tunneled through BLE  

Make sure Xcode is installed and configured for iOS development.

Verify available devices:

```bash
flutter devices
```

Example:

```
Gene’s Phone (wireless) • ios • iOS 18.5
```

You may hardcode your device ID in VSCode `launch.json`:

```json
{
  "name": "Fusion Setup (Gene's iPhone)",
  "type": "dart",
  "request": "launch",
  "args": ["-d", "00008101-000971623484001E"]
}
```

In VSCode:

- Select **Fusion Setup (Gene’s iPhone)**  
- Press **Start Debugging**

The app will launch on your iPhone and display a tile for Fusion Mini.  
Tap **Connect** to issue a test request to `/endpoints`.

## Summary of Local Debugging Capabilities

Running locally gives you:

- Full REST API  
- BLE advertising and request handling  
- Real-time console logs  
- Audio upload, listing, and triggering  
- Simple testing without multipass, cluster gossip, or VRRP  
- Integration testing with a real iOS app over Bluetooth  

This mode is ideal for:

- BLE feature development  
- Flutter client integration  
- Debugging audio workflows  
- Iterating quickly without a distributed environment  
