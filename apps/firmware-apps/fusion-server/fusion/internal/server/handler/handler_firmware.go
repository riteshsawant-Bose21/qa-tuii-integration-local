package handler

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
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
)

// writeFirmwareError writes a JSON error response for firmware endpoints.
func writeFirmwareError(w http.ResponseWriter, statusCode int, errMsg, detail string) {
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	w.WriteHeader(statusCode)
	_ = json.NewEncoder(w).Encode(api.FirmwareErrorResponse{Error: errMsg, Message: detail})
}

// HandleFirmwareUpload handles POST /firmware/upload.
//
// Multipart form fields:
//
//	firmware: The firmware bundle as a .swu file (required).
//	checksum: Expected SHA-256 hex digest for integrity validation (required).
func (h *Handler) HandleFirmwareUpload(w http.ResponseWriter, r *http.Request) {
	logger := logging.GetLogger()
	start := time.Now()
	ctx := r.Context()

	defer func() {
		duration := time.Since(start)
		logger.Debug("firmware upload: completed in %v", duration)
	}()

	logger.Info("firmware upload: processing upload on node %s", h.clusterTransport.LocalNode().Name)

	// Check available disk space based on Content-Length header
	if contentLength := r.ContentLength; contentLength > 0 {
		if err := checkDiskSpace(contentLength, logger); err != nil {
			logger.Error("firmware upload: disk space check failed: %v", err)
			writeFirmwareError(w, http.StatusInsufficientStorage, "insufficient_storage", err.Error())
			return
		}
		logger.Debug("firmware upload: disk space check passed for %d bytes upload", contentLength)
	}

	r.Body = http.MaxBytesReader(w, r.Body, api.MaxFirmwareUploadBytes)

	contentType := r.Header.Get("Content-Type")
	_, params, err := mime.ParseMediaType(contentType)
	if err != nil {
		logger.Error("firmware upload: parse content type: %v", err)
		writeFirmwareError(w, http.StatusBadRequest, "invalid_content_type", "Invalid or missing multipart content type")
		return
	}

	boundary, ok := params["boundary"]
	if !ok {
		logger.Error("firmware upload: missing boundary in content type")
		writeFirmwareError(w, http.StatusBadRequest, "invalid_content_type", "Missing multipart boundary")
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
			logger.Error("firmware upload: read multipart part: %v", err)
			writeFirmwareError(w, http.StatusBadRequest, "invalid_form", "Error reading multipart form data")
			return
		}

		formName := part.FormName()
		switch formName {
		case "firmware":
			filename := part.FileName()
			if filename == "" {
				part.Close()
				continue
			}
			origName = filepath.Base(filename)

			// Process firmware data immediately to avoid memory buffering
			actualChecksum, written, tmpPath, err = h.processFirmwareStream(part, origName, ctx)
			part.Close()
			if err != nil {
				logger.Error("firmware upload: process firmware stream: %v", err)
				writeFirmwareError(w, http.StatusBadRequest, "invalid_form", "Error processing firmware file")
				return
			}
		case "checksum":
			checksumBytes, err := io.ReadAll(part)
			part.Close()
			if err != nil {
				logger.Error("firmware upload: read checksum: %v", err)
				writeFirmwareError(w, http.StatusBadRequest, "invalid_form", "Error reading checksum field")
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
		switch err.Error() {
		case "missing_firmware":
			writeFirmwareError(w, http.StatusBadRequest, "missing_field", `Missing "firmware" field (.swu file required)`)
		case "missing_checksum":
			writeFirmwareError(w, http.StatusBadRequest, "missing_field", `Missing "checksum" field (SHA-256 hex required)`)
		case "invalid_filename":
			writeFirmwareError(w, http.StatusBadRequest, "invalid_filename", "Filename is missing or invalid")
		case "invalid_file_type":
			writeFirmwareError(w, http.StatusBadRequest, "invalid_file_type", "Only .swu firmware files are allowed")
		default:
			writeFirmwareError(w, http.StatusBadRequest, "validation_error", "Upload validation failed")
		}
		return
	}

	// Sanitize filename
	origName = filepath.Base(origName)

	// Validate checksum
	if err := validateChecksum(actualChecksum, expectedChecksum); err != nil {
		cleanupTempFile(tmpPath, logger)
		logger.Error("firmware upload: checksum validation failed: %v", err)
		writeFirmwareError(w, http.StatusBadRequest, "checksum_mismatch", err.Error())
		return
	}

	// Check for existing file with same name and checksum to prevent duplicates
	finalPath = filepath.Join(api.FirmwareOTAPath, origName)
	logger.Debug("firmware upload: checking for existing file at %s", finalPath)
	if _, statErr := os.Stat(finalPath); statErr == nil {
		existingChecksum, csErr := utils.FileChecksum(finalPath)
		if csErr != nil {
			logger.Warn("firmware upload: could not checksum existing file %s: %v — proceeding with overwrite", finalPath, csErr)
		} else if strings.EqualFold(existingChecksum, actualChecksum) {
			logger.Info("firmware upload: %s already present with matching checksum %s — rejecting duplicate", origName, existingChecksum)
			// Clean up temp file
			os.Remove(tmpPath)
			writeFirmwareError(w, http.StatusConflict, "already_exists",
				"firmware file is already present on this node with the same checksum")
			return
		} else {
			// Different checksum — the bundle has been updated; allow overwrite.
			logger.Info("firmware upload: %s exists (checksum %s) but actual checksum differs (%s) — overwriting", origName, existingChecksum, actualChecksum)
		}
	} else {
		logger.Debug("firmware upload: no existing file at %s (%v) — proceeding", finalPath, statErr)
	}

	if duplicateFile, err := checkForCrossFilenameDuplicates(api.FirmwareOTAPath, actualChecksum, origName, logger); err != nil {
		cleanupTempFile(tmpPath, logger)
		writeFirmwareError(w, http.StatusInternalServerError, "server_error", "Failed to scan for duplicate content")
		return
	} else if duplicateFile != "" {
		logger.Info("firmware upload: identical content (checksum %s) already exists as %s — rejecting duplicate %s",
			actualChecksum, duplicateFile, origName)
		cleanupTempFile(tmpPath, logger)
		writeFirmwareError(w, http.StatusConflict, "already_exists",
			fmt.Sprintf("firmware content is already present with this checksum as file '%s'", duplicateFile))
		return
	}

	// Finalize upload by renaming from temp .part path to final filename in OTA directory
	if err := os.Rename(tmpPath, finalPath); err != nil {
		cleanupTempFile(tmpPath, logger)
		logger.Error("firmware upload: rename %s → %s failed: %v", tmpPath, finalPath, err)
		writeFirmwareError(w, http.StatusInternalServerError, "server_error", "Failed to finalize firmware file")
		return
	}

	logger.Info("firmware upload: bundle finalized at %s (%.1f MB, sha256=%s, duration=%v)",
		finalPath, float64(written)/(1<<20), actualChecksum, time.Since(start))

	uploadRate := float64(written) / (1024 * 1024) / time.Since(start).Seconds()
	logger.Info("firmware upload: upload rate: %.1f MB/s", uploadRate)

	uploaded := time.Now().UTC()
	resp := api.FirmwareUploadResponse{
		Filename:  origName,
		Checksum:  actualChecksum,
		SizeBytes: written,
		Uploaded:  uploaded,
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	w.WriteHeader(http.StatusCreated)
	if err := json.NewEncoder(w).Encode(resp); err != nil {
		logger.Error("firmware upload: json encode: %v", err)
	}

	logger.Info("[FirmwareUpload] Upload successful - now broadcasting to cluster for automatic distribution")

	// Broadcast firmware availability to cluster so followers can initiate download
	go func() {
		sourceIP := h.clusterTransport.LocalNode().Addr.String()

		update := &api.FirmwareSyncUpdate{
			Filename:  origName,
			Checksum:  actualChecksum,
			SizeBytes: written,
			Uploaded:  uploaded,
			SourceIP:  sourceIP,
		}

		msg := api.NewNotifyMessage(
			api.NotifyOpFirmwareAvailable,
			h.clusterTransport.LocalNode().Name,
			api.WithFirmwareUpdate(update),
		)

		if err := h.hub.BroadcastToNodes(msg); err != nil {
			logger.Error("firmware upload: broadcast gossip failed: %v", err)
		} else {
			logger.Info("firmware upload: broadcasted firmware_available for %s from %s", origName, sourceIP)
		}
	}()
}

// HandleFirmwareDownload serves GET /firmware/download/{filename}.
// This is the source endpoint that follower nodes HTTP-pull from when the
// VIP broadcasts a firmware_available gossip notification.
func (h *Handler) HandleFirmwareDownload(w http.ResponseWriter, r *http.Request) {
	logger := logging.GetLogger()
	logger.Info("[FirmwareDownload] Request from %s for %s", r.RemoteAddr, r.URL.Path)

	filename, err := utils.ExtractValue(r, "filename")
	if err != nil {
		logger.Error("[FirmwareDownload] Invalid filename parameter: %v", err)
		writeFirmwareError(w, http.StatusBadRequest, "invalid_filename", "Filename is missing or invalid")
		return
	}

	logger.Info("[FirmwareDownload] Requested file: %s", filename)

	filePath := filepath.Join(api.FirmwareOTAPath, filename)
	logger.Info("[FirmwareDownload] Looking for file at: %s", filePath)

	f, err := os.Open(filePath)
	if err != nil {
		if os.IsNotExist(err) {
			logger.Error("[FirmwareDownload] File not found: %s", filePath)
			writeFirmwareError(w, http.StatusNotFound, "not_found",
				"firmware bundle not found")
			return
		}
		logger.Error("firmware download: open %s: %v", filePath, err)
		writeFirmwareError(w, http.StatusInternalServerError, "server_error", "Failed to open firmware bundle")
		return
	}
	defer f.Close()

	info, err := f.Stat()
	if err != nil {
		logger.Error("firmware download: stat %s: %v", filePath, err)
		writeFirmwareError(w, http.StatusInternalServerError, "server_error", "Failed to stat firmware bundle")
		return
	}

	logger.Info("[FirmwareDownload] Serving file: %s (%.1f MB)", filename, float64(info.Size())/(1<<20))

	w.Header().Set("Content-Type", "application/octet-stream")
	w.Header().Set("Content-Disposition", "attachment; filename=\""+filename+"\"")
	w.Header().Set("Content-Length", strconv.FormatInt(info.Size(), 10))

	if _, err := io.Copy(w, f); err != nil {
		logger.Error("firmware download: stream %s: %v", filePath, err)
	}
}

// HandleFirmwareList serves GET /firmware/list.
// Returns all firmware bundles present in /mnt/ota as []api.FirmwareSyncUpdate.
// Called by joining nodes to perform initial firmware sync from a peer.
func (h *Handler) HandleFirmwareList(w http.ResponseWriter, r *http.Request) {
	logger := logging.GetLogger()

	entries, err := os.ReadDir(api.FirmwareOTAPath)
	if err != nil {
		if os.IsNotExist(err) {
			// No firmware directory yet — return empty list
			w.Header().Set(api.ContentType, api.JsonMIMEType)
			w.Write([]byte("[]"))
			return
		}
		logger.Error("firmware list: readdir %s: %v", api.FirmwareOTAPath, err)
		writeFirmwareError(w, http.StatusInternalServerError, "server_error", "Failed to list firmware directory")
		return
	}

	sourceIP := h.clusterTransport.LocalNode().Addr.String()

	var bundles []api.FirmwareSyncUpdate
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		name := entry.Name()
		if strings.HasSuffix(name, ".part") {
			continue
		}
		fullPath := filepath.Join(api.FirmwareOTAPath, name)

		info, err := entry.Info()
		if err != nil {
			logger.Warn("firmware list: stat %s: %v — skipping", fullPath, err)
			continue
		}

		checksum, err := utils.FileChecksum(fullPath)
		if err != nil {
			logger.Warn("firmware list: checksum %s: %v — skipping", fullPath, err)
			continue
		}

		bundles = append(bundles, api.FirmwareSyncUpdate{
			Filename:  name,
			Checksum:  checksum,
			SizeBytes: info.Size(),
			Uploaded:  info.ModTime().UTC(),
			SourceIP:  sourceIP,
		})
	}

	if bundles == nil {
		bundles = []api.FirmwareSyncUpdate{}
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	if err := json.NewEncoder(w).Encode(bundles); err != nil {
		logger.Error("firmware list: json encode: %v", err)
	}
}

// processFirmwareStream processes a firmware file stream directly to disk without buffering in memory
func (h *Handler) processFirmwareStream(part *multipart.Part, origName string, ctx context.Context) (checksum string, written int64, tmpPath string, err error) {
	logger := logging.GetLogger()

	// Create OTA directory for staging uploads directly
	if err = os.MkdirAll(api.FirmwareOTAPath, 0755); err != nil {
		logger.Error("firmware upload: mkdir %s: %v", api.FirmwareOTAPath, err)
		return "", 0, "", fmt.Errorf("failed to create OTA directory: %w", err)
	}

	// Clean up any existing stale .part files in OTA directory
	cleanupStalePartFiles(api.FirmwareOTAPath, logger)

	tmpFile, err := os.CreateTemp(api.FirmwareOTAPath, origName+".*.part")
	if err != nil {
		logger.Error("firmware upload: create temp file: %v", err)
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
		logger.Error("firmware upload: write to %s failed: %v", tmpPath, copyErr)
		return "", 0, "", fmt.Errorf("failed to write firmware data: %w", copyErr)
	}
	if closeErr != nil {
		os.Remove(tmpPath)
		logger.Error("firmware upload: close %s failed: %v", tmpPath, closeErr)
		return "", 0, "", fmt.Errorf("failed to close temp file: %w", closeErr)
	}

	// Validate written size
	if written == 0 {
		os.Remove(tmpPath)
		return "", 0, "", fmt.Errorf("no data written to temp file")
	}

	checksum = hex.EncodeToString(hasher.Sum(nil))
	logger.Debug("firmware upload: streaming completed to OTA directory - %d bytes written, checksum: %s", written, checksum)
	return checksum, written, tmpPath, nil
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
		return fmt.Errorf("checksum mismatch: computed=%s, expected=%s", actual, expected)
	}
	return nil
}

// validateUploadFields validates all required fields for firmware upload
func validateUploadFields(origName, expectedChecksum string, logger *logging.Logger) error {
	if origName == "" {
		logger.Error("firmware upload: firmware file not found in multipart data")
		return fmt.Errorf("missing_firmware")
	}

	if expectedChecksum == "" {
		logger.Error("firmware upload: checksum field not found")
		return fmt.Errorf("missing_checksum")
	}

	origName = filepath.Base(origName)
	if origName == "" || origName == "." {
		logger.Error("firmware upload: invalid filename after sanitization")
		return fmt.Errorf("invalid_filename")
	}

	// Validate file extension for security
	if !strings.HasSuffix(strings.ToLower(origName), ".swu") {
		logger.Error("firmware upload: invalid file type - only .swu files allowed")
		return fmt.Errorf("invalid_file_type")
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

	logger.Debug("firmware upload: scanning %d entries in %s for duplicate content", len(entries), otaPath)
	for _, entry := range entries {
		if entry.IsDir() || entry.Name() == origName {
			continue
		}
		// Skip temporary .part files - these should already be cleaned up
		if strings.HasSuffix(entry.Name(), ".part") {
			logger.Debug("firmware upload: skipping temp file %s", entry.Name())
			continue
		}
		candidate := filepath.Join(otaPath, entry.Name())
		logger.Debug("firmware upload: checking candidate %s", candidate)
		candidateChecksum, csErr := utils.FileChecksum(candidate)
		if csErr != nil {
			logger.Debug("firmware upload: failed to checksum %s: %v", candidate, csErr)
			continue
		}
		logger.Debug("firmware upload: candidate %s has checksum %s, comparing against upload %s", entry.Name(), candidateChecksum, actualChecksum)
		if strings.EqualFold(candidateChecksum, actualChecksum) {
			return entry.Name(), nil // Found duplicate
		}
	}
	logger.Debug("firmware upload: no duplicate content found in %d existing files", len(entries))
	return "", nil
}

// cleanupTempFile safely removes temporary files
func cleanupTempFile(tmpPath string, logger *logging.Logger) {
	if tmpPath != "" {
		if err := os.Remove(tmpPath); err != nil && !os.IsNotExist(err) {
			logger.Warn("firmware upload: failed to cleanup temp file %s: %v", tmpPath, err)
		} else {
			logger.Debug("firmware upload: cleaned up temp file %s", tmpPath)
		}
	}
}

// cleanupStalePartFiles removes any stale .part files from directory
func cleanupStalePartFiles(dirPath string, logger *logging.Logger) {
	entries, readErr := os.ReadDir(dirPath)
	if readErr != nil {
		return // Directory might not exist yet
	}

	for _, entry := range entries {
		if strings.HasSuffix(entry.Name(), ".part") {
			staleFile := filepath.Join(dirPath, entry.Name())
			logger.Debug("firmware upload: cleaning up stale temp file %s", entry.Name())
			os.Remove(staleFile)
		}
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
	otaAvailable, _, err := getDiskUsage(api.FirmwareOTAPath)
	if err != nil {
		if parent := filepath.Dir(api.FirmwareOTAPath); parent != api.FirmwareOTAPath {
			otaAvailable, _, err = getDiskUsage(parent)
		}
		if err != nil {
			return fmt.Errorf("cannot determine disk space for OTA directory: %w", err)
		}
	}

	logger.Debug("firmware upload: space check - ota: %.1f MB available, required: %.1f MB",
		float64(otaAvailable)/(1<<20), float64(totalRequired)/(1<<20))

	if otaAvailable < totalRequired {
		return fmt.Errorf("insufficient space on OTA filesystem: %.1f MB available, %.1f MB required",
			float64(otaAvailable)/(1<<20), float64(totalRequired)/(1<<20))
	}

	logger.Info("firmware upload: disk space validation passed - %.1f MB available in OTA directory",
		float64(otaAvailable)/(1<<20))
	return nil
}
