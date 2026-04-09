# Software Update Management

Fusion Server provides REST API endpoints for uploading, downloading, and managing Software Update files across the cluster. This document covers the Software Update management functionality and API usage.

## Overview

The Software Update management system allows:
- **Secure Upload**: Upload `.swu` Software Update bundles with SHA-256 checksum validation
- **Cluster Distribution**: Automatic distribution to all cluster members via gossip protocol
- **Version Management**: Duplicate detection and version control

## Architecture

### File Storage
- **Storage Path**: `/mnt/ota/` - Primary storage for validated Software Update files
- **Staging Process**: Files are staged directly in `/mnt/ota/` as `.part` files during upload
- **Atomic Deployment**: Simple rename operation from `.part` to final filename after validation

### Workflow
1. **Upload**: Receive multipart form data with Software Update file and checksum
2. **Staging**: Stream file directly to `/mnt/ota/<filename>.part` 
3. **Validation**: Calculate and verify SHA-256 checksum during streaming
4. **Duplicate Check**: Verify file content isn't already present (same or different filename)
5. **Deployment**: Atomic rename from `.part` to final filename
6. **Cluster Sync Tracking**: Generate unique sync ID and track cluster-wide distribution
7. **Distribution**: Broadcast `software_update_available` gossip message to cluster
8. **Automatic Sync**: Follower nodes download from VIP automatically
9. **Sync Completion**: Wait for acknowledgments from all cluster members before responding

## API Endpoints

### POST /softwareUpdate/upload

Upload a Software Update bundle (.swu file) with checksum validation.

**Request Format**:
```bash
curl -X POST http://localhost:8080/softwareUpdate/upload \
  -F "bundle=@bundle_v1.2.3.swu" \
  -F "checksum=abc123def456..."
```

**Multipart Form Fields**:
- `bundle` (required): The Software Update bundle as a `.swu` file
- `checksum` (required): Expected SHA-256 hex digest (64 characters)

**Response** (201 Created):
```json
{
  "filename": "bundle_v1.2.3.swu",
  "checksum": "abc123def456...",
  "size_bytes": 15728640,
  "uploaded": "2026-03-26T17:30:00Z"
}
```

**Error Responses**:
- `400 Bad Request`: Missing fields, invalid file type, or checksum mismatch
- `409 Conflict`: File already exists with same checksum
- `413 Request Entity Too Large`: File exceeds 300MB limit
- `507 Insufficient Storage`: Not enough disk space
- `408 Request Timeout`: Cluster sync did not complete within timeout

### GET /softwareUpdate/download/{filename}

Download a specific Software update file.

**Request**:
```bash
curl -O http://localhost:8080/softwareUpdate/download/bundle_v1.2.3.swu
```

**Response**: Binary Software Update file with appropriate headers:
- `Content-Type: application/octet-stream`
- `Content-Disposition: attachment; filename="bundle_v1.2.3.swu"`
- `Content-Length: <file-size>`

### GET /softwareUpdate/list

List all available software update files.

**Request**:
```bash
curl http://localhost:8080/softwareUpdate/list
```

**Response**:
```json
[
  {
    "filename": "bundle_v1.2.3.swu",
    "checksum": "abc123def456...",
    "size_bytes": 15728640,
    "uploaded": "2026-03-26T17:30:00Z",
    "source_ip": "192.168.1.100"
  },
  {
    "filename": "bundle_v1.2.4.swu", 
    "checksum": "def456abc123...",
    "size_bytes": 15831552,
    "uploaded": "2026-03-26T18:15:00Z",
    "source_ip": "192.168.1.100"
  }
]
```

## Software Update Execution

Once software update files are uploaded and distributed across the cluster, they can be executed using coordinated cluster mechanisms.

### Execution Methods

#### WebSocket Trigger (Recommended)

**Message Format**:
```json
{
  "id": "sw-update-001",
  "version": 1,
  "type": "start_update"
}
```

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

#### REST API Trigger

**Public Endpoint** (Cluster Coordination):
```bash
curl -X POST http://localhost:8080/cluster/software-update
```

