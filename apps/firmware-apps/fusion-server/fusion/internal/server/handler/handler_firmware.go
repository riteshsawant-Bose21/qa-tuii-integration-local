package handler

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/utils"
	"io"
	"mime"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"time"

	json "github.com/goccy/go-json"
)

const (
	maxFirmwareUploadBytes = 900 << 20 // 900 MB
	minAvailableMemoryMB   = 175       // Minimum 200MB available memory required
)

// firmwareUploadResponse is the JSON body returned after a successful firmware upload.
type firmwareUploadResponse struct {
	Filename  string    `json:"filename"`
	Checksum  string    `json:"checksum"`
	SizeBytes int64     `json:"size_bytes"`
	Uploaded  time.Time `json:"uploaded"`
}

// firmwareErrorResponse is the JSON body returned on firmware upload errors.
type firmwareErrorResponse struct {
	Error   string `json:"error"`
	Message string `json:"message,omitempty"`
}

// writeFirmwareError writes a JSON error response for firmware endpoints.
func writeFirmwareError(w http.ResponseWriter, statusCode int, errMsg, detail string) {
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	w.WriteHeader(statusCode)
	_ = json.NewEncoder(w).Encode(firmwareErrorResponse{Error: errMsg, Message: detail})
}

// checkMemoryAvailable verifies sufficient memory is available for upload
func checkMemoryAvailable(logger *logging.Logger, uploadSizeMB int64) error {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	// Check available memory from /proc/meminfo if on Linux
	if memInfo, err := os.ReadFile("/proc/meminfo"); err == nil {
		lines := strings.Split(string(memInfo), "\n")
		for _, line := range lines {
			if strings.HasPrefix(line, "MemAvailable:") {
				fields := strings.Fields(line)
				if len(fields) >= 2 {
					availKB, err := strconv.ParseInt(fields[1], 10, 64)
					if err == nil {
						availMB := availKB / 1024
						requiredMB := uploadSizeMB + minAvailableMemoryMB

						logger.Debug("Memory check: available=%dMB, required=%dMB (upload=%dMB + buffer=%dMB)",
							availMB, requiredMB, uploadSizeMB, minAvailableMemoryMB)

						if availMB < requiredMB {
							logger.Error("Insufficient memory: available %dMB, required %dMB", availMB, requiredMB)
							return errors.New("insufficient memory for upload")
						}
						return nil
					}
				}
				break
			}
		}
	}

	// Fallback: check Go runtime stats
	gcMemMB := int64(m.Sys-m.HeapReleased) / (1024 * 1024)
	requiredMB := uploadSizeMB + minAvailableMemoryMB

	logger.Debug("Memory check (fallback): Go mem=%dMB, required=%dMB", gcMemMB, requiredMB)

	// Conservative check: if we're using more than 80% of available memory
	if gcMemMB > 100 && requiredMB > gcMemMB/5 { // More than 20% of current usage
		logger.Error("Insufficient memory for upload: current usage %dMB, upload requires %dMB", gcMemMB, requiredMB)
		return errors.New("insufficient memory for upload")
	}

	return nil
}

// HandleFirmwareUpload handles POST /firmware/upload.
//
// Multipart form fields:
//
//	firmware: The firmware bundle as a .swu file (required).
//	checksum: Expected SHA-256 hex digest for integrity validation (required).
//
// Workflow on the receiving (VIP) node:
//  1. Write incoming bundle to /mnt/ota/<filename>.*.part (temp staging path).
//  2. Validate the SHA-256 checksum against the provided expected value.
//  3. Atomic rename from .part file to /mnt/ota/<original-filename>.
//  4. Broadcast a firmware_available gossip notification so every non-VIP follower
//     can initiate an HTTP download from this node via /firmware/download/{filename}.
func (h *Handler) HandleFirmwareUpload(w http.ResponseWriter, r *http.Request) {
	logger := logging.GetLogger()
	start := time.Now()
	ctx := r.Context()

	defer func() {
		duration := time.Since(start)
		logger.Debug("firmware upload: completed in %v", duration)
	}()

	logger.Info("firmware upload: processing upload on node %s", h.clusterTransport.LocalNode().Name)

	// Check available memory based on Content-Length header
	// COMMENTED OUT: Memory check disabled
	// if contentLength := r.ContentLength; contentLength > 0 {
	// 	uploadSizeMB := contentLength / (1024 * 1024)
	// 	if err := checkMemoryAvailable(logger, uploadSizeMB); err != nil {
	// 		logger.Error("firmware upload: pre-flight memory check failed: %v", err)
	// 		writeFirmwareError(w, http.StatusInsufficientStorage, "insufficient_memory",
	// 			"Upload rejected due to memory constraints")
	// 		return
	// 	}
	// 	logger.Debug("firmware upload: memory check passed for %dMB upload", uploadSizeMB)
	// }

	// Log upload start for performance monitoring

	r.Body = http.MaxBytesReader(w, r.Body, maxFirmwareUploadBytes)

	// Use streaming multipart reader for better memory efficiency
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

	var firmwareData []byte
	var origName string
	var expectedChecksum string

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

			// Read firmware data - we need to buffer it since multipart is sequential
			firmwareData, err = io.ReadAll(part)
			part.Close()
			if err != nil {
				logger.Error("firmware upload: read firmware data: %v", err)
				writeFirmwareError(w, http.StatusBadRequest, "invalid_form", "Error reading firmware file")
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

	if firmwareData == nil || origName == "" {
		logger.Error("firmware upload: firmware file not found in multipart data")
		writeFirmwareError(w, http.StatusBadRequest, "missing_field", `Missing "firmware" field (.swu file required)`)
		return
	}

	if expectedChecksum == "" {
		writeFirmwareError(w, http.StatusBadRequest, "missing_field", `Missing "checksum" field (SHA-256 hex required)`)
		return
	}

	origName = filepath.Base(origName)
	if origName == "" || origName == "." {
		writeFirmwareError(w, http.StatusBadRequest, "invalid_filename", "Filename is missing or invalid")
		return
	}

	// Validate file extension for security
	if !strings.HasSuffix(strings.ToLower(origName), ".swu") {
		writeFirmwareError(w, http.StatusBadRequest, "invalid_file_type", "Only .swu firmware files are allowed")
		return
	}

	// ------------------------------------------------------------------
	// Duplicate check – if the file already sits at /mnt/ota/<filename>
	// with the same checksum, reject the upload immediately.
	// ------------------------------------------------------------------
	finalPath := filepath.Join(api.FirmwareOTAPath, origName)
	logger.Debug("firmware upload: checking for existing file at %s", finalPath)
	if _, statErr := os.Stat(finalPath); statErr == nil {
		existingChecksum, csErr := utils.FileChecksum(finalPath)
		if csErr != nil {
			logger.Warn("firmware upload: could not checksum existing file %s: %v — proceeding with overwrite", finalPath, csErr)
		} else if strings.EqualFold(existingChecksum, expectedChecksum) {
			logger.Info("firmware upload: %s already present with matching checksum %s — rejecting duplicate", origName, existingChecksum)
			writeFirmwareError(w, http.StatusConflict, "already_exists",
				"firmware file is already present on this node with the same checksum")
			return
		} else {
			// Different checksum — the bundle has been updated; allow overwrite.
			logger.Info("firmware upload: %s exists (checksum %s) but request checksum differs (%s) — overwriting", origName, existingChecksum, expectedChecksum)
		}
	} else {
		logger.Debug("firmware upload: no existing file at %s (%v) — proceeding", finalPath, statErr)
	}

	// ------------------------------------------------------------------
	// Cross-filename duplicate check – scan existing files in FirmwareOTAPath
	// and reject if any file (under a different name) already has the same
	// checksum. This prevents re-uploading identical content with a new name.
	// ------------------------------------------------------------------
	if entries, readErr := os.ReadDir(api.FirmwareOTAPath); readErr == nil {
		for _, entry := range entries {
			if entry.IsDir() || entry.Name() == origName {
				continue
			}
			candidate := filepath.Join(api.FirmwareOTAPath, entry.Name())
			candidateChecksum, csErr := utils.FileChecksum(candidate)
			if csErr != nil {
				continue
			}
			if strings.EqualFold(candidateChecksum, expectedChecksum) {
				logger.Info("firmware upload: identical content (checksum %s) already exists as %s — rejecting duplicate %s",
					expectedChecksum, entry.Name(), origName)
				writeFirmwareError(w, http.StatusConflict, "already_exists",
					"firmware content is already present with this checksum")
				return
			}
		}
	}

	// ------------------------------------------------------------------
	// Step 1 – write bundle to /mnt/ota/<filename>.*.part
	// Temp file is in the same directory as the final path, so os.Rename
	// is always atomic — no cross-device copy needed.
	// Random suffix from os.CreateTemp prevents concurrent upload collision.
	// SHA-256 computed inline via io.TeeReader — no second file-read pass.
	// ------------------------------------------------------------------
	if err := os.MkdirAll(api.FirmwareOTAPath, 0755); err != nil {
		logger.Error("firmware upload: mkdir %s: %v", api.FirmwareOTAPath, err)
		writeFirmwareError(w, http.StatusInternalServerError, "server_error", "Failed to create OTA directory")
		return
	}

	tmpFile, err := os.CreateTemp(api.FirmwareOTAPath, origName+".*.part")
	if err != nil {
		logger.Error("firmware upload: create temp: %v", err)
		writeFirmwareError(w, http.StatusInternalServerError, "server_error", "Failed to create staging file")
		return
	}
	tempPath := tmpFile.Name()

	// Check context cancellation
	if err := ctx.Err(); err != nil {
		tmpFile.Close()
		os.Remove(tempPath)
		writeFirmwareError(w, http.StatusRequestTimeout, "upload_cancelled", "Upload was cancelled")
		return
	}

	initializer := strings.NewReader("")
	_ = initializer // Avoid unused variable

	hasher := sha256.New()
	// Write firmware data to temp file and compute hash simultaneously
	firmwareReader := bytes.NewReader(firmwareData)
	written, copyErr := io.CopyBuffer(tmpFile, io.TeeReader(firmwareReader, hasher), make([]byte, 1024*1024))
	// Skip explicit sync for performance - close() will ensure data is written
	closeErr := tmpFile.Close()

	if copyErr != nil {
		os.Remove(tempPath)
		logger.Error("firmware upload: write %s: %v", tempPath, copyErr)
		writeFirmwareError(w, http.StatusInternalServerError, "server_error", "Failed to write firmware to staging path")
		return
	}
	if closeErr != nil {
		os.Remove(tempPath)
		logger.Error("firmware upload: close %s: %v", tempPath, closeErr)
		writeFirmwareError(w, http.StatusInternalServerError, "server_error", "Failed to close staging file")
		return
	}

	// ------------------------------------------------------------------
	// Step 2 – validate SHA-256 checksum (computed inline during write)
	// ------------------------------------------------------------------
	actualChecksum := hex.EncodeToString(hasher.Sum(nil))
	if !strings.EqualFold(actualChecksum, expectedChecksum) {
		os.Remove(tempPath)
		logger.Error("firmware upload: checksum mismatch: got %s, want %s", actualChecksum, expectedChecksum)
		writeFirmwareError(w, http.StatusBadRequest, "checksum_mismatch",
			"checksum validation failed")
		return
	}

	// ------------------------------------------------------------------
	// Step 3 – atomic rename: .part → /mnt/ota/<filename>
	// Same filesystem as temp file — always succeeds without copy.
	// ------------------------------------------------------------------
	if err := os.Rename(tempPath, finalPath); err != nil {
		os.Remove(tempPath)
		logger.Error("firmware upload: rename %s → %s: %v", tempPath, finalPath, err)
		writeFirmwareError(w, http.StatusInternalServerError, "server_error", "Failed to move firmware to OTA path")
		return
	}

	logger.Info("firmware upload: bundle stored at %s (%.1f MB, sha256=%s, duration=%v)",
		finalPath, float64(written)/(1<<20), actualChecksum, time.Since(start))

	// Log performance metrics
	uploadRate := float64(written) / (1024 * 1024) / time.Since(start).Seconds()
	logger.Info("firmware upload: upload rate: %.1f MB/s", uploadRate)

	uploaded := time.Now().UTC()
	resp := firmwareUploadResponse{
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

	// ------------------------------------------------------------------
	// Step 4 – broadcast firmware_available gossip to cluster followers
	//
	// The gossip carries this node's IP so that followers know where to
	// HTTP download from (this node is expected to be the VIP).
	// ------------------------------------------------------------------
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
		logging.GetLogger().Error("firmware download: stream %s: %v", filePath, err)
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
