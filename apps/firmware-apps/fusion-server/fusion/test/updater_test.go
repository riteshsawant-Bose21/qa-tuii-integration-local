//go:build exclude

package main

import (
	"crypto/sha256"
	"fmt"
	"fusion/internal/logging"
	"fusion/internal/server"
	"fusion/internal/server/handler"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"testing"
	"time"
)

// Create a package variable for mocking
var executablePath = os.Executable

func init() {
	logging.InitLogger(logging.LogConfig{
		NodeName:    "updater_test",
		LogDir:      "/tmp/updater_test",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logging.ERROR,
	})
}

// Integration test for the entire update process
func TestPerformUpdate(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping test in short mode")
	}

	// Determine the correct binary name based on runtime.GOOS and runtime.GOARCH
	var binaryName string
	switch runtime.GOOS {
	case "darwin":
		binaryName = fmt.Sprintf("fusion-server_darwin_%s", runtime.GOARCH)
	case "linux":
		binaryName = fmt.Sprintf("fusion-server_linux_%s", runtime.GOARCH)
	default:
		t.Fatalf("Unsupported OS: %s", runtime.GOOS)
	}

	buildBinaryPath := filepath.Join("../../build", binaryName)
	// Verify the binary exists and is executable
	if _, err := os.Stat(buildBinaryPath); err != nil {
		t.Fatalf("Build binary not found at %s: %v", buildBinaryPath, err)
	}

	// Create test directories
	testDir := filepath.Join("build", "test-update")
	if err := os.MkdirAll(testDir, 0755); err != nil {
		t.Fatalf("Failed to create test directory: %v", err)
	}
	defer os.RemoveAll(testDir)

	// Copy the actual build binary as our "current" binary
	currentBinary := filepath.Join(testDir, "current-binary")
	if err := copyExecutable(buildBinaryPath, currentBinary); err != nil {
		t.Fatalf("Failed to copy current binary: %v", err)
	}

	// Copy the build binary again as our "new" binary
	newBinary := filepath.Join(testDir, "new-binary")
	if err := copyExecutable(buildBinaryPath, newBinary); err != nil {
		t.Fatalf("Failed to copy new binary: %v", err)
	}

	// Store the original executable path function
	originalExecutable := executablePath

	// Mock the executable path
	executablePath = func() (string, error) {
		return currentBinary, nil
	}

	// Restore the original after the test
	defer func() {
		executablePath = originalExecutable
	}()

	// Create updater instance
	updater := server.NewUpdater()

	// Run update
	doneChan := make(chan error)
	go func() {
		err := updater.PerformUpdate(newBinary)
		doneChan <- err
	}()

	// Wait for update with timeout
	select {
	case err := <-doneChan:
		if err != nil {
			t.Fatalf("Update failed: %v", err)
		}
		// Verify the update succeeded
		_, err = os.Stat(currentBinary)
		if err != nil {
			t.Fatalf("Binary not found after update: %v", err)
		}
	case <-time.After(10 * time.Second):
		t.Fatal("Update timed out")
	}
}

func TestPerformRollback(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping test in short mode")
	}

	// Determine the binary name based on runtime.GOOS and runtime.GOARCH
	var binaryName string
	switch runtime.GOOS {
	case "darwin":
		binaryName = fmt.Sprintf("fusion-server_darwin_%s", runtime.GOARCH)
	case "linux":
		binaryName = fmt.Sprintf("fusion-server_linux_%s", runtime.GOARCH)
	default:
		t.Fatalf("Unsupported OS: %s", runtime.GOOS)
	}

	buildBinaryPath := filepath.Join("../../build", binaryName)
	if _, err := os.Stat(buildBinaryPath); err != nil {
		t.Fatalf("Build binary not found at %s: %v", buildBinaryPath, err)
	}

	// Create test directory
	testDir := filepath.Join("build", "test-rollback")
	if err := os.MkdirAll(testDir, 0755); err != nil {
		t.Fatalf("Failed to create test directory: %v", err)
	}
	defer os.RemoveAll(testDir)

	// Copy the build binary as our "current" binary
	currentBinaryPath := filepath.Join(testDir, "current-binary")
	if err := copyExecutable(buildBinaryPath, currentBinaryPath); err != nil {
		t.Fatalf("Failed to copy current binary: %v", err)
	}

	// Create updater instance
	updater := server.NewUpdater()

	// Create several backups with different timestamps
	backups := make([]string, 3)
	for i := range backups {
		// Sleep to ensure different timestamps
		time.Sleep(100 * time.Millisecond)
		backup, err := createBackup(currentBinaryPath, updater)
		if err != nil {
			t.Fatalf("Failed to create backup %d: %v", i, err)
		}
		backups[i] = backup
	}

	// Corrupt the current binary to simulate a failed update
	if err := os.WriteFile(currentBinaryPath, []byte("corrupted binary"), 0755); err != nil {
		t.Fatalf("Failed to corrupt current binary: %v", err)
	}

	// Store and mock the executable path
	originalExecutable := executablePath
	executablePath = func() (string, error) {
		return currentBinaryPath, nil
	}
	defer func() {
		executablePath = originalExecutable
	}()

	// Perform rollback
	doneChan := make(chan error)
	go func() {
		err := updater.PerformRollback(currentBinaryPath, -1)
		doneChan <- err
	}()

	// Wait for update with timeout
	select {
	case err := <-doneChan:
		if err != nil {
			t.Fatalf("Rollback failed: %v", err)
		}
		// Verify the update succeeded
		_, err = os.Stat(currentBinaryPath)
		if err != nil {
			t.Fatalf("Binary not found after rollback: %v", err)
		}
	case <-time.After(10 * time.Second):
		t.Fatal("Update timed out")
	}

	// Verify the current binary matches the most recent backup
	currentHash, err := getFileHash(currentBinaryPath)
	if err != nil {
		t.Fatalf("Failed to hash current binary: %v", err)
	}

	mostRecentBackupHash, err := getFileHash(backups[len(backups)-1])
	if err != nil {
		t.Fatalf("Failed to hash most recent backup: %v", err)
	}

	if currentHash != mostRecentBackupHash {
		t.Error("Current binary does not match most recent backup after rollback")
	}

	// Verify the current binary is executable
	info, err := os.Stat(currentBinaryPath)
	if err != nil {
		t.Fatalf("Failed to stat current binary: %v", err)
	}
	if info.Mode()&0111 == 0 {
		t.Error("Current binary is not executable after rollback")
	}

	// Try to execute the restored binary
	cmd := exec.Command(currentBinaryPath, "--help")
	if err := cmd.Run(); err != nil {
		t.Errorf("Restored binary failed to execute: %v", err)
	}
}

// Helper function to calculate file hash
func getFileHash(path string) (string, error) {
	file, err := os.Open(path)
	if err != nil {
		return "", fmt.Errorf("failed to open file: %w", err)
	}
	defer file.Close()

	hash := sha256.New()
	if _, err := io.Copy(hash, file); err != nil {
		return "", fmt.Errorf("failed to calculate hash: %w", err)
	}

	return fmt.Sprintf("%x", hash.Sum(nil)), nil
}

// Helper function to get the real path if it's a symlink
func getRealPath(path string) (string, error) {
	// Check if it's a symlink
	info, err := os.Lstat(path)
	if err != nil {
		return "", fmt.Errorf("failed to lstat path: %w", err)
	}

	// If it's a symlink, get the destination
	if info.Mode()&os.ModeSymlink != 0 {
		realPath, err := os.Readlink(path)
		if err != nil {
			return "", fmt.Errorf("failed to read symlink: %w", err)
		}
		// If the symlink path is relative, make it absolute
		if !filepath.IsAbs(realPath) {
			realPath = filepath.Join(filepath.Dir(path), realPath)
		}
		return realPath, nil
	}

	// If it's not a symlink, return original path
	return path, nil
}

func createBackup(currentBinaryPath string, updater *handler.Updater) (string, error) {
	// Get the real path if it's a symlink
	realBinaryPath, err := getRealPath(currentBinaryPath)
	if err != nil {
		return "", fmt.Errorf("failed to resolve real path: %w", err)
	}

	// Generate backup path with timestamp to avoid conflicts
	backupPath := currentBinaryPath + fmt.Sprintf(".backup.%d", time.Now().UnixNano())

	// Create a temporary file in the same directory as the backup
	dir := filepath.Dir(backupPath)
	tmpBackup := filepath.Join(dir, ".tmp-"+filepath.Base(backupPath))

	// Copy the current binary to temporary file with restricted permissions
	if err := func() error {
		src, err := os.Open(realBinaryPath) // Open the real file, not the symlink
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
		return "", err
	}

	// Atomic rename of temporary file to final backup location
	if err := os.Rename(tmpBackup, backupPath); err != nil {
		os.Remove(tmpBackup) // Clean up on failure
		return "", fmt.Errorf("failed to create backup: %w", err)
	}

	// Verify the backup
	if err := updater.VerifyBackup(realBinaryPath, backupPath); err != nil {
		os.Remove(backupPath)
		return "", fmt.Errorf("backup verification failed: %w", err)
	}

	return backupPath, nil
}

// Helper function to copy an executable while maintaining permissions
func copyExecutable(src, dst string) error {
	// Open source file
	sourceFile, err := os.Open(src)
	if err != nil {
		return fmt.Errorf("failed to open source: %w", err)
	}
	defer sourceFile.Close()

	// Get source file info for permissions
	sourceInfo, err := sourceFile.Stat()
	if err != nil {
		return fmt.Errorf("failed to stat source: %w", err)
	}

	// Create destination file with same permissions
	destFile, err := os.OpenFile(dst, os.O_RDWR|os.O_CREATE|os.O_TRUNC, sourceInfo.Mode())
	if err != nil {
		return fmt.Errorf("failed to create destination: %w", err)
	}
	defer destFile.Close()

	// Copy the content
	if _, err := io.Copy(destFile, sourceFile); err != nil {
		return fmt.Errorf("failed to copy content: %w", err)
	}

	return nil
}