**Admin Endpoint** (Local Node Only):
```bash  
curl -X POST http://localhost:9090/cluster/software-update
```

### Execution Architecture

**WebSocket Trigger**: Uses cluster messaging via gossip protocol:
1. **Message Broadcast**: Send `NotifyOpSoftwareUpdate` message to all cluster nodes
2. **Delegate Processing**: Each node's `ClusterDelegate.handleSoftwareUpdate()` receives the message
3. **Service Execution**: Each delegate executes `systemctl start swupdate-ota-install.service` locally
4. **Reliable Delivery**: Gossip protocol ensures all active nodes receive the trigger

**REST API Trigger**: Uses "remote-first, local-last" HTTP coordination pattern:

1. **Remote Nodes First**: Trigger `systemctl start swupdate-ota-install.service` on all remote cluster nodes
2. **Initiator Last**: Execute software update on the initiating node after confirming all remotes started
3. **Ordered Execution**: Ensures the coordination node remains available to orchestrate the entire process
4. **Graceful Coordination**: Prevents cluster partitioning during the update process

**Service Integration**:
- **Service Name**: `swupdate-ota-install.service`
- **Execution**: Each node executes the systemctl command locally via delegate
- **Cross-Platform**: Supports both Linux (systemctl) and development environments
- **Local Mode**: Skips execution when `appConfig.Local` is enabled for development

### Status Codes

| Code | Category | Description |
|------|----------|-------------|
| `3005` | Success | Software update started successfully |
| `4500` | Error | Failed to coordinate software update |
| `5000` | Server Error | Internal coordination error |

### Real-Time Progress Push

Once a software update starts, the server broadcasts real-time progress events to **all connected WebSocket clients** automatically. No subscription is required. Each push message contains a snapshot of the current progress for **every cluster node** in a single message.

**Message type**: `update_progress`  
**Code**: `3004` (shared event push code)

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

The `data` field is a `map[string]object` keyed by **node name**. Each value contains:

| Field | Type | Description |
|-------|------|-------------|
| `update_state` | string | Current status: `IDLE`, `STARTING`, `IN_PROGRESS`, `SUCCESS`, `FAILED`, `DOWNLOADING`, `COMPLETED`, `SUBPROCESS`, `PROGRESS`, `UNKNOWN` |
| `step` | string | Current step as `"current/total"` (e.g. `"2/4"`) |
| `current_task` | string | Active swupdate image name |
| `progress` | string | Percent complete for the current step |
| `node` | string | Node name |
| `handler` | string | swupdate handler (e.g. `"raw"`, `"shellscript"`) |
| `timestamp` | string | RFC3339 timestamp of the event |
| `serial_number` | string | Node serial number |

**Progress flow** (gossip integration):

1. swupdate daemon writes progress to unix socket `/tmp/swupdateprog` on each node
2. Hub reads the socket, stores progress keyed by node name, and gossips a **single-node** `NotifyOpSoftwareUpdateProgress` message to peer nodes (lean payload — no aggregated map)
3. Each receiving node stores the incoming progress in its own per-node map
4. Before pushing to local WebSocket clients, each node aggregates its full per-node map into the `update_progress` message
5. VIP (and any node with connected WebSocket clients) broadcasts the aggregated `update_progress` push

**Progress monitoring lifecycle**:

- Monitoring starts automatically when a `NotifyOpSoftwareUpdate` trigger is processed on the local node
- Monitoring stops on `COMPLETED` (swupdate `DONE`) in the normal success path, or on `FAILED` in the error path
- The full observable sequence in normal operation is: `STARTING → DOWNLOADING → IN_PROGRESS → ... → SUCCESS → COMPLETED`
- Clients should treat `COMPLETED` as the definitive end-of-update signal
- This prevents the monitoring goroutine from running indefinitely or producing error log spam after the update socket closes

## Usage Examples

### Upload New Software Update Upload

1. **Calculate checksum**:
   ```bash
   sha256sum bundle_v1.2.3.swu
   abc123def456abc123def456abc123def456abc123def456abc123def456abc123
   ```

2. **Upload with checksum**:
   ```bash
   curl -X POST http://localhost:8080/softwareUpdate/upload \
     -F "bundle=@bundle_v1.2.3.swu" \
     -F "checksum=abc123def456abc123def456abc123def456abc123def456abc123def456abc123"
   ```

3. **Verify upload**:
   ```bash
   curl http://localhost:8080/softwareUpdate/list | jq '.[] | select(.filename=="bundle_v1.2.3.swu")'
   ```

### Download Existing Software Update

```bash
# List available Software Update
curl http://localhost:8080/softwareUpdate/list

# Download specific version
curl -O http://localhost:8080/softwareUpdate/download/softwareUpdate_v1.2.3.swu
```

### Cluster Distribution

When a softwareUpdate file is uploaded to the VIP node:

1. **File is stored** in `/mnt/ota/` on the VIP node
2. **Gossip message** is broadcast with softwareUpdate metadata
3. **Follower nodes** automatically download from VIP via `/softwareUpdate/download/{filename}`
4. **All nodes** maintain synchronized copies in their `/mnt/ota/` directories

## File Validation

### Supported Formats
- **Extension**: Only `.swu` files are accepted (case-insensitive)
- **Size Limit**: Maximum 300MB per file
- **Naming**: Filenames are sanitized using `filepath.Base()`

### Checksum Validation
- **Algorithm**: SHA-256 
- **Format**: 64-character hexadecimal string
- **Timing**: Calculated during streaming upload (memory efficient)
- **Verification**: Must match provided checksum exactly (case-insensitive)

### Duplicate Detection
- **Same File**: Rejected if identical filename and checksum exist
- **Cross-filename**: Rejected if same content exists under different filename
- **Version Updates**: Allowed if same filename but different checksum

## Storage Management

### Directory Structure
```
/mnt/ota/
├── bundle_v1.2.3.swu           # Validated bundle file
├── bundle_v1.2.4.swu           # Another version
└── temp_upload.swu.part           # Temporary file (cleaned up)
```

### Cleanup
- `.part` files are automatically cleaned up as part of the upload processing (e.g. during `processSoftwareUpdateStream`)
- Failed uploads are cleaned up by the upload handler and leave no persistent artifacts
- Stale temporary files are opportunistically removed during subsequent uploads

### Disk Space
- **Buffer**: 100MB minimum free space maintained
- **Validation**: Checked before starting upload
- **Error Handling**: Upload rejected if insufficient space

## Security Considerations

### Integrity
- **Checksum verification** prevents corruption and tampering
- **Atomic operations** ensure consistent state
- **Filename sanitization** prevents directory traversal

### Access Control
- **Network-based**: Restrict access to softwareUpdate endpoints via firewall
- **File permissions**: `/mnt/ota/` directory should have appropriate ownership
- **Cluster security**: Use private networks for cluster communication

### Validation
- **File type enforcement**: Only `.swu` extensions accepted
- **Size limits**: 300MB maximum prevents resource exhaustion
- **Content verification**: SHA-256 ensures file integrity
- **Sentinel Error Types**: Type-safe error handling with `errors.Is()` for robust validation
- **Field Requirements**: Bundle file and checksum field validation with specific error types

## Troubleshooting

### Upload Failures

**"Missing bundle field"**:
```bash
# Incorrect - missing file field
curl -F "checksum=abc123" http://localhost:8080/softwareUpdate/upload

# Correct - include bundle file
curl -F "bundle=@file.swu" -F "checksum=abc123" http://localhost:8080/softwareUpdate/upload
```

**"Checksum mismatch"**:
```bash
# Verify checksum calculation
sha256sum bundle.swu
# Use exact output in upload request
```

**"File already exists"**:
```bash
# Check existing files
curl http://localhost:8080/softwareUpdate/list
# Remove old version or use different filename
```

### Download Issues

