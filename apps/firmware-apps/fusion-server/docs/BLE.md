# Local Development Build of `fusion-server` for Bluetooth Debugging

A local build of `fusion-server` can be used for developing and debugging a Bluetooth connection between a mobile device and the server. Instead of using the launch script to create virtualized Multipass instances of `fusion-server`, the server must be built for macOS and launched in local mode.

---

## Building for macOS

From the root of the `fusion-server` code repository, run:

```bash
make build-darwin-arm64
```

If you forget this target, you can list all available Make targets with:

```bash
make help
```

### Available Make Targets

```
Make targets:
 all                - Run deps and build
 build              - Build for current platform
 clean              - Clean build files
 run                - Build and run locally
 deps               - Download dependencies
 tidy               - Tidy go.mod
 fmt                - Format code
 vet                - Run go vet
 lint               - Run linter
 build-linux-amd64  - Build for Linux amd64
 build-linux-arm32  - Build for Linux ARM32
 build-linux-arm64  - Build for Linux ARM64
 build-darwin-arm64 - Build for macOS ARM64
 build-all          - Build for all platforms
```

> **Note:** Local mode disables some distributed features. It is ideal for BLE feature development and interactive debugging in VSCode or via GDB.

---

## Running the Local Binary

After a successful build, the macOS binary will be located at:

```
build/fusion-server_darwin_arm64
```

Launch the binary in local mode:

```bash
./build/fusion-server_darwin_arm64 --local
```

### Example Output

```bash
./build/fusion-server_darwin_arm64 --local
[fusion1] [INFO] [CLUSTER] Total members: 1
[fusion1] [INFO] [CLUSTER] Current cluster state:
[fusion1] [INFO] [CLUSTER] Node: fusion1, Address: 10.0.0.157:7946, Status: ALIVE
[fusion1] [INFO] BLE server initialized: B053 AD10
[fusion1] [INFO] UDP server listening on :7947
[fusion1] [INFO] Starting API server on :9090
[fusion1] [INFO] Starting API server on :8080
[fusion1] [INFO] fusion1 is ALIVE and RUNNING
[fusion1] [INFO] Version: 1.0.0-alpha.2 Commit: b46147f Build Time: 2025-05-23T04:06:07Z
```

> **Key Line:**  
> ```bash
> [fusion1] [INFO] BLE server initialized: B053 AD10
> ```

- `B053` is the **service identifier** being broadcast.  
- `AD10` is the **characteristic identifier** associated with the service.

---

## Verifying Bluetooth Broadcast with nRF Connect

You can use the **nRF Connect** mobile application to verify that the local `fusion-server` build is broadcasting over Bluetooth.

- **Download for iOS:**  
  [nRF Connect for Mobile](https://apps.apple.com/us/app/nrf-connect-for-mobile/id1054362403)

Once running, you should see an entry for **"Fusion Mini"** with the **B053** service listed in the detected Bluetooth devices.


## Flutter Application

Clone the repo located here: https://github.com/BoseProfessional/fusion-setup

This repo contains an example application that is able to make REST calls to 
fusion-server over a Bluetooth connection.

Make sure you have XCode installed. Flutter will use XCode to build the iOS target.

Review the [Flutter for iOS](https://docs.flutter.dev/get-started/install/macos/mobile-ios) document and make sure your system has been configured for iOS development.

Connect your iPhone to your Mac using a cable and then run `flutter devices` to list
the devices. You should see your device listed.

```bash
Found 3 connected devices:
  macOS (desktop)                 • macos                 • darwin-arm64   • macOS 14.6.1 23G93 darwin-arm64
  Mac Designed for iPad (desktop) • mac-designed-for-ipad • darwin         • macOS 14.6.1 23G93 darwin-arm64
  Chrome (web)                    • chrome                • web-javascript • Google Chrome 134.0.6998.89

Found 1 wirelessly connected device:
  Gene’s Phone (wireless) (mobile) • 00008101-000971623484001E • ios • iOS 18.5 22F76
```

You can hardcode an entry to your device in lauch.json like this:
```base
{
  "name": "Fusion Setup (Gene's iPhone)",
  "type": "dart",
  "request": "launch",
  "args": ["-d", "00008101-000971623484001E"]
}
```

From the Run and Debug tab in VSCode, select the "Fusion Setup (Generic Phone)",
or your specific phone if you added it, and press the green "Start Debugging" button.

The initial build and launch may take some time as packages and symbols may need
to be downloaded and installed.

Once the fusion-setup app launches on your iOS device, you should see a Fusion Mini
tile on the screen. You can tap the magnifying glass icon to scan again. Tap the Connect button
to connect to the device and make a call to /endpoints.
