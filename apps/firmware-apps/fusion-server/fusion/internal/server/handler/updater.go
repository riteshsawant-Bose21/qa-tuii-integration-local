package handler

import (
	"bytes"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"
)

const (
	compareBufferSize = 64 * 1024 // 64KB chunks
	MaxBackups        = 3
)

type Updater struct {
	updateMutex      sync.Mutex
	currentAssembler *BinaryAssembler
	currentUpdate    *BinaryUpdate
}

func NewUpdater() *Updater {
	return &Updater{}
}

// PerformUpdate handles the mechanics of updating the binary
func (u *Updater) PerformUpdate(newBinaryPath string) error {
	if !u.updateMutex.TryLock() {
		return errors.New("update already in progress")
	}
	defer u.updateMutex.Unlock()

	logger := logging.GetLogger()

	// Wait for existing requests to complete
	time.Sleep(5 * time.Second)
	logger.Info("Updating fusion-server")

	// Get the current binary path
	currentBinaryPath, err := os.Executable()
	if err != nil {
		return fmt.Errorf("failed to get current binary path: %v", err)
	}

	// Create backup of current binary
	if err := u.CreateBackup(currentBinaryPath); err != nil {
		return fmt.Errorf("backup creation failed: %v", err)
	}

	// Setup rollback in case of failure
	var needsRollback bool
	defer func() {
		if needsRollback {
			if err := u.PerformRollback(currentBinaryPath, -1); err != nil {
				logger.Error("Rollback failed: %v", err)
			}
		}
	}()

	// Move new binary into place
	if err := os.Rename(newBinaryPath, currentBinaryPath); err != nil {
		needsRollback = true
		return fmt.Errorf("failed to install update: %v", err)
	}

	// Make the new binary executable
	if err := os.Chmod(currentBinaryPath, 0755); err != nil {
		needsRollback = true
		return fmt.Errorf("failed to make binary executable: %v", err)
	}

	// Try to run the new binary to verify it works
	cmd := exec.Command(currentBinaryPath, "--help")
	if err := cmd.Run(); err != nil {
		needsRollback = true
		return fmt.Errorf("new binary verification failed: %v", err)
	}

	// Clean up old backups keeping only the 3 most recent
	if err := u.cleanupOldBackups(MaxBackups); err != nil {
		logger.Warn("Failed to cleanup old backups: %v", err)
		// Continue with restart as this is not critical
	}

	logger.Info("Restarting fusion-server")

	return syscall.Exec(currentBinaryPath, os.Args, os.Environ())
}

func (u *Updater) PerformRemoteUpdate(message api.VersionUpdate) error {

	logger := logging.GetLogger()

	switch message.Type {
	case VersionRollback:
		var rollback BinaryRollback
		if err := json.Unmarshal(message.Payload, &rollback); err != nil {
			return err
		}

		logger.Info("PerformRemoteUpdate: Rollback started")

		if err := u.PerformRollback(rollback.BinaryPath, rollback.Index); err != nil {
			return err
		}
		return nil

	case VersionUpdate:
		var update BinaryUpdate
		if err := json.Unmarshal(message.Payload, &update); err != nil {
			return err
		}
		u.currentAssembler = NewBinaryAssembler(update.BinarySize)
		u.currentUpdate = &update
		logger.Info("PerformRemoteUpdate: Update started")
		return nil

	case UpdateChunk:
		var chunk BinaryChunk
		if err := json.Unmarshal(message.Payload, &chunk); err != nil {
			return err
		}

		if u.currentAssembler == nil {
			return errors.New("no active binary update")
		}

		if err := u.currentAssembler.AddChunk(chunk); err != nil {
			return err
		}

		if u.currentAssembler.IsComplete() {
			logger.Info("PerformRemoteUpdate: Binary transfer complete")

			binary, err := u.currentAssembler.Assemble()
			if err != nil {
				return err
			}

			if err := u.handleBinaryUpdate(binary); err != nil {
				return err
			}
			return nil
		}

		return nil
	}

	return nil
}

func (u *Updater) IsValidRollbackIndex(index int) bool {
	if index > -1 || index < -MaxBackups {
		return false
	}
	return true
}

