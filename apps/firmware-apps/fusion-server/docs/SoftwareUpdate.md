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
- `.part` files are automatically cleaned up as part of the upload processing (e.g. during `processFirmwareStream`)
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