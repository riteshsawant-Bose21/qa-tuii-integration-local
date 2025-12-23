# TCP Wall Controller Management System

A TCP-based wall controller management system for Fusion Server that enables real-time communication between wall controllers and the server infrastructure.

## Overview

This system provides:
- TCP server for wall controller connections on port 7950
- HTTP API endpoints for controller management 
- WebSocket integration for real-time event broadcasting (future)
- VIP-aware architecture for high availability (future)

## Features

### Core Functionality
- **TCP Server**: Accepts concurrent connections from wall controllers
- **Controller Registration**: Automatic registration/unregistration of controllers
- **HTTP API**: REST endpoints for controller management
- **Real-time Events**: WebSocket broadcasting for controller events
- **Synchronous Commands**: HTTP-to-TCP command execution with timeout

### Supported Operations
- List active controllers
- Execute wink commands
- Real-time event broadcasting (Winking, ReverseWinking)
- Automatic disconnect handling

## API Reference

### HTTP Endpoints

#### Get Active Controllers
```
GET /controllers
```
Returns a list of all currently connected and registered controllers.

**Response:**
```json
[
  {
    "id": "controller-1",
    "name": "Wall Controller 1",
    "address": "192.168.1.100", 
    "version": "1.0.0"
  }
]
```

#### Execute Wink Command (WIP)
```
GET /wink/{controller_id}
```
Triggers a synchronous wink command to the specified controller with a 300-second timeout.

### TCP Protocol

#### Controller Registration
When a controller connects, the server initiates identification:

**Server sends:**
```json
{
  "action": "identify",
  "payload": {}
}
```

**Controller responds:**
```json
{
  "action": "identify",
  "payload": {
    "id": "unique-controller-id",
    "name": "Controller Display Name", 
    "address": "controller-ip",
    "version": "1.0.0"
  }
}
```

#### Wink Command Flow
**Server sends:**
```json
{
  "action": "performWink",
  "payload": {}
}
```

**Controller responds (every 10 seconds during wink):**
```json
{
  "action": "Winking",
  "payload": {
    "id": "controller-1",
    "name": "Wall Controller 1",
    "address": "192.168.1.100", 
    "version": "1.0.0"
  }
}
```

### WebSocket Events

The following events are broadcasted to all WebSocket clients:
- `Winking` - Controller wink responses
- `ReverseWinking` - Controller-initiated wink events

## Connection Management

### Registration Process
1. Controller connects to TCP server on port 7950
2. Server sends identification request
3. Controller responds with registration details
4. Controller added to active list
5. Only registered and connected controllers appear in API responses

### Disconnection Handling
- Controllers are immediately removed from active list on disconnect
- No state persistence - reconnections treated as new registrations
- No heartbeat or keepalive mechanisms
- Duplicate connections replace previous connections



### Error Handling - TBD
- Malformed TCP messages: Log and ignore
- TCP write failures: Immediate controller disconnection
- Connection timeouts: Remove from active list
- No automatic retry mechanisms (fail-fast approach)

## Configuration

### Default Settings
- **TCP Port**: 7950

### Future Work
- [ ] VIP-aware architecture
- [ ] Enhanced commands (wink, reversewink, ip address setting)