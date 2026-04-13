package persistence

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/routes"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
)

var (
	ErrInvalidUpdate    = errors.New("software update sync validation failed")
	ErrDownloadFailed   = errors.New("software update download failed")
	ErrChecksumMismatch = errors.New("software update checksum validation failed")
	ErrInstallFailed    = errors.New("software update installation failed")
)

// SyncSoftwareUpdateFile pulls the software update bundle from the VIP node via HTTP,
// validates the SHA-256 checksum, and installs the bundle to /mnt/ota.
//
// Follower workflow:
//
//  1. HTTP-GET the bundle from the VIP node's /softwareUpdate/download/{filename}
//     endpoint and stream it directly into /mnt/ota/<filename>.*.part via io.Copy.
//
//  2. Verify the SHA-256 checksum of the received file against the value
//     advertised in the gossip notification.
//
//  3. Atomic rename from .part file to final /mnt/ota/<filename>.
//     Temp file is in the same directory as final path
func (p *Persistence) SyncSoftwareUpdateFile(update *api.SoftwareUpdateSync) error {
	logger := logging.GetLogger()

	// Validate required fields
	if update.SourceIP == "" {
		return fmt.Errorf("%w: SourceIP cannot be empty", ErrInvalidUpdate)
	}
	if update.Filename == "" {
		return fmt.Errorf("%w: Filename cannot be empty", ErrInvalidUpdate)
	}
	if update.Checksum == "" {
		return fmt.Errorf("%w: Checksum cannot be empty", ErrInvalidUpdate)
	}

	logger.Info("[SoftwareUpdateSync] Starting sync: filename=%s, sourceIP=%s, checksum=%s",
		update.Filename, update.SourceIP, update.Checksum)

	finalPath := filepath.Join(api.SoftwareUpdateOTAPath, update.Filename)

	// ------------------------------------------------------------------
	// Step 1 – stream bundle from VIP into /mnt/ota/<filename>.*.part
	// Temp file is in the same directory as the final path, so os.Rename
	// SHA-256 computed inline via io.TeeReader
	// ------------------------------------------------------------------
	if err := os.MkdirAll(api.SoftwareUpdateOTAPath, 0755); err != nil {
		return fmt.Errorf("%w: failed to create OTA directory %s: %w", ErrInstallFailed, api.SoftwareUpdateOTAPath, err)
	}

	downloadPath := strings.Replace(routes.SoftwareUpdateDownloadEndpoint, "{filename}", update.Filename, 1)
	downloadURL := fmt.Sprintf("http://%s:%s%s", update.SourceIP, api.HTTPPort, downloadPath)

	// Create HTTP client with timeout
	client := &http.Client{
		Timeout: api.HTTPUploadTimeout,
	}

	resp, err := client.Get(downloadURL)
	if err != nil {
		logger.Error("[SoftwareUpdate] HTTP GET failed for %s: %v", downloadURL, err)
		return fmt.Errorf("%w: failed to download from %s: %w", ErrDownloadFailed, downloadURL, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("%w: server returned status %d from %s: %s",
			ErrDownloadFailed, resp.StatusCode, downloadURL, string(body))
	}

	tmp, err := os.CreateTemp(api.SoftwareUpdateOTAPath, update.Filename+".*.part")
	if err != nil {
		return fmt.Errorf("%w: failed to create temp file: %w", ErrInstallFailed, err)
	}
	tempPath := tmp.Name()

	hasher := sha256.New()
	cleanup := func(err error) error {
		tmp.Close()
		os.Remove(tempPath)
		return fmt.Errorf("%w: %w", ErrInstallFailed, err)
	}

	if _, err := io.Copy(tmp, io.TeeReader(resp.Body, hasher)); err != nil {
		return cleanup(fmt.Errorf("failed to copy software update data to %s: %w", tempPath, err))
	}
	if err := tmp.Sync(); err != nil {
		return cleanup(fmt.Errorf("failed to sync temp file %s: %w", tempPath, err))
	}
	if err := tmp.Close(); err != nil {
		return cleanup(fmt.Errorf("failed to close temp file %s: %w", tempPath, err))
	}

	// ------------------------------------------------------------------
	// Step 2 – verify SHA-256 checksum
	// ------------------------------------------------------------------
	actualChecksum := hex.EncodeToString(hasher.Sum(nil))
	if !strings.EqualFold(actualChecksum, update.Checksum) {
		os.Remove(tempPath)
		return fmt.Errorf("%w: file %s checksum mismatch - got %s, want %s",
			ErrChecksumMismatch, update.Filename, actualChecksum, update.Checksum)
	}

	// ------------------------------------------------------------------
	// Step 3 – atomic rename: .part → /mnt/ota/<filename>
	// ------------------------------------------------------------------
	if err := os.Rename(tempPath, finalPath); err != nil {
		os.Remove(tempPath)
		return fmt.Errorf("%w: failed to install software update %s → %s: %w",
			ErrInstallFailed, tempPath, finalPath, err)
	}

	return nil
}
