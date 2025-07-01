# fusion-edge-gateway
This builds a client for Fusion devices to connect to a cloud(Xyte for now) and do analytics and monitoring.

# Basic Functions
1. Registers the device using the hardware key and cloud-id.
2. Saves the response in a file to use it to send telemetry.
3. Sends telemetry in a while loop with an interval.
4. Receives commands from the cloud and performs them.

# Build
- "make local" - to build for wsl for testing.
- "make release" - to build for fusion devices.

# Testing
- (tested)WSL - after "make local"
  - run ./build/fusion-edge-gateway
- (Not tested)Fusion devices - after "make release"
  - copy ./build/fusion-edge-gateway to /home/
  - chmod +x fusion-edge-gateway
  - run using ./fusion-edge-gateway

