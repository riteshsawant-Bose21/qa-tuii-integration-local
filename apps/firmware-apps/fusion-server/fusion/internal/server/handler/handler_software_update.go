package handler

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/utils"
	"io"
	"mime"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
	"time"

	json "github.com/goccy/go-json"
	"github.com/oklog/ulid/v2"
)

// Sentinel errors for upload validation
var (
	ErrMissingSoftwareUpdate = errors.New("missing_software_update")
	ErrMissingChecksum       = errors.New("missing_checksum")
	ErrInvalidFilename       = errors.New("invalid_filename")
	ErrInvalidFileType       = errors.New("invalid_file_type")
)

// writeSoftwareUpdateError writes a JSON error response for SoftwareUpdate endpoints.
func writeSoftwareUpdateError(w http.ResponseWriter, statusCode int, errMsg, detail string) {
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	w.WriteHeader(statusCode)
	_ = json.NewEncoder(w).Encode(api.SoftwareUpdateErrorResponse{Error: errMsg, Message: detail})
}

// HandleSoftwareUpdateUpload handles POST /softwareUpdate/upload.
//
// Multipart form fields:
//
//	bundle: The SoftwareUpdate bundle as a .swu file (required).
//	checksum: Expected SHA-256 hex digest for integrity validation (required).
func (h *Handler) HandleSoftwareUpdateUpload(w http.ResponseWriter, r *http.Request) {
	logger := logging.GetLogger()
	start := time.Now()
	ctx := r.Context()

	defer func() {
		duration := time.Since(start)
		logger.Debug("SoftwareUpdate upload: completed in %v", duration)
	}()

	logger.Info("SoftwareUpdate upload: processing upload on node %s", h.clusterTransport.LocalNode().Name)

	// Check available disk space based on Content-Length header
	if contentLength := r.ContentLength; contentLength > 0 {
		if err := checkDiskSpace(contentLength, logger); err != nil {
			logger.Error("SoftwareUpdate upload: disk space check failed: %v", err)
			writeSoftwareUpdateError(w, http.StatusInsufficientStorage, "insufficient_storage", err.Error())
			return
		}
		logger.Debug("SoftwareUpdate upload: disk space check passed for %d bytes upload", contentLength)
	}

	r.Body = http.MaxBytesReader(w, r.Body, api.MaxSoftwareUpdateUploadBytes)

	contentType := r.Header.Get("Content-Type")
	_, params, err := mime.ParseMediaType(contentType)
	if err != nil {
		logger.Error("SoftwareUpdate upload: parse content type: %v", err)
		writeSoftwareUpdateError(w, http.StatusBadRequest, "invalid_content_type", "Invalid or missing multipart content type")
		return
	}

	boundary, ok := params["boundary"]
	if !ok {
		logger.Error("SoftwareUpdate upload: missing boundary in content type")
		writeSoftwareUpdateError(w, http.StatusBadRequest, "invalid_content_type", "Missing multipart boundary")
		return
	}

	multipartReader := multipart.NewReader(r.Body, boundary)

	var origName string
	var expectedChecksum string
	var actualChecksum string
	var written int64
	var tmpPath string
	var finalPath string

	// Stream through multipart parts and collect required fields
	for {
		part, err := multipartReader.NextPart()
		if err == io.EOF {
			break
		}
		if err != nil {
			// Check if this is a max bytes exceeded error
			if isMaxBytesError(err) {
				logger.Error("SoftwareUpdate upload: request body too large: %v", err)
				writeSoftwareUpdateError(w, http.StatusRequestEntityTooLarge, "file_too_large",
					fmt.Sprintf("Software update bundle exceeds maximum size limit of %d MB",
						api.MaxSoftwareUpdateUploadBytes/(1024*1024)))
				return
			}
			logger.Error("SoftwareUpdate upload: read multipart part: %v", err)
			writeSoftwareUpdateError(w, http.StatusBadRequest, "invalid_form", "Error reading multipart form data")
			return
		}

		formName := part.FormName()
		switch formName {
		case "bundle":
			filename := part.FileName()
			if filename == "" {
				part.Close()
				continue
			}
			origName = filepath.Base(filename)

			// Process SoftwareUpdate data immediately to avoid memory buffering
			actualChecksum, written, tmpPath, err = h.processSoftwareUpdateStream(part, origName, ctx)
			part.Close()
			if err != nil {
				// Check if this is a file size limit error
				if strings.Contains(err.Error(), "file_too_large:") {
					logger.Error("SoftwareUpdate upload: file too large: %v", err)
					writeSoftwareUpdateError(w, http.StatusRequestEntityTooLarge, "file_too_large",
						strings.TrimPrefix(err.Error(), "file_too_large: "))
					return
				}
				logger.Error("SoftwareUpdate upload: process SoftwareUpdate stream: %v", err)
				writeSoftwareUpdateError(w, http.StatusBadRequest, "invalid_form", "Error processing SoftwareUpdate bundle file")
				return
			}
		case "checksum":
			checksumBytes, err := io.ReadAll(part)
			part.Close()
			if err != nil {
				logger.Error("SoftwareUpdate upload: read checksum: %v", err)
				writeSoftwareUpdateError(w, http.StatusBadRequest, "invalid_form", "Error reading checksum field")
				return
			}
			expectedChecksum = strings.TrimSpace(string(checksumBytes))
		default:
			// Close unknown parts to avoid resource leaks
			part.Close()
		}
	}

	// Validate required fields and filename
	if err := validateUploadFields(origName, expectedChecksum, logger); err != nil {
		cleanupTempFile(tmpPath, logger)
		switch {
		case errors.Is(err, ErrMissingSoftwareUpdate):
			writeSoftwareUpdateError(w, http.StatusBadRequest, "missing_field", `Missing "bundle" field (.swu file required)`)
		case errors.Is(err, ErrMissingChecksum):
			writeSoftwareUpdateError(w, http.StatusBadRequest, "missing_field", `Missing "checksum" field (SHA-256 hex required)`)
		case errors.Is(err, ErrInvalidFilename):
			writeSoftwareUpdateError(w, http.StatusBadRequest, "invalid_filename", "Filename is missing or invalid")
		case errors.Is(err, ErrInvalidFileType):
			writeSoftwareUpdateError(w, http.StatusBadRequest, "invalid_file_type", "Only .swu bundle files are allowed")
		default:
			writeSoftwareUpdateError(w, http.StatusBadRequest, "validation_error", "Upload validation failed")
		}
		return
	}

	// Sanitize filename
	origName = filepath.Base(origName)

	// Validate checksum
	if err := validateChecksum(actualChecksum, expectedChecksum); err != nil {
		cleanupTempFile(tmpPath, logger)
		logger.Error("software update upload: checksum validation failed: %v", err)
		writeSoftwareUpdateError(w, http.StatusBadRequest, "checksum_mismatch", err.Error())
		return
	}

	// Check for existing file with same name and checksum to prevent duplicates
	finalPath = filepath.Join(api.SoftwareUpdateOTAPath, origName)
	logger.Debug("SoftwareUpdate upload: checking for existing file at %s", finalPath)
	if _, statErr := os.Stat(finalPath); statErr == nil {
		existingChecksum, csErr := utils.FileChecksum(finalPath)
		if csErr != nil {
			logger.Warn("SoftwareUpdate upload: could not checksum existing file %s: %v — proceeding with overwrite", finalPath, csErr)
		} else if strings.EqualFold(existingChecksum, actualChecksum) {
			logger.Info("SoftwareUpdate upload: %s already present with matching checksum %s — rejecting duplicate", origName, existingChecksum)
			// Clean up temp file
			os.Remove(tmpPath)
			writeSoftwareUpdateError(w, http.StatusConflict, "already_exists",
				"SoftwareUpdate file is already present on this node with the same checksum")
			return
		} else {
			// Different checksum — the bundle has been updated; allow overwrite.
			logger.Info("SoftwareUpdate upload: %s exists (checksum %s) but actual checksum differs (%s) — overwriting", origName, existingChecksum, actualChecksum)
		}
	} else {
		logger.Debug("SoftwareUpdate upload: no existing file at %s (%v) — proceeding", finalPath, statErr)
	}

	if duplicateFile, err := checkForCrossFilenameDuplicates(api.SoftwareUpdateOTAPath, actualChecksum, origName, logger); err != nil {
		cleanupTempFile(tmpPath, logger)
		writeSoftwareUpdateError(w, http.StatusInternalServerError, "server_error", "Failed to scan for duplicate content")
		return
	} else if duplicateFile != "" {
		logger.Info("SoftwareUpdate upload: identical content (checksum %s) already exists as %s — rejecting duplicate %s",
			actualChecksum, duplicateFile, origName)
		cleanupTempFile(tmpPath, logger)
		writeSoftwareUpdateError(w, http.StatusConflict, "already_exists",
			fmt.Sprintf("SoftwareUpdate content is already present with this checksum as file '%s'", duplicateFile))
		return
	}

	// Finalize upload by renaming from temp .part path to final filename in OTA directory
	if err := os.Rename(tmpPath, finalPath); err != nil {
		cleanupTempFile(tmpPath, logger)
		logger.Error("SoftwareUpdate upload: rename %s → %s failed: %v", tmpPath, finalPath, err)
		writeSoftwareUpdateError(w, http.StatusInternalServerError, "server_error", "Failed to finalize SoftwareUpdate file")
		return
	}

	logger.Info("SoftwareUpdate upload: bundle finalized at %s (%.1f MB, sha256=%s, duration=%v)",
		finalPath, float64(written)/(1<<20), actualChecksum, time.Since(start))

	uploadRate := float64(written) / (1024 * 1024) / time.Since(start).Seconds()
	logger.Info("SoftwareUpdate upload: upload rate: %.1f MB/s", uploadRate)

	uploaded := time.Now().UTC()

	// Get cluster members (excluding self) for sync tracking
	members := h.clusterTransport.MemberListMembers()
	var expectedNodes []string
	localNodeName := h.clusterTransport.LocalNode().Name

	for _, member := range members {
		if member.Name != localNodeName {
			expectedNodes = append(expectedNodes, member.Name)
		}
	}

	// If no other nodes in cluster, respond immediately
	if len(expectedNodes) == 0 {
		logger.Info("[SoftwareUpdateUpload] Single node cluster - responding immediately")
		resp := api.SoftwareUpdateUploadResponse{
			Filename:  origName,
			Checksum:  actualChecksum,
			SizeBytes: written,
			Uploaded:  uploaded,
		}

		w.Header().Set(api.ContentType, api.JsonMIMEType)
		w.WriteHeader(http.StatusCreated)
		if err := json.NewEncoder(w).Encode(resp); err != nil {
			logger.Error("SoftwareUpdate upload: json encode: %v", err)
		}
		return
	}

	// Generate unique sync ID for this operation
	syncID := ulid.Make().String()
	logger.Info("[SoftwareUpdateUpload] Starting cluster sync tracking (ID: %s) for %d nodes: %v",
		syncID, len(expectedNodes), expectedNodes)

	// Start sync tracking with 2 minute timeout
	h.StartSyncTracking(syncID, origName, actualChecksum, expectedNodes, 2*time.Minute)

	logger.Info("[SoftwareUpdateUpload] Broadcasting to cluster for automatic distribution")

	// Broadcast SoftwareUpdate availability to cluster so followers can initiate download
	sourceIP := h.clusterTransport.LocalNode().Addr.String()

	update := &api.SoftwareUpdateSync{
		Filename:  origName,
		Checksum:  actualChecksum,
		SizeBytes: written,
		Uploaded:  uploaded,
		SourceIP:  sourceIP,
	}

	// Add sync ID to the update for tracking
	update.SyncID = syncID

	msg := api.NewNotifyMessage(
		api.NotifyOpSoftwareUpdateAvailable,
		h.clusterTransport.LocalNode().Name,
		api.WithSoftwareUpdate(update),
	)

	if err := h.hub.BroadcastToNodes(msg); err != nil {
		logger.Error("SoftwareUpdate upload: broadcast gossip failed: %v", err)
		writeSoftwareUpdateError(w, http.StatusInternalServerError, "broadcast_failed", "Failed to broadcast to cluster")
		return
	}

	logger.Info("SoftwareUpdate upload: broadcasted software_update_available for %s from %s with sync ID %s",
		origName, sourceIP, syncID)

	// Wait for cluster-wide sync completion or timeout
	logger.Info("[SoftwareUpdateUpload] Waiting for cluster sync completion...")
	success, err := h.WaitForSyncCompletion(syncID)

	if !success {
		logger.Error("SoftwareUpdate upload: cluster sync failed or timed out: %v", err)
		writeSoftwareUpdateError(w, http.StatusRequestTimeout, "sync_timeout",
			"Software update was uploaded but cluster sync did not complete within timeout")
		return
	}

	logger.Info("[SoftwareUpdateUpload] Cluster sync completed successfully - sending response")

	// Send successful response after cluster sync completion
	resp := api.SoftwareUpdateUploadResponse{
		Filename:  origName,
		Checksum:  actualChecksum,
		SizeBytes: written,
		Uploaded:  uploaded,
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	w.WriteHeader(http.StatusCreated)
	if err := json.NewEncoder(w).Encode(resp); err != nil {
		logger.Error("SoftwareUpdate upload: json encode: %v", err)
	}

	logger.Info("[SoftwareUpdateUpload] Upload and cluster sync completed successfully")
}

// HandleSoftwareUpdateDownload serves GET /softwareUpdate/download/{filename}.
// This is the source endpoint that follower nodes HTTP-pull from when the
// VIP broadcasts a software_update_available gossip notification.
func (h *Handler) HandleSoftwareUpdateDownload(w http.ResponseWriter, r *http.Request) {
	logger := logging.GetLogger()
	logger.Info("[SoftwareUpdateDownload] Request from %s for %s", r.RemoteAddr, r.URL.Path)

	filename, err := utils.ExtractValue(r, "filename")
	if err != nil {
		logger.Error("[SoftwareUpdateDownload] Invalid filename parameter: %v", err)
		writeSoftwareUpdateError(w, http.StatusBadRequest, "invalid_filename", "Filename is missing or invalid")
		return
	}

	// Sanitize filename to prevent path traversal and validate format
	originalFilename := filename
	filename = filepath.Base(filename)

	// Reject if sanitized filename differs from original (indicates path traversal attempt)
	if filename != originalFilename {
		logger.Error("[SoftwareUpdateDownload] Path traversal attempt detected: %s", originalFilename)
		writeSoftwareUpdateError(w, http.StatusBadRequest, "invalid_filename", "Invalid filename - path components not allowed")
		return
	}

	// Reject empty filenames or current/parent directory references
	if filename == "" || filename == "." || filename == ".." {
		logger.Error("[SoftwareUpdateDownload] Invalid filename: %s", originalFilename)
		writeSoftwareUpdateError(w, http.StatusBadRequest, "invalid_filename", "Invalid filename")
		return
	}

	// Enforce .swu file extension for security
	if !strings.HasSuffix(strings.ToLower(filename), ".swu") {
		logger.Error("[SoftwareUpdateDownload] Invalid file type - only .swu files allowed: %s", filename)
		writeSoftwareUpdateError(w, http.StatusBadRequest, "invalid_file_type", "Only .swu bundle files are allowed")
		return
	}

	logger.Info("[SoftwareUpdateDownload] Requested file: %s", filename)

	filePath := filepath.Join(api.SoftwareUpdateOTAPath, filename)
	logger.Info("[SoftwareUpdateDownload] Looking for file at: %s", filePath)

	f, err := os.Open(filePath)
	if err != nil {
		if os.IsNotExist(err) {
			logger.Error("[SoftwareUpdateDownload] File not found: %s", filePath)
			writeSoftwareUpdateError(w, http.StatusNotFound, "not_found",
				"SoftwareUpdate bundle not found")
			return
		}
		logger.Error("SoftwareUpdate download: open %s: %v", filePath, err)
		writeSoftwareUpdateError(w, http.StatusInternalServerError, "server_error", "Failed to open SoftwareUpdate bundle")
		return
	}
	defer f.Close()

	info, err := f.Stat()
	if err != nil {
		logger.Error("SoftwareUpdate download: stat %s: %v", filePath, err)
		writeSoftwareUpdateError(w, http.StatusInternalServerError, "server_error", "Failed to stat SoftwareUpdate bundle")
		return
	}

	logger.Info("[SoftwareUpdateDownload] Serving file: %s (%.1f MB)", filename, float64(info.Size())/(1<<20))

	// Safely encode filename for Content-Disposition header
	safeFilename := strings.ReplaceAll(filename, "\\", "\\\\")
	safeFilename = strings.ReplaceAll(safeFilename, "\"", "\\\"")
	safeFilename = strings.ReplaceAll(safeFilename, "\n", "")
	safeFilename = strings.ReplaceAll(safeFilename, "\r", "")

	w.Header().Set("Content-Type", "application/octet-stream")
	w.Header().Set("Content-Disposition", "attachment; filename=\""+safeFilename+"\"")
	w.Header().Set("Content-Length", strconv.FormatInt(info.Size(), 10))

	if _, err := io.Copy(w, f); err != nil {
		logger.Error("SoftwareUpdate download: stream %s: %v", filePath, err)
	}
}

// HandleSoftwareUpdateList serves GET /SoftwareUpdate/list.
// Returns all SoftwareUpdate bundles present in /mnt/ota as []api.SoftwareUpdateSyncUpdate.
// Called by joining nodes to perform initial SoftwareUpdate sync from a peer.
func (h *Handler) HandleSoftwareUpdateList(w http.ResponseWriter, r *http.Request) {
	logger := logging.GetLogger()

	entries, err := os.ReadDir(api.SoftwareUpdateOTAPath)
	if err != nil {
		if os.IsNotExist(err) {
			// No SoftwareUpdate directory yet — return empty list
			w.Header().Set(api.ContentType, api.JsonMIMEType)
			w.Write([]byte("[]"))
			return
		}
		logger.Error("SoftwareUpdate list: readdir %s: %v", api.SoftwareUpdateOTAPath, err)
		writeSoftwareUpdateError(w, http.StatusInternalServerError, "server_error", "Failed to list SoftwareUpdate directory")
		return
	}

	sourceIP := h.clusterTransport.LocalNode().Addr.String()

	var bundles []api.SoftwareUpdateSync
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		name := entry.Name()
		if strings.HasSuffix(name, ".part") {
			continue
		}
		fullPath := filepath.Join(api.SoftwareUpdateOTAPath, name)

		info, err := entry.Info()
		if err != nil {
			logger.Warn("SoftwareUpdate list: stat %s: %v — skipping", fullPath, err)
			continue
		}

		checksum, err := utils.FileChecksum(fullPath)
		if err != nil {
			logger.Warn("SoftwareUpdate list: checksum %s: %v — skipping", fullPath, err)
			continue
		}

		bundles = append(bundles, api.SoftwareUpdateSync{
			Filename:  name,
			Checksum:  checksum,
			SizeBytes: info.Size(),
			Uploaded:  info.ModTime().UTC(),
			SourceIP:  sourceIP,
		})
	}

	if bundles == nil {
		bundles = []api.SoftwareUpdateSync{}
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	if err := json.NewEncoder(w).Encode(bundles); err != nil {
		logger.Error("SoftwareUpdate list: json encode: %v", err)
	}
}

// processSoftwareUpdateStream processes a SoftwareUpdate file stream directly to disk without buffering in memory
func (h *Handler) processSoftwareUpdateStream(part *multipart.Part, origName string, ctx context.Context) (checksum string, written int64, tmpPath string, err error) {
	logger := logging.GetLogger()

	// Create OTA directory for staging uploads directly
	if err = os.MkdirAll(api.SoftwareUpdateOTAPath, 0755); err != nil {
		logger.Error("SoftwareUpdate upload: mkdir %s: %v", api.SoftwareUpdateOTAPath, err)
		return "", 0, "", fmt.Errorf("failed to create OTA directory: %w", err)
	}

	// Clean up any existing stale .part files in OTA directory
	cleanupStalePartFiles(api.SoftwareUpdateOTAPath, logger)

	tmpFile, err := os.CreateTemp(api.SoftwareUpdateOTAPath, origName+".*.part")
	if err != nil {
		logger.Error("SoftwareUpdate upload: create temp file: %v", err)
		return "", 0, "", fmt.Errorf("failed to create temp file: %w", err)
	}
	tmpPath = tmpFile.Name()

	// Check context cancellation
	if err := ctx.Err(); err != nil {
		tmpFile.Close()
		os.Remove(tmpPath)
		return "", 0, "", fmt.Errorf("context cancelled: %w", err)
	}

	hasher := sha256.New()
	// Stream from multipart part directly to temp file with hash calculation
	bufferSize := 1024 * 1024 // 1MB buffer
	written, copyErr := io.CopyBuffer(tmpFile, io.TeeReader(part, hasher), make([]byte, bufferSize))

	// Close file first to ensure data is written
	closeErr := tmpFile.Close()

	if copyErr != nil {
		os.Remove(tmpPath)
		// Check if this is a max bytes exceeded error
		logger.Error("SoftwareUpdate upload: copy error details: %v (type: %T)", copyErr, copyErr)
		if isMaxBytesError(copyErr) {
			logger.Error("SoftwareUpdate upload: request body too large during stream: %v", copyErr)
			return "", 0, "", fmt.Errorf("file_too_large: Software update bundle exceeds maximum size limit of %d MB",
				api.MaxSoftwareUpdateUploadBytes/(1024*1024))
		}
		logger.Error("SoftwareUpdate upload: write to %s failed: %v", tmpPath, copyErr)
		return "", 0, "", fmt.Errorf("failed to write SoftwareUpdate data: %w", copyErr)
	}
	if closeErr != nil {
		os.Remove(tmpPath)
		logger.Error("SoftwareUpdate upload: close %s failed: %v", tmpPath, closeErr)
		return "", 0, "", fmt.Errorf("failed to close temp file: %w", closeErr)
	}

	// Validate written size
	if written == 0 {
		os.Remove(tmpPath)
		return "", 0, "", fmt.Errorf("no data written to temp file")
	}

	checksum = hex.EncodeToString(hasher.Sum(nil))
	logger.Debug("SoftwareUpdate upload: streaming completed to OTA directory - %d bytes written, checksum: %s", written, checksum)
	return checksum, written, tmpPath, nil
}

// handleSwUpdateInfo fetches /etc/swupdate from all cluster nodes and returns the aggregated results.
func (h *Handler) handleSwUpdateInfo(request *api.WebSocketRequest) (*api.WebSocketResponse, error) {
	infos := h.clusterTransport.GetAllSwUpdateInfo()
	return createSuccessResponse(&request.ID, api.WSMsgTypeSwUpdateInfo, api.WSCodeOK, "OK", infos), nil
}

// Helper functions for improved error handling and validation

// validateChecksum validates the computed checksum against expected value
func validateChecksum(actual, expected string) error {
	if actual == "" {
		return fmt.Errorf("computed checksum is empty")
	}
	if expected == "" {
		return fmt.Errorf("expected checksum is empty")
	}
	if len(expected) != 64 {
		return fmt.Errorf("invalid checksum format - expected 64 hex characters, got %d", len(expected))
	}
	// Validate hex format
	if _, err := hex.DecodeString(expected); err != nil {
		return fmt.Errorf("invalid checksum format - not valid hex: %w", err)
	}
	if !strings.EqualFold(actual, expected) {
		return fmt.Errorf("SHA-256 of received bundle does not match X-Checksum-SHA256 header. Bundle discarded.")
	}
	return nil
}

// validateUploadFields validates all required fields for SoftwareUpdate upload
func validateUploadFields(origName, expectedChecksum string, logger *logging.Logger) error {
	if origName == "" {
		logger.Error("SoftwareUpdate upload: SoftwareUpdate file not found in multipart data")
		return ErrMissingSoftwareUpdate
	}

	if expectedChecksum == "" {
		logger.Error("SoftwareUpdate upload: checksum field not found")
		return ErrMissingChecksum
	}

	origName = filepath.Base(origName)
	if origName == "" || origName == "." {
		logger.Error("SoftwareUpdate upload: invalid filename after sanitization")
		return ErrInvalidFilename
	}

	// Validate file extension for security
	if !strings.HasSuffix(strings.ToLower(origName), ".swu") {
		logger.Error("SoftwareUpdate upload: invalid file type - only .swu files allowed")
		return ErrInvalidFileType
	}

	return nil
}

// checkForCrossFilenameDuplicates scans for duplicate content across different filenames
func checkForCrossFilenameDuplicates(otaPath, actualChecksum, origName string, logger *logging.Logger) (string, error) {
	entries, readErr := os.ReadDir(otaPath)
	if readErr != nil {
		if os.IsNotExist(readErr) {
			return "", nil // Directory doesn't exist yet - no duplicates
		}
		return "", fmt.Errorf("failed to read OTA directory: %w", readErr)
	}

	logger.Debug("SoftwareUpdate upload: scanning %d entries in %s for duplicate content", len(entries), otaPath)
	for _, entry := range entries {
		if entry.IsDir() || entry.Name() == origName {
			continue
		}
		// Skip temporary .part files - these should already be cleaned up
		if strings.HasSuffix(entry.Name(), ".part") {
			logger.Debug("SoftwareUpdate upload: skipping temp file %s", entry.Name())
			continue
		}
		candidate := filepath.Join(otaPath, entry.Name())
		logger.Debug("SoftwareUpdate upload: checking candidate %s", candidate)
		candidateChecksum, csErr := utils.FileChecksum(candidate)
		if csErr != nil {
			logger.Debug("SoftwareUpdate upload: failed to checksum %s: %v", candidate, csErr)
			continue
		}
		logger.Debug("SoftwareUpdate upload: candidate %s has checksum %s, comparing against upload %s", entry.Name(), candidateChecksum, actualChecksum)
		if strings.EqualFold(candidateChecksum, actualChecksum) {
			return entry.Name(), nil // Found duplicate
		}
	}
	logger.Debug("SoftwareUpdate upload: no duplicate content found in %d existing files", len(entries))
	return "", nil
}

// cleanupTempFile safely removes temporary files
func cleanupTempFile(tmpPath string, logger *logging.Logger) {
	if tmpPath != "" {
		if err := os.Remove(tmpPath); err != nil && !os.IsNotExist(err) {
			logger.Warn("SoftwareUpdate upload: failed to cleanup temp file %s: %v", tmpPath, err)
		} else {
			logger.Debug("SoftwareUpdate upload: cleaned up temp file %s", tmpPath)
		}
	}
}

// cleanupStalePartFiles removes only truly stale .part files from directory
// Files are considered stale if they're older than staleThreshold and haven't been modified recently
func cleanupStalePartFiles(dirPath string, logger *logging.Logger) {
	const staleThreshold = 1 * time.Hour // Consider files stale after 1 hour

	entries, readErr := os.ReadDir(dirPath)
	if readErr != nil {
		return // Directory might not exist yet
	}

	now := time.Now()
	cleanedCount := 0
	preservedCount := 0

	for _, entry := range entries {
		if strings.HasSuffix(entry.Name(), ".part") {
			staleFile := filepath.Join(dirPath, entry.Name())

			// Get file info to check modification time
			info, err := entry.Info()
			if err != nil {
				logger.Warn("SoftwareUpdate upload: cannot stat temp file %s: %v", entry.Name(), err)
				continue
			}

			age := now.Sub(info.ModTime())
			if age > staleThreshold {
				logger.Info("SoftwareUpdate upload: cleaning up stale temp file %s (age: %v)", entry.Name(), age)
				if err := os.Remove(staleFile); err != nil {
					logger.Warn("SoftwareUpdate upload: failed to remove stale file %s: %v", entry.Name(), err)
				} else {
					cleanedCount++
				}
			} else {
				logger.Debug("SoftwareUpdate upload: preserving recent temp file %s (age: %v)", entry.Name(), age)
				preservedCount++
			}
		}
	}

	if cleanedCount > 0 || preservedCount > 0 {
		logger.Info("SoftwareUpdate upload: cleanup complete - removed %d stale files, preserved %d recent files",
			cleanedCount, preservedCount)
	}
}

// getDiskUsage returns available bytes and filesystem ID for the given path
func getDiskUsage(path string) (availableBytes uint64, fsid syscall.Fsid, err error) {
	var stat syscall.Statfs_t
	if err := syscall.Statfs(path, &stat); err != nil {
		return 0, syscall.Fsid{}, fmt.Errorf("failed to get disk usage for %s: %w", path, err)
	}

	// Calculate available bytes
	availableBytes = stat.Bavail * uint64(stat.Bsize)
	fsid = stat.Fsid
	return availableBytes, fsid, nil
}

// checkDiskSpace validates disk space for OTA directory upload
func checkDiskSpace(uploadSize int64, logger *logging.Logger) error {
	if uploadSize <= 0 {
		return nil
	}

	requiredBytes := uint64(uploadSize)
	bufferBytes := uint64(api.MinFreeSpaceBuffer)
	totalRequired := requiredBytes + bufferBytes

	// Get filesystem info for OTA directory
	otaAvailable, _, err := getDiskUsage(api.SoftwareUpdateOTAPath)
	if err != nil {
		if parent := filepath.Dir(api.SoftwareUpdateOTAPath); parent != api.SoftwareUpdateOTAPath {
			otaAvailable, _, err = getDiskUsage(parent)
		}
		if err != nil {
			return fmt.Errorf("cannot determine disk space for OTA directory: %w", err)
		}
	}

	logger.Debug("softwareUpdate upload: space check - ota: %.1f MB available, required: %.1f MB",
		float64(otaAvailable)/(1<<20), float64(totalRequired)/(1<<20))

	if otaAvailable < totalRequired {
		return fmt.Errorf("insufficient space on OTA filesystem: %.1f MB available, %.1f MB required",
			float64(otaAvailable)/(1<<20), float64(totalRequired)/(1<<20))
	}

	logger.Info("softwareUpdate upload: disk space validation passed - %.1f MB available in OTA directory",
		float64(otaAvailable)/(1<<20))
	return nil
}

// isMaxBytesError checks if an error is from http.MaxBytesReader exceeding the size limit
func isMaxBytesError(err error) bool {
	if err == nil {
		return false
	}

	// Check if it's specifically a *http.MaxBytesError
	var maxBytesErr *http.MaxBytesError
	if errors.As(err, &maxBytesErr) {
		return true
	}

	// Fallback: check error message for the typical MaxBytesReader message
	errMsg := err.Error()
	return strings.Contains(errMsg, "http: request body too large") ||
		strings.Contains(errMsg, "request body too large")
}
