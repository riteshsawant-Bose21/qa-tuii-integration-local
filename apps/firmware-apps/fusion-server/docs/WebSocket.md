# WebSocket API Quick Reference

This document describes the complete WebSocket protocol implementation for the Fusion Server, providing real-time device management with structured messaging.

## Overview

The WebSocket implementation provides:

- **Custom Protocol**: Simplified message format with structured status codes
- **Direct Connection**: No authentication or session management required
- **Device Management**: Core device operations via WebSocket messages
- **Pull-then-Push Pattern**: Request device data and automatically receive future updates
- **Subscription Management**: Subscribe/unsubscribe from device updates
- **Structured Error Handling**: Clear error responses with standardized codes
- **Health Monitoring**: Built-in ping/pong mechanism

## Architecture

### Core Components

1. **WebSocketHandler** (`handler_websocket.go`)
   - Message type routing (devices, device_by_id, update_device_info, ping)
   - Request/response processing with standardized format
   - Status code management and error handling

2. **FusionServer** (`server.go`)
   - WebSocket connection management
   - Welcome message handling
   - Connection lifecycle management

## Message Format

### Request Format

```json
{
  "id": "unique-request-id",     // Required: non-empty string for client requests
  "version": 1,                  // Protocol version (currently 1)
  "type": "message_type",        // Message type (see supported types below)
  "data": {}                     // Optional: message-specific data
}
```

### Response Format

```json
{
  "id": "request-id",            // Matches request ID, null for server-initiated messages
  "version": 1,                  // Protocol version
  "type": "response_type",       // Response type (devices, device, error, etc.)
  "code": 3000,                  // Status code (see status codes below)
  "status": "success",           // Status category (success, error, event)
  "message": "OK",               // Human-readable message
  "data": {},                    // Response payload
  "timestamp": "2026-02-28T08:09:07Z"  // Response timestamp
}
```

**Note**: Client requests must include a non-empty string `id`. Server-initiated messages (like push notifications) have `id: null`.

## Subscription Management

### Automatic Subscription
The WebSocket API uses a **Pull-then-Push** pattern where requesting device data automatically subscribes the client to future updates:

1. **devices** request → subscribes to all device updates
2. **device_by_id** request → subscribes to all device updates (cluster-wide)


**Push notifications work correctly cluster-wide** - all WebSocket clients receive real-time updates when any device in the cluster changes, regardless of which cluster node they're connected to or which node hosts the device.

1. **`devices`** - List all devices
   ```json
   {
     "id": "req-001",
     "version": 1,
     "type": "devices"
   }
   ```

2. **`device_by_id`** - Get specific device (searches all cluster nodes)
   ```json
   {
     "id": "req-002", 
     "version": 1,
     "type": "device_by_id",
     "data": {
       "device_id": "fusion_dgqpf3lhvrww_kcig_instance"
     }
   }
   ```

3. **`update_device_info`** - Update device information (uses DevicePatch structure)
   ```json
   {
     "id": "req-003",
     "version": 1, 
     "type": "update_device_info",
     "data": {
       "device_id": "fusion-1",
       "id": "new-device-id",
       "name": "New Device Name",
       "location": "Rack A",
       "model_name": "FM6",
       "is_claimed": true
     }
   }
   ```
   
   **Note**: All fields except `device_id` are optional. Only provided fields will be updated (partial update support).
   **Structure**: Uses the same `DevicePatch` struct as the REST API PATCH `/devices/{id}` endpoint for consistency.

### System Operations

4. **`ping`** - Health check (responds with `pong`)
   ```json
   {
     "id": "req-ping",
     "version": 1,
     "type": "ping"
   }
   ```

5. **`config`** - Get current configuration and auto-subscribe to `config_update`
    ```json
    {
       "id": "req-config",
       "version": 1,
       "type": "config"
    }
    ```

6. **`patch_config`** - Apply partial configuration patch (same semantics as HTTP PATCH)
    ```json
    {
       "id": "req-patch-config",
       "version": 1,
       "type": "patch_config",
       "data": {
          "zones": {
             "zone_a": {
                "volume": 75
             }
          }
       }
    }
    ```
7. **`unsubscribe_config`** - Unsubscribe from configuration update events
    ```json
    {
       "id": "req-unsub-config",
       "version": 1,
       "type": "unsubscribe_config"
    }
    ```

8. **`unsubscribe_devices`** - Unsubscribe from device updates
   ```json
   {
     "id": "req-unsub",
     "version": 1,
     "type": "unsubscribe_devices"
   }
   ```

9. **`start_update`** - Trigger coordinated software update across cluster
   ```json
   {
     "id": "sw-update-001", 
     "version": 1,
     "type": "start_update"
   }
   ```

   **Execution Flow**:
   - Broadcasts cluster message to all nodes via gossip protocol
   - Each node's delegate receives the message and executes `systemctl start swupdate-ota-install.service`
   - Uses reliable cluster messaging for coordination across all cluster members
   - After the update starts, the server pushes real-time `update_progress` events to all WebSocket clients (see [Software Update Progress Push Format](#software-update-progress-push-format))

   **Response**:
   ```json
   {
     "id": "sw-update-001",
     "version": 1,
     "type": "start_update",
     "code": 3005,
     "status": "success",
     "message": "Software update broadcasted to all cluster nodes",
     "data": {
       "action": "broadcast_cluster",
       "nodes": [...]
     },
     "timestamp": "2026-04-01T10:15:30Z"
   }
   ```

10. **`sw_update_info`** - Read `/etc/swupdate-status` from **all cluster nodes** and return the aggregated results
    ```json
    {
      "id": "req-sw-info-001",
      "version": 1,
      "type": "sw_update_info"
    }
    ```

    **Response**:
    ```json
    {
      "id": "req-sw-info-001",
      "version": 1,
      "type": "sw_update_info",
      "code": 3000,
      "status": "success",
      "message": "OK",
      "data": [
        {
          "serial_number": "SN123456789",
          "current_bundle_version": "2.3.1",
          "previous_bundle_version": "2.3.0",
          "mount": "rootfsB",
          "previous_mount": "rootfsA",
          "status": "SUCCESS",
          "current_state": "UPDATED",
          "boot_partition": "B",
          "previous_boot_partition": "A",
          "error": "",
          "updated_at": "2026-04-06T10:15:22Z"
        },
        {
          "serial_number": "SN987654321",
          "current_bundle_version": "2.3.1",
          "previous_bundle_version": "2.3.0",
          "mount": "rootfsB",
          "previous_mount": "rootfsA",
          "status": "SUCCESS",
          "current_state": "UPDATED",
          "boot_partition": "B",
          "previous_boot_partition": "A",
          "error": "",
          "updated_at": "2026-04-06T10:15:30Z"
        }
      ],
      "timestamp": "2026-04-06T10:16:00Z"
    }
    ```

    **Data field**: An array of `SwUpdateInfo` objects, one per cluster node. Each object reflects the contents of `/etc/swupdate-status` on that node. If the file cannot be read on a node, an empty object is included so the array always has one entry per cluster member.

    | Field | Type | Description |
    |-------|------|-------------|
    | `serial_number` | string | Device serial number |
    | `current_bundle_version` | string | Currently running firmware bundle version |
    | `previous_bundle_version` | string | Previously installed firmware bundle version |
    | `mount` | string | Current active rootfs mount point |
    | `previous_mount` | string | Previously active rootfs mount point |
    | `status` | string | Last swupdate operation status (e.g. `SUCCESS`, `FAILED`) |
    | `current_state` | string | Current device state (e.g. `UPDATED`) |
    | `boot_partition` | string | Active boot partition (e.g. `A` or `B`) |
    | `previous_boot_partition` | string | Previously active boot partition |
    | `error` | string | Error message from last swupdate run, empty if none |
    | `updated_at` | string | RFC3339 timestamp of the last update |

11. **`list_sw_update_files`** - List OTA bundles from **all cluster nodes** (de-duplicated union by filename)
    ```json
    {
      "id": "req-list-001",
      "version": 1,
      "type": "list_sw_update_files"
    }
    ```

    **Response**:
    ```json
    {
      "id": "req-list-001",
      "version": 1,
      "type": "list_sw_update_files",
      "code": 3000,
      "status": "success",
      "message": "OK",
      "data": [
        {
          "filename": "bundle_v2.3.1.swu",
          "checksum": "a1b2c3d4e5f6...",
          "size_bytes": 15728640,
          "uploaded": "2026-04-05T14:22:00Z",
          "source_ip": "192.168.2.100"
        },
        {
          "filename": "bundle_v2.3.2.swu",
          "checksum": "f6e5d4c3b2a1...",
          "size_bytes": 15831552,
          "uploaded": "2026-04-06T09:10:00Z",
          "source_ip": "192.168.2.101"
        }
      ],
      "timestamp": "2026-04-06T10:20:00Z"
    }
    ```

    **Data field**: An array of `SoftwareUpdateSync` objects representing every OTA bundle present across the cluster.

    | Field | Type | Description |
    |-------|------|-------------|
    | `filename` | string | Bundle filename (e.g. `bundle_v2.3.1.swu`) |
    | `checksum` | string | SHA-256 hex digest of the bundle file |
    | `size_bytes` | int64 | File size in bytes |
    | `uploaded` | string | RFC3339 UTC timestamp of when the file was stored |
    | `source_ip` | string | IP address of the node that holds the file |

## Pull-then-Push Pattern

The device APIs implement a **Pull-then-Push** pattern for real-time updates:

1. **Pull Phase**: Client requests device data (`devices` or `device_by_id`)
2. **Response**: Server responds with current device data
3. **Auto-Subscribe**: Client is automatically subscribed to device updates
4. **Push Phase**: Server pushes future device changes to subscribed clients


### Subscription Management:
- **Auto-Subscribe**: Requesting `devices` or `device_by_id` automatically subscribes the client
- **Auto-Subscribe (Config)**: Requesting `config` automatically subscribes the client
- **Manual Unsubscribe**: Send `unsubscribe_devices` message to stop receiving updates
- **Config Unsubscribe**: Send `unsubscribe_config` to stop receiving config updates
- **Connection Cleanup**: Subscriptions are automatically removed when connection closes

## Status Codes

### Standard WebSocket Close Codes (1xxx)
- `1000` - **Normal Closure**: Connection closed normally
- `1002` - **Protocol Error**: Protocol error during handshake
- `1011` - **Internal Error**: Internal server error (connection close only)

### Application Success Codes (3xxx)
- `3000` - **OK**: Request processed successfully
- `3001` - **Updated**: Resource updated successfully
- `3002` - **Connected**: Connection established (welcome message)
- `3003` - **Pong**: Response to ping request
- `3004` - **Event Push**: Push notifications — device updates (`device_update`) and software update progress (`update_progress`)
- `3005` - **Update Started**: Software update triggered successfully

### Application Client Error Codes (4xxx)
- `4000` - **Invalid JSON**: Malformed JSON message
- `4001` - **Missing Field**: Required field missing in request
- `4002` - **Invalid Type**: Unsupported message type
- `4003` - **Invalid Payload**: Invalid request payload data
- `4004` - **Missing Device ID**: Device ID missing in request
- `4005` - **Device Not Found**: Specified device does not exist
- `4006` - **Update Failed**: Update operation failed
- `4500` - **Application Error**: General application error

## Error Handling

### Error Response Structure
```json
{
  "id": null,                    // null for server errors, matches request ID for client errors
  "version": 1,                  // Protocol version
  "type": "error",               // Always "error" for error responses
  "code": 4000,                  // Error code (see status codes above)
  "status": "error",             // Always "error" for error responses
  "message": "Invalid JSON format",  // Human-readable error description
  "data": null,                  // Always null for errors
  "timestamp": "2026-02-28T08:09:07Z"  // Error timestamp
}
```

### Common Error Scenarios

1. **Invalid Message Format**
   ```json
   {
     "id": null,
     "version": 1,
     "type": "error", 
     "code": 4000,
     "status": "error",
     "message": "Invalid JSON format",
     "data": null,
     "timestamp": "2026-02-28T08:09:07Z"
   }
   ```

2. **JSON Comments Error (Code 4003)**
    ```json
    {
      "id": "req-123",
      "version": 1,
      "type": "error",
      "code": 4003,
      "status": "error",
      "message": "Invalid data payload",
      "data": null,
      "timestamp": "2026-03-01T01:07:29Z"
    }
    ```
    **Cause**: Including JSON comments like `// Comment` or `/* Comment */` in your message. JSON specification does not support comments.
    **Solution**: Remove all comments from your JSON payload.

3. **Unsupported Message Type**
   ```json
   {
     "id": "req-123",
     "version": 1,
     "type": "error",
     "code": 4002, 
     "status": "error",
     "message": "Unknown message type: invalid_type",
     "data": null,
     "timestamp": "2026-02-28T08:09:07Z"
   }
   ```

4. **Missing Required Fields**
   ```json
   {
     "id": "req-123",
     "version": 1,
     "type": "error",
     "code": 4001,
     "status": "error", 
     "message": "Missing required field: id",
     "data": null,
     "timestamp": "2026-02-28T08:09:07Z"
   }
   ```

5. **Device Not Found**
   ```json
   {
     "id": "req-123",
     "version": 1,
     "type": "error",
     "code": 4005,
     "status": "error", 
     "message": "Device not found: fusion-99",
     "data": null,
     "timestamp": "2026-02-28T08:09:07Z"
   }
   ```

6. **Missing Device ID**
   ```json
   {
     "id": "req-123",
     "version": 1,
     "type": "error",
     "code": 4004,
     "status": "error", 
     "message": "Missing device_id in payload",
     "data": null,
     "timestamp": "2026-02-28T08:09:07Z"
   }
   ```

### Push Notification Format

When devices are updated anywhere in the cluster, all subscribed WebSocket clients automatically receive push notifications via their connected node (typically VIP in distributed deployments):

```json
{
  "id": null,
  "version": 1,
  "type": "device_update",
  "code": 3004,
  "status": "event",
  "message": "Device fusion-1 info_updated",
  "data": {
      "address": "192.168.2.100",
      "id": "fusion-1",
      "name": "Updated Device Name",
      "location": "Building A - Lobby",
  },
  "timestamp": "2026-02-28T08:20:57Z"
}
```

### Software Update Progress Push Format

When a software update is running, the server pushes real-time progress from **all cluster nodes** in a single message. Clients do not need to subscribe — progress is broadcast to all connected WebSocket clients automatically.

```json
{
  "id": null,
  "version": 1,
  "type": "update_progress",
  "code": 3004,
  "status": "event",
  "message": "System notification: software_update_progress",
  "data": {
    "node-1": {
      "update_state": "IN_PROGRESS",
      "step": "2/4",
      "current_task": "rootfs.ext4",
      "progress": "65",
      "node": "node-1",
      "handler": "raw",
      "timestamp": "2026-04-01T10:16:05Z",
      "serial_number": "0123456789abcdef"
    },
    "node-2": {
      "update_state": "SUCCESS",
      "step": "4/4",
      "current_task": "rootfs.ext4",
      "progress": "100",
      "node": "node-2",
      "handler": "raw",
      "timestamp": "2026-04-01T10:16:42Z",
      "serial_number": "fedcba9876543210"
    }
  },
  "timestamp": "2026-04-01T10:16:45Z"
}
```

**Data field**: A `map[string]object` keyed by **node name**. Each value is a `SoftwareUpdateProgressResponse` with the following fields:

| Field | Type | Description |
|-------|------|-------------|
| `update_state` | string | Current update state (see enum below) |
| `step` | string | Current step as `"current/total"` (e.g. `"2/4"`) |
| `current_task` | string | Active swupdate image/task name |
| `progress` | string | Percent complete for the current step (`"0"`–`"100"`) |
| `node` | string | Node name this progress belongs to |
| `handler` | string | swupdate handler name (e.g. `"raw"`, `"shellscript"`) |
| `timestamp` | string | RFC3339 timestamp of the progress event |
| `serial_number` | string | Serial number of the node |

**`update_state` enum values**:

| Value | Meaning | Terminal |
|-------|---------|----------|
| `IDLE` | No update in progress | — |
| `STARTING` | Update service starting | — |
| `IN_PROGRESS` | Update actively running | — |
| `SUCCESS` | Update completed successfully | — |
| `FAILED` | Update encountered an error | ✅ stops monitoring |
| `DOWNLOADING` | Downloading update bundle | — |
| `COMPLETED` | Update fully done — **last observed state in normal flow** | ✅ stops monitoring |
| `SUBPROCESS` | Running a subprocess step | — |
| `PROGRESS` | General progress tick | — |
| `UNKNOWN` | Unrecognised status code | — |

> **Monitoring lifecycle**: progress monitoring starts automatically on `start_update`. In normal operation the full sequence ends with `SUCCESS` followed by `COMPLETED` — monitoring stops on `COMPLETED`. On error, monitoring stops on `FAILED`. Clients should wait for `COMPLETED` (or `FAILED`) as the definitive final state.

## Configuration

The WebSocket server uses basic configuration:

- **Port**: 8080 (default)
- **Endpoint**: `/ws`
- **Protocol**: Custom message format (version 1)
- **Connection**: Direct connection without authentication
- **Message Size**: Standard WebSocket limits apply
- **Cluster Mode**: Supports VIP-centric deployments where clients connect only to VIP but receive updates from all nodes
- **Gossip Protocol**: Automatic cross-node device update propagation via memberlist

## Testing

### Unit Tests

Multipass
```bash
cd fusion/test
go test -v websocket_test.go
```

Local 
```bash
cd fusion/test
FUSION_TEST_LOCAL=1 go test -v ./test/websocket_test.go -timeout 60s
```

### Test Coverage
- Connection establishment and welcome message
- Device listing and retrieval operations  
- Ping/pong health check mechanism
- Error handling for invalid messages and missing data
- Message format validation

### Example Tests
- `TestWebsocketConnect` - Basic connection and welcome message test
- `TestWebsocketDevicesRequest` - Device listing test
- `TestWebsocketDeviceByID` - Specific device retrieval test
- `TestWebsocketPing` - Health check test
- `TestWebsocketInvalidRequest` - Error handling test
- `TestSoftwareUpdateTriggerViaWebSocket` - Software update trigger via WebSocket (expects code `3005`)
- `TestSoftwareUpdateTriggerUnknownType` - Invalid type error handling (expects code `4002`)
- `TestSoftwareUpdateProgressReceivedAfterTrigger` - Progress push after trigger (requires `FUSION_SWUPDATE_TEST=1`)
- `TestSoftwareUpdateProgressMessageFormat` - Progress message format validation (requires `FUSION_SWUPDATE_TEST=1`)

> **Note**: Tests that require the swupdate Unix socket (`/tmp/swupdateprog`) are guarded behind the
> `FUSION_SWUPDATE_TEST=1` environment variable. In Multipass or CI environments without swupdate,
> these tests are automatically skipped unless the variable is set.

## Best Practices

### Client Implementation
1. **Connection Management**
   - Implement reconnection logic with exponential backoff
   - Handle connection drops gracefully
   - Monitor connection state and attempt reconnect

2. **Message Handling**
   - Always include unique request IDs for correlation
   - Set appropriate version field (currently 1)
   - Validate message structure before sending
   - Implement timeout handling for requests

3. **Error Handling**
   - Check status codes in responses (3xxx = success, 4xxx = error)
   - Parse error responses to understand failure reasons
   - Implement retry logic for transient errors (4xxx codes)
   - Log errors with request IDs for debugging

4. **Performance Considerations**
   - Use request correlation to avoid blocking
   - Implement proper cleanup on disconnect
   - Handle device list caching appropriately
   - Use ping/pong for connection health monitoring

## Troubleshooting

### Common Issues

1. **Connection Refused**
   - Check server is running on port 8080
   - Verify WebSocket endpoint `/ws` is accessible
   - Check firewall settings and network connectivity

2. **Message Format Errors**
   - Ensure message includes `version: 1`
   - Include required `type` field with valid message type
   - Verify JSON is well-formed and properly escaped
   - **Remove all JSON comments** - JSON does not support `//` or `/* */` comments
   - Check that `data` field is included when required

3. **Invalid Message Type**
   - Use supported types: `devices`, `device_by_id`, `update_device_info`, `ping`, `config`, `patch_config`, `unsubscribe_config`, `unsubscribe_devices`, `start_update`, `sw_update_info`, `list_sw_update_files`
   - Check for typos in message type names
   - Verify protocol version compatibility

4. **Device Operations Failed**
   - Ensure device IDs are valid and exist in system
   - Check that required data fields are provided
   - Verify device_id format in requests

### Debugging

1. **Enable Verbose Logging**
   ```bash
   ./fusion-server --verbose
   ```

2. **Test WebSocket Connection**
   ```bash
   # Install wscat if needed
   npm install -g wscat
   
   # Test connection
   wscat -c ws://localhost:8080/ws
   
   # Send test message
   {"id":"test-001","version":1,"type":"ping"}
   ```

3. **Validate Message Format**
    // Minimum required fields for devices request
    ```json
    {
        "id": "test-001",
        "version": 1,
        "type": "devices"
    }
    ```
   
   // Device by ID request format
    ```json
    {
        "id": "test-002", 
        "version": 1,
        "type": "device_by_id",
        "data": {
        "device_id": "fusion-1"
        }
    }
    ```



### Status Code Reference

| Code | Category | Description |
|------|----------|-------------|
| **WebSocket Close Codes** | | |
| 1000 | Normal Closure | Connection closed normally |
| 1002 | Protocol Error | Protocol error during handshake |
| 1011 | Internal Error | Internal server error (close only) |
| **Application Success Codes** | | |
| 3000 | Success | Request processed successfully |
| 3001 | Success | Resource updated successfully |
| 3002 | Success | Connection established |
| 3003 | Success | Pong response to ping |
| 3004 | Event | Push notification (device update or software update progress) |
| 3005 | Success | Software update triggered successfully |
| **Application Error Codes** | | |
| 4000 | Client Error | Invalid JSON message |
| 4001 | Client Error | Missing required field |
| 4002 | Client Error | Invalid message type |
| 4003 | Client Error | Invalid request payload |
| 4004 | Client Error | Missing device ID |
| 4005 | Resource Error | Device not found |
| 4006 | Client Error | Update operation failed |
| 4500 | Application Error | General application error |

## Complete API Reference

### Request Types

| Type | Description | Auto-Subscribe | Data Required |
|------|-------------|----------------|--------------|
| `devices` | List all cluster devices | ✅ Yes | None |
| `device_by_id` | Get specific device | ✅ Yes | `device_id` |
| `config` | Get current configuration | ✅ Yes | None |
| `patch_config` | Patch configuration state | ❌ No | Partial config object |
| `update_device_info` | Update device info | ❌ No* | `device_id` + patch fields |
| `unsubscribe_config` | Stop config updates | ❌ No | None |
| `ping` | Health check | ❌ No | None |
| `unsubscribe_devices` | Stop device updates | ❌ No | None |
| `start_update` | Trigger software update | ❌ No | None |
| `sw_update_info` | Read `/etc/swupdate-status` from all nodes | ❌ No | None |
| `list_sw_update_files` | List OTA bundles from all nodes (de-duplicated union) | ❌ No | None |

*Server-initiated push types (cannot be requested by client)*

| Type | Description | Code | Condition |
|------|-------------|------|-----------|
| `device_update` | Device changed | 3004 | Any subscribed device changes |
| `update_progress` | Software update progress | 3004 | Software update running on any cluster node |

*Update operations trigger push notifications to all subscribed clients

### Response Types

| Type | When Sent | Status Code | Description |
|------|-----------|-------------|-------------|
| `welcome` | Connection established | 3002 | Welcome message with server info |
| `devices` | Response to devices request | 3000 | All cluster devices |
| `device_by_id` | Response to device lookup | 3000 | Single device info |
| `config` | Response to config request | 3000 | Current full configuration |
| `patch_config` | Response to patch request | 3000/3001 | No-op or patch applied |
| `update_device_info` | Response to update request | 3001 | Update confirmation |
| `device_update` | Push notification | 3004 | Real-time device change |
| `config_update` | Push notification | 3001 | Real-time configuration change |
| `unsubscribe_config` | Response to unsubscribe | 3000 | Config unsubscribe confirmation |
| `unsubscribe_devices` | Response to unsubscribe | 3000 | Unsubscribe confirmation |
| `start_update` | Response to update trigger | 3005 | Software update coordination |
| `update_progress` | Push notification | 3004 | Real-time per-node software update progress |
| `sw_update_info` | Response to sw_update_info request | 3000 | Array of `/etc/swupdate-status` contents from all cluster nodes |
| `list_sw_update_files` | Response to list_sw_update_files request | 3000 | De-duplicated union of OTA bundles from all cluster nodes |
| `pong` | Response to ping | 3003 | Health check response |
| `error` | Request processing error | 4xxx | Error details |