// PerformRollback rolls back to a specific backup version
func (u *Updater) PerformRollback(currentBinaryPath string, rollbackIndex int) error {

	logger := logging.GetLogger()

	logger.Info("Rolling back  %s to %d", currentBinaryPath, rollbackIndex)

	if !u.updateMutex.TryLock() {
		return errors.New("update already in progress")
	}
	defer u.updateMutex.Unlock()

	if !u.IsValidRollbackIndex(rollbackIndex) {
		return fmt.Errorf("rollback index must be between -%d and -1, got: %d", MaxBackups, rollbackIndex)
	}

	positiveIndex := -rollbackIndex - 1

	// Find all backups
	backups, err := u.findBackups(currentBinaryPath)
	if err != nil {
		return err
	}

	if len(backups) == 0 {
		return fmt.Errorf("no valid backups found for rollback")
	}

	if positiveIndex >= len(backups) {
		return fmt.Errorf("rollback index %d exceeds number of available backups (%d)", positiveIndex, len(backups))
	}

	// Create a temporary file for the rollback
	dir := filepath.Dir(currentBinaryPath)
	tmpRollback := filepath.Join(dir, ".tmp-rollback-"+filepath.Base(currentBinaryPath))

	// Copy the selected backup to a temporary file
	if err := u.copyAndVerifyBackup(backups[positiveIndex].path, tmpRollback); err != nil {
		return err
	}

	// If we get here, the backup is good. Perform the atomic rename
	if err := os.Rename(tmpRollback, currentBinaryPath); err != nil {
		os.Remove(tmpRollback)
		return fmt.Errorf("failed to install rollback: %v", err)
	}

	logging.GetLogger().Info("Successfully rolled back to backup from %v", time.Unix(0, backups[positiveIndex].timestamp))

	return syscall.Exec(currentBinaryPath, os.Args, os.Environ())
}

func (u *Updater) CreateBackup(binaryPath string) error {
	// Generate backup path with timestamp to avoid conflicts
	backupPath := binaryPath + fmt.Sprintf(".backup.%d", time.Now().UnixNano())

	// Create a temporary file in the same directory as the backup
	dir := filepath.Dir(backupPath)
	tmpBackup := filepath.Join(dir, ".tmp-"+filepath.Base(backupPath))

	// Copy the current binary to temporary file with restricted permissions
	if err := func() error {
		src, err := os.Open(binaryPath)
		if err != nil {
			return fmt.Errorf("failed to open current binary: %w", err)
		}
		defer src.Close()

		// Create temp file with restricted permissions
		dst, err := os.OpenFile(tmpBackup, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0600)
		if err != nil {
			return fmt.Errorf("failed to create temporary backup: %w", err)
		}
		defer dst.Close()

		// Copy with integrity check
		hash := sha256.New()
		writer := io.MultiWriter(dst, hash)

		if _, err := io.Copy(writer, src); err != nil {
			os.Remove(tmpBackup) // Clean up on failure
			return fmt.Errorf("failed to copy binary: %w", err)
		}

		// Ensure all data is written to disk
		if err := dst.Sync(); err != nil {
			os.Remove(tmpBackup)
			return fmt.Errorf("failed to sync backup file: %w", err)
		}

		return nil
	}(); err != nil {
		return err
	}

	// Atomic rename of temporary file to final backup location
	if err := os.Rename(tmpBackup, backupPath); err != nil {
		os.Remove(tmpBackup)
		return fmt.Errorf("failed to create backup: %w", err)
	}

	// Verify the backup
	if err := u.VerifyBackup(binaryPath, backupPath); err != nil {
		os.Remove(backupPath)
		return fmt.Errorf("backup verification failed: %w", err)
	}

	return nil
}

func (u *Updater) VerifyBackup(originalPath, backupPath string) error {
	original, err := os.Open(originalPath)
	if err != nil {
		return fmt.Errorf("failed to open original file: %w", err)
	}
	defer original.Close()

	backup, err := os.Open(backupPath)
	if err != nil {
		return fmt.Errorf("failed to open backup file: %w", err)
	}
	defer backup.Close()

	originalBuf := make([]byte, compareBufferSize)
	backupBuf := make([]byte, compareBufferSize)

	for {
		originalN, originalErr := original.Read(originalBuf)
		backupN, backupErr := backup.Read(backupBuf)

		if originalN != backupN {
			return errors.New("backup file size does not match original")
		}

		if !bytes.Equal(originalBuf[:originalN], backupBuf[:backupN]) {
			return errors.New("backup file contents do not match original")
		}

		if originalErr == io.EOF && backupErr == io.EOF {
			break
		}
		if originalErr != nil && originalErr != io.EOF {
			return fmt.Errorf("error reading original file: %w", originalErr)
		}
		if backupErr != nil && backupErr != io.EOF {
			return fmt.Errorf("error reading backup file: %w", backupErr)
		}
	}

	return nil
}

func (u *Updater) findBackups(binaryPath string) ([]struct {
	path      string
	timestamp int64
}, error) {
	dir := filepath.Dir(binaryPath)
	base := filepath.Base(binaryPath)
	files, err := os.ReadDir(dir)
	if err != nil {
		return nil, fmt.Errorf("failed to read directory during rollback: %v", err)
	}

	var backups []struct {
		path      string
		timestamp int64
	}

	backupPrefix := base + ".backup."
	for _, file := range files {
		if strings.HasPrefix(file.Name(), backupPrefix) {
			timestampStr := strings.TrimPrefix(file.Name(), backupPrefix)
			timestamp, err := strconv.ParseInt(timestampStr, 10, 64)
			if err != nil {
				logging.GetLogger().Warn("Ignoring backup with invalid timestamp during rollback: %s", file.Name())
				continue
			}
			backups = append(backups, struct {
				path      string
				timestamp int64
			}{
				path:      filepath.Join(dir, file.Name()),
				timestamp: timestamp,
			})
		}
	}

	// Sort backups by timestamp (newest first)
	sort.Slice(backups, func(i, j int) bool {
		return backups[i].timestamp > backups[j].timestamp
	})

	return backups, nil
}

func (u *Updater) copyAndVerifyBackup(sourcePath, destPath string) error {
	if err := func() error {
		src, err := os.Open(sourcePath)
		if err != nil {
			return fmt.Errorf("failed to open backup %s: %v", sourcePath, err)
		}
		defer src.Close()

		dst, err := os.OpenFile(destPath, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0600)
		if err != nil {
			return fmt.Errorf("failed to create temporary rollback file: %v", err)
		}
		defer dst.Close()

		if _, err := io.Copy(dst, src); err != nil {
			os.Remove(destPath)
			return fmt.Errorf("failed to copy backup: %v", err)
		}

		if err := dst.Sync(); err != nil {
			os.Remove(destPath)
			return fmt.Errorf("failed to sync rollback file: %v", err)
		}

		return nil
	}(); err != nil {
		return err
	}

	// Make the temporary file executable
	if err := os.Chmod(destPath, 0755); err != nil {
		os.Remove(destPath)
		return fmt.Errorf("failed to make rollback file executable: %v", err)
	}

	// Test the backup
	cmd := exec.Command(destPath, "--help")
	if err := cmd.Run(); err != nil {
		os.Remove(destPath)
		return fmt.Errorf("backup verification failed: %v", err)
	}

	return nil
}

// handleBinaryUpdate handles internal binary updates
func (u *Updater) handleBinaryUpdate(binary []byte) error {
	// Create a temporary file for the binary
	tempFile, err := os.CreateTemp("", "fusion-update-*")
	if err != nil {
		return fmt.Errorf("failed to create temporary file: %v", err)
	}

	if _, err := tempFile.Write(binary); err != nil {
		return fmt.Errorf("failed to write binary data: %v", err)
	}

	if err := tempFile.Close(); err != nil {
		return fmt.Errorf("failed to close temporary file: %v", err)
	}

	// Schedule the update
	go func() {
		if err := u.PerformUpdate(tempFile.Name()); err != nil {
			logging.GetLogger().Error("Update failed: %v", err)
		}
		os.Remove(tempFile.Name())
	}()

	return nil
}

func (u *Updater) cleanupOldBackups(keep int) error {
	binaryPath, err := os.Executable()
	if err != nil {
		return fmt.Errorf("failed to get binary path: %v", err)
	}

	dir := filepath.Dir(binaryPath)
	base := filepath.Base(binaryPath)
	files, err := os.ReadDir(dir)
	if err != nil {
		return fmt.Errorf("failed to read directory: %v", err)
	}

	// Filter and sort backup files by timestamp in filename
	var backups []struct {
		path      string
		timestamp int64
	}

	backupPrefix := base + ".backup."
	for _, file := range files {
		if strings.HasPrefix(file.Name(), backupPrefix) {
			timestampStr := strings.TrimPrefix(file.Name(), backupPrefix)
			timestamp, err := strconv.ParseInt(timestampStr, 10, 64)
			if err != nil {
				logging.GetLogger().Warn("Ignoring backup with invalid timestamp: %s", file.Name())
				continue
			}
			backups = append(backups, struct {
				path      string
				timestamp int64
			}{
				path:      filepath.Join(dir, file.Name()),
				timestamp: timestamp,
			})
		}
	}

	if len(backups) <= keep {
		return nil
	}

	// Sort backups by timestamp (newest first)
	sort.Slice(backups, func(i, j int) bool {
		return backups[i].timestamp > backups[j].timestamp
	})

	// Remove older backups
	for _, backup := range backups[keep:] {
		if err := os.Remove(backup.path); err != nil {
			return fmt.Errorf("failed to remove old backup %s: %v", backup.path, err)
		}
	}

	return nil
}
