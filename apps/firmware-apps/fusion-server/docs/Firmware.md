# Firmware Management

Fusion Server provides REST API endpoints for uploading, downloading, and managing firmware files across the cluster. This document covers the firmware management functionality and API usage.

## Overview

The firmware management system allows:
- **Secure Upload**: Upload `.swu` firmware bundles with SHA-256 checksum validation
- **Cluster Distribution**: Automatic distribution to all cluster members via gossip protocol
- **Version Management**: Duplicate detection and version control

## Architecture

### File Storage
- **Storage Path**: `/mnt/ota/` - Primary storage for validated firmware files
- **Staging Process**: Files are staged directly in `/mnt/ota/` as `.part` files during upload
- **Atomic Deployment**: Simple rename operation from `.part` to final filename after validation

### Workflow
1. **Upload**: Receive multipart form data with firmware file and checksum
2. **Staging**: Stream file directly to `/mnt/ota/<filename>.part` 
3. **Validation**: Calculate and verify SHA-256 checksum during streaming
4. **Duplicate Check**: Verify file content isn't already present (same or different filename)
5. **Deployment**: Atomic rename from `.part` to final filename
6. **Distribution**: Broadcast `firmware_available` gossip message to cluster
7. **Automatic Sync**: Follower nodes download from VIP automatically

## API Endpoints

### POST /firmware/upload

Upload a firmware bundle (.swu file) with checksum validation.

**Request Format**:
```bash
curl -X POST http://localhost:8080/firmware/upload \
  -F "firmware=@firmware_v1.2.3.swu" \
  -F "checksum=abc123def456..."
```

**Multipart Form Fields**:
- `firmware` (required): The firmware bundle as a `.swu` file
- `checksum` (required): Expected SHA-256 hex digest (64 characters)

**Response** (201 Created):
```json
{
  "filename": "firmware_v1.2.3.swu",
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

### GET /firmware/download/{filename}

Download a specific firmware file.

**Request**:
```bash
curl -O http://localhost:8080/firmware/download/firmware_v1.2.3.swu
```

**Response**: Binary firmware file with appropriate headers:
- `Content-Type: application/octet-stream`
- `Content-Disposition: attachment; filename="firmware_v1.2.3.swu"`
- `Content-Length: <file-size>`

### GET /firmware/list

List all available firmware files.

**Request**:
```bash
curl http://localhost:8080/firmware/list
```

**Response**:
```json
[
  {
    "filename": "firmware_v1.2.3.swu",
    "checksum": "abc123def456...",
    "size_bytes": 15728640,
    "uploaded": "2026-03-26T17:30:00Z",
    "source_ip": "192.168.1.100"
  },
  {
    "filename": "firmware_v1.2.4.swu", 
    "checksum": "def456abc123...",
    "size_bytes": 15831552,
    "uploaded": "2026-03-26T18:15:00Z",
    "source_ip": "192.168.1.100"
  }
]
```

## Usage Examples

### Upload New Firmware

1. **Calculate checksum**:
   ```bash
   sha256sum firmware_v1.2.3.swu
   abc123def456abc123def456abc123def456abc123def456abc123def456abc123
   ```

2. **Upload with checksum**:
   ```bash
   curl -X POST http://localhost:8080/firmware/upload \
     -F "firmware=@firmware_v1.2.3.swu" \
     -F "checksum=abc123def456abc123def456abc123def456abc123def456abc123def456abc123"
   ```

3. **Verify upload**:
   ```bash
   curl http://localhost:8080/firmware/list | jq '.[] | select(.filename=="firmware_v1.2.3.swu")'
   ```

### Download Existing Firmware

```bash
# List available firmware
curl http://localhost:8080/firmware/list

# Download specific version
curl -O http://localhost:8080/firmware/download/firmware_v1.2.3.swu
```

### Cluster Distribution

When a firmware file is uploaded to the VIP node:

1. **File is stored** in `/mnt/ota/` on the VIP node
2. **Gossip message** is broadcast with firmware metadata
3. **Follower nodes** automatically download from VIP via `/firmware/download/{filename}`
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
├── firmware_v1.2.3.swu           # Validated firmware file
├── firmware_v1.2.4.swu           # Another version
└── temp_upload.swu.part           # Temporary file (cleaned up)
```

### Cleanup
- `.part` files are automatically cleaned up on startup
- Failed uploads leave no artifacts
- Temporary files are removed on process exit

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
- **Network-based**: Restrict access to firmware endpoints via firewall
- **File permissions**: `/mnt/ota/` directory should have appropriate ownership
- **Cluster security**: Use private networks for cluster communication

### Validation
- **File type enforcement**: Only `.swu` extensions accepted
- **Size limits**: 300MB maximum prevents resource exhaustion
- **Content verification**: SHA-256 ensures file integrity

## Troubleshooting

### Upload Failures

**"Missing firmware field"**:
```bash
# Incorrect - missing file field
curl -F "checksum=abc123" http://localhost:8080/firmware/upload

# Correct - include firmware file
curl -F "firmware=@file.swu" -F "checksum=abc123" http://localhost:8080/firmware/upload
```

**"Checksum mismatch"**:
```bash
# Verify checksum calculation
sha256sum firmware.swu
# Use exact output in upload request
```

**"File already exists"**:
```bash
# Check existing files
curl http://localhost:8080/firmware/list
# Remove old version or use different filename
```

### Download Issues

**"File not found"**:
```bash
# Verify filename exists
curl http://localhost:8080/firmware/list | grep filename
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
# Check logs for firmware_available messages
tail -f /var/log/fusion-server.log | grep firmware_available
```

## Configuration

### Environment Variables
- `FUSION_OTA_PATH`: Override default `/mnt/ota/` storage path (not recommended)
- `FUSION_MAX_UPLOAD_SIZE`: Override 300MB upload limit (not recommended)

### File Permissions
```bash
# Ensure proper permissions for OTA directory
sudo mkdir -p /mnt/ota
sudo chown fusion-server:fusion-server /mnt/ota
sudo chmod 755 /mnt/ota
```

### Monitoring
Monitor firmware operations via logs:
```bash
tail -f /var/log/fusion-server.log | grep "firmware upload"
```

Common log events:
- `firmware upload: processing upload` - Upload started
- `firmware upload: bundle finalized` - Upload completed successfully  
- `firmware upload: checksum validation failed` - Integrity check failed
- `firmware upload: duplicate content` - File already exists