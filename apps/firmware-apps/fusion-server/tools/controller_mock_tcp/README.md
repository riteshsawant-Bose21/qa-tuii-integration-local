# Wall Controller Simulator

A C++ TCP client simulator that emulates a wall controller device for testing the Fusion Server's TCP wall controller management system.

## Overview

This simulator connects to the Fusion Server TCP endpoint (default port 7950) and implements the JSON-based protocol for wall controller communication. It's designed for testing and development purposes to validate the server's controller management functionality without requiring physical hardware.

## Features

- **TCP Connection**: Connects to Fusion Server via TCP socket
- **JSON Protocol**: Implements the complete wall controller communication protocol
- **Device Identification**: Responds to server identification requests
- **Wink Commands**: Handles and responds to wink commands with proper timing
- **Logging**: Comprehensive logging with timestamps for debugging
- **Signal Handling**: Graceful shutdown on Ctrl+C or SIGTERM
- **Configurable**: Command-line parameters for controller ID, host, and port

## Protocol Implementation

### Identification Flow
1. **Server Request**: `{"action": "identify", "payload": {}}`
2. **Controller Response**: 
   ```json
   {
     "action": "identity",
     "payload": {
       "id": "WC001",
       "deviceType": "WallController", 
       "firmwareVersion": "1.0.0"
     }
   }
   ```

### Wink Command Flow {WIP}
1. **Server Request**: `{"action": "performWink", "payload": {"duration": 5000, "timestamp": 123456}}`
2. **Controller Start Response**: `{"action": "winkResponse", "payload": {"status": "starting"}}`
3. **Controller Completion Response**: `{"action": "winkResponse", "payload": {"status": "done"}}`

## Building

### Prerequisites
- C++17 compatible compiler (g++ recommended)
- Standard C++ libraries (no external dependencies)
- POSIX-compliant system (Linux, macOS)

### Build Commands

Using the provided Makefile:
```bash
# Build the simulator
make -f Makefile.wall_controller

## Usage
### Basic Usage
```bash
# Run with parameters (ID, VIP, 7950)
./wall_controller_simulator WC004 192.168.2.100 7950
```

### Command Line Parameters
1. **Controller ID** (optional): Unique identifier for the controller (default: "WC001")
2. **Host** (optional): Fusion Server hostname or IP address (default: "localhost")  
3. **Port** (optional): TCP port number (default: 7950)

### Example Sessions

**Single Controller:**
```bash
./wall_controller_simulator WC001 localhost 7950
```

**Multiple Controllers (separate terminals):**
```bash
# Terminal 1
./wall_controller_simulator WC001 192.168.2.100 7950

# Terminal 2  
./wall_controller_simulator WC002 192.168.2.100 7950

# Terminal 3
./wall_controller_simulator WC003 192.168.2.100 7950
```


## Testing Integration

### With Fusion Server
1. Start Fusion Server with TCP controller support enabled
2. Run the simulator pointing to the server's IP and port
3. Verify controller appears in `GET /controllers` API response
<!-- 4. Test wink functionality with `GET /wink/{controller_id}` API call -->
<!-- 5. Monitor WebSocket events for real-time controller messages -->