**"File not found"**:
```bash
# Verify filename exists
curl http://localhost:8080/softwareUpdate/list | grep filename
# Use exact filename from list
```

### Cluster Sync Issues

**Check cluster status**:
```bash
curl http://localhost:8080/cluster/members
curl http://localhost:8080/cluster/status
```

**Verify gossip communication**:
```bash
# Check logs for software_update_available messages
tail -f /var/log/fusion-server.log | grep software_update_available
```

## Configuration

### File Permissions
```bash
# Ensure proper permissions for OTA directory
sudo mkdir -p /mnt/ota
sudo chown fusion-server:fusion-server /mnt/ota
sudo chmod 755 /mnt/ota
```

### Monitoring
Monitor software Update operations via logs:
```bash
tail -f /var/log/fusion-server.log | grep "softwareUpdate"
```

Common log events:
- `SoftwareUpdate upload: processing upload` - Upload started
- `SoftwareUpdate upload: bundle finalized` - Upload completed successfully  
- `SoftwareUpdate upload: checksum validation failed` - Integrity check failed
- `SoftwareUpdate upload: duplicate content` - File already exists
- `Starting cluster sync tracking` - Cluster distribution initiated
- `Cluster sync completed successfully` - All nodes synchronized

## Testing

Comprehensive integration tests are available to validate the software update functionality.

### Running Integration Tests

From the `fusion/` directory:

```bash
# Run all software update tests
FUSION_TEST_VIP=192.168.2.100:8080 \
FUSION_TEST_NODES=192.168.2.100:8080 \
go test -v ./test -run TestSoftwareUpdate
```

### Individual Test Scenarios

**Upload and List Functionality**:
```bash
FUSION_TEST_VIP=192.168.2.100:8080 \
FUSION_TEST_NODES=192.168.2.100:8080 \
go test -v ./test -run TestSoftwareUpdateUploadAndListSuccess
```

**Checksum Validation**:
```bash
FUSION_TEST_VIP=192.168.2.100:8080 \
FUSION_TEST_NODES=192.168.2.100:8080 \
go test -v ./test -run TestSoftwareUpdateUploadChecksumMismatch
```

**Duplicate Detection (409 Conflict)**:
```bash
FUSION_TEST_VIP=192.168.2.100:8080 \
FUSION_TEST_NODES=192.168.2.100:8080 \
go test -v ./test -run TestSoftwareUpdateUploadDuplicate
```

**File Size Limits (413 Request Entity Too Large)**:
```bash
FUSION_TEST_VIP=192.168.2.100:8080 \
FUSION_TEST_NODES=192.168.2.100:8080 \
go test -v ./test -run TestSoftwareUpdateUploadOversized
```

**Field Validation (400 Bad Request)**:
```bash
FUSION_TEST_VIP=192.168.2.100:8080 \
FUSION_TEST_NODES=192.168.2.100:8080 \
go test -v ./test -run TestSoftwareUpdateUploadMissingFields
```

**Download Functionality**:
```bash
FUSION_TEST_VIP=192.168.2.100:8080 \
FUSION_TEST_NODES=192.168.2.100:8080 \
go test -v ./test -run TestSoftwareUpdateDownload
```

### WebSocket Software Update Tests

WebSocket-based software update tests (trigger and progress) are also available:

**Trigger via WebSocket (expects code `3005`)**:
```bash
FUSION_TEST_VIP=192.168.2.100:8080 \
go test -v ./test -run TestSoftwareUpdateTriggerViaWebSocket
```

**Invalid type error handling (expects code `4002`)**:
```bash
FUSION_TEST_VIP=192.168.2.100:8080 \
go test -v ./test -run TestSoftwareUpdateTriggerUnknownType
```

**Progress push after trigger** (requires `/tmp/swupdateprog` socket — real device only):
```bash
FUSION_TEST_VIP=192.168.2.100:8080 \
FUSION_SWUPDATE_TEST=1 \
go test -v ./test -run TestSoftwareUpdateProgressReceivedAfterTrigger
```

**Progress message format validation** (requires `/tmp/swupdateprog` socket — real device only):
```bash
FUSION_TEST_VIP=192.168.2.100:8080 \
FUSION_SWUPDATE_TEST=1 \
go test -v ./test -run TestSoftwareUpdateProgressMessageFormat
```

> **Note**: Tests that read the swupdate progress socket (`/tmp/swupdateprog`) check for the
> `FUSION_SWUPDATE_TEST=1` environment variable and **skip automatically** if it is not set.
> This keeps the test suite safe to run in Multipass or CI environments where the swupdate daemon
> is not present. Set `FUSION_SWUPDATE_TEST=1` only when running against a real device.

### Test Coverage

The integration test suite validates:

- **Multipart Upload Processing**: Proper handling of `.swu` bundle files and checksum fields
- **SHA-256 Integrity Checking**: Checksum calculation during streaming and validation
- **File Size Enforcement**: 300MB limit with proper HTTP 413 responses
- **Duplicate Detection**: Content-based conflict detection using SHA-256 checksums
- **Field Validation**: Missing bundle/checksum detection with appropriate error messages
- **File Download**: Successful retrieval and proper 404 handling for missing files
- **Storage Integration**: Persistent storage in `/mnt/ota` with atomic operations
- **Cluster Synchronization**: Sync tracking and completion waiting across cluster members
- **Error Handling**: Comprehensive HTTP status code mapping and error responses
- **WebSocket Trigger**: `start_update` via WebSocket with correct code `3005` response
- **WebSocket Progress Push**: Validates aggregated `update_progress` message format (all nodes, per-field types)

### Testing Against Local Server

For local development testing:

1. **Start local fusion server**:
   ```bash
   ./build/fusion-server_darwin_arm64 --local
   ```

2. **Run tests against localhost**:
   ```bash
   FUSION_TEST_VIP=127.0.0.1:8080 \
   FUSION_TEST_NODES=127.0.0.1:8080 \
   FUSION_TEST_LOCAL=1 \
   go test -v ./test -run TestSoftwareUpdate
   ```

### Manual Testing Examples

**Create test bundle**:
```bash
# Create a small test file
echo "Test SWU Bundle Content" > test-bundle.swu

# Calculate checksum
sha256sum test-bundle.swu
```

**Upload test**:
```bash
curl -X POST http://localhost:8080/softwareUpdate/upload \
  -F "bundle=@test-bundle.swu" \
  -F "checksum=$(sha256sum test-bundle.swu | cut -d' ' -f1)"
```

**Verify the upload worked**:
```bash
curl http://localhost:8080/softwareUpdate/list | jq .
```

**Download test**:
```bash
curl -O http://localhost:8080/softwareUpdate/download/test-bundle.swu
```

### Error Response Examples

The API returns structured JSON error responses with specific error types:

**Missing Bundle Field (HTTP 400)**:
```json
{"error":"missing_field","message":"Missing \"bundle\" field (.swu file required)"}
```

**Missing Checksum Field (HTTP 400)**:
```json
{"error":"missing_field","message":"Missing \"checksum\" field (SHA-256 hex required)"}
```

**Invalid File Type (HTTP 400)**:
```json
{"error":"invalid_file_type","message":"Only .swu bundle files are allowed"}
```

**Checksum Mismatch (HTTP 400)**:
```json
{"error":"checksum_mismatch","message":"checksum mismatch: computed=abc123..., expected=def456..."}
```

**File Already Exists (HTTP 409)**:
```json
{"error":"already_exists","message":"SoftwareUpdate file is already present on this node with the same checksum"}
```

**File Too Large (HTTP 413)**:
```json
{"error":"file_too_large","message":"Software update bundle exceeds maximum size limit of 300 MB"}
```

**Cluster Sync Timeout (HTTP 408)**:
```json
{"error":"sync_timeout","message":"Software update was uploaded but cluster sync did not complete within timeout"}
```

**File Not Found (HTTP 404)**:
```json
{"error":"not_found","message":"SoftwareUpdate bundle not found"}
```