package server

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"

	"github.com/hashicorp/memberlist"
)

// HandleVersionUpdate processes a multipart form upload containing a binary update,
// verifies the checksum, stores the binary temporarily, and initiates a version update across the cluster.
func (h *Handler) HandleVersionUpdate(w http.ResponseWriter, r *http.Request) {
	logger := logging.GetLogger()
	if err := r.ParseMultipartForm(32 << 20); err != nil {
		logger.Error("Error parsing multipart form: %v", err)
		http.Error(w, "Error parsing form data", http.StatusBadRequest)
		return
	}

	updateFile, header, err := r.FormFile("binary")
	if err != nil {
		logger.Error("Error reading binary: %v", err)
		http.Error(w, "Error reading binary", http.StatusBadRequest)
		return
	}
	defer updateFile.Close()

	if !VerifyChecksum(updateFile, r.FormValue("checksum")) {
		logger.Error("Invalid checksum")
		http.Error(w, "Invalid checksum", http.StatusBadRequest)
		return
	}

	if _, err := updateFile.Seek(0, 0); err != nil {
		logger.Error("Error resetting file pointer: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	tempPath := filepath.Join(os.TempDir(), header.Filename)
	tempFile, err := os.Create(tempPath)
	if err != nil {
		logger.Error("Error creating temporary file: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	defer tempFile.Close()

	if _, err := io.Copy(tempFile, updateFile); err != nil {
		logger.Error("Error moving binary to temporary file: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	if err := h.InitiateVersionUpdate(tempPath); err != nil {
		logger.Error("Failed to initiate cluster update: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	go func() {
		if err := h.updater.PerformUpdate(tempPath); err != nil {
			logger.Error("Update failed: %v", err)
		}
	}()
}

// HandleVersionRollback processes a rollback request using the provided index,
// verifies the rollback index, and initiates the rollback across the cluster.
func (h *Handler) HandleVersionRollback(w http.ResponseWriter, r *http.Request) {
	logger := logging.GetLogger()
	indexStr := r.URL.Query().Get("index")
	if indexStr == "" {
		logger.Error("No rollback index provided")
		http.Error(w, "Rollback index required", http.StatusBadRequest)
		return
	}

	index, err := strconv.Atoi(indexStr)
	if err != nil {
		logger.Error("Invalid rollback index: %v", err)
		http.Error(w, "Invalid rollback index", http.StatusBadRequest)
		return
	}

	if !h.updater.IsValidRollbackIndex(index) {
		logger.Error("Rollback index out of range: %d", index)
		http.Error(w, fmt.Sprintf("Rollback index must be between -%d and -1, got: %d", MaxBackups, index), http.StatusBadRequest)
		return
	}

	currentBinaryPath, err := os.Executable()
	if err != nil {
		logger.Error("Failed to get current binary path: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	if err := h.InitiateBinaryRollback(currentBinaryPath, index); err != nil {
		logger.Error("Failed to initiate cluster rollback: %v", err)
	}

	go func() {
		if err := h.updater.PerformRollback(currentBinaryPath, index); err != nil {
			logger.Error("Rollback failed: %v", err)
		}
	}()
}

// InitiateVersionUpdate prepares a version update message with binary metadata
// and streams the binary to all other nodes in the cluster.
func (h *Handler) InitiateVersionUpdate(newBinaryPath string) error {
	logger := logging.GetLogger()
	hash, size, err := getBinaryMetadata(newBinaryPath)
	if err != nil {
		return fmt.Errorf("failed to get binary metadata: %w", err)
	}

	update := BinaryUpdate{
		BinaryHeader: BinaryHeader{
			NodeID: h.memberlist.LocalNode().Name,
			Time:   time.Now().UTC(),
		},
		BinaryHash: hash,
		BinarySize: size,
	}

	data, err := json.Marshal(update)
	if err != nil {
		return fmt.Errorf("failed to marshal update: %w", err)
	}

	message := api.VersionMessage{
		Type:    VersionUpdate,
		Payload: data,
	}

	messageData, err := json.Marshal(message)
	if err != nil {
		return fmt.Errorf("failed to marshal message: %w", err)
	}

	h.broadcastToNodes(messageData)

	// Stream the binary to each node.
	for _, node := range h.memberlist.Members() {
		if node.Name == h.memberlist.LocalNode().Name {
			continue
		}
		if err := h.streamBinaryToNode(node, newBinaryPath); err != nil {
			logger.Error("Failed to stream binary to node %s: %v", node.Name, err)
		}
	}
	return nil
}

// InitiateBinaryRollback prepares a rollback message and broadcasts it to the cluster
// to trigger a coordinated rollback to a previous binary version.
func (h *Handler) InitiateBinaryRollback(currentBinaryPath string, index int) error {

	rollback := BinaryRollback{
		BinaryHeader: BinaryHeader{
			NodeID: h.memberlist.LocalNode().Name,
			Time:   time.Now().UTC(),
		},
		BinaryPath: currentBinaryPath,
		Index:      index,
	}

	data, err := json.Marshal(rollback)
	if err != nil {
		return fmt.Errorf("failed to marshal rollback: %w", err)
	}

	message := api.VersionMessage{
		Type:    VersionRollback,
		Payload: data,
	}

	messageData, err := json.Marshal(message)
	if err != nil {
		return fmt.Errorf("failed to marshal message: %w", err)
	}

	h.broadcastToNodes(messageData)
	return nil
}

// HandleAudioUpload handles the upload of an audio file, saving it to a fixed location,
// updating the internal configuration to include it, and applying that configuration.
func (h *Handler) HandleAudioUpload(w http.ResponseWriter, r *http.Request) {
	logger := logging.GetLogger()
	if err := r.ParseMultipartForm(32 << 20); err != nil {
		logger.Error("Error parsing multipart form: %v", err)
		http.Error(w, "Error parsing form data", http.StatusBadRequest)
		return
	}

	audioFile, header, err := r.FormFile("binary")
	if err != nil {
		logger.Error("Error reading binary: %v", err)
		http.Error(w, "Error reading binary", http.StatusBadRequest)
		return
	}
	defer audioFile.Close()

	destDir := "/var/lib/fusion/audio"
	destPath := filepath.Join(destDir, header.Filename)
	if err := os.MkdirAll(destDir, 0755); err != nil {
		logger.Error("Error creating destination directory: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	dstFile, err := os.Create(destPath)
	if err != nil {
		logger.Error("Error creating destination file: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	defer dstFile.Close()

	if _, err := io.Copy(dstFile, audioFile); err != nil {
		logger.Error("Error copying file to destination: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	existingData := TransformState(h.stateManager.GetFullState().State)
	addAudioFilesToConfig(destDir, existingData)
	if err := h.handleConfigUpdate(existingData); err != nil {
		logger.Error("Failed to handle audio config update: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
}

// getBinaryMetadata calculates the SHA-256 hash and size of the specified binary file.
// It returns the hex-encoded hash, file size in bytes, and any encountered error.
func getBinaryMetadata(path string) (hash string, size int64, err error) {
	file, err := os.Open(path)
	if err != nil {
		return "", 0, err
	}
	defer file.Close()

	hasher := sha256.New()
	size, err = io.Copy(hasher, file)
	if err != nil {
		return "", 0, err
	}
	return hex.EncodeToString(hasher.Sum(nil)), size, nil
}

// streamBinaryToNode sends a binary file in chunks to a specific node over the network,
// ending with a final chunk message to signal completion.
func (h *Handler) streamBinaryToNode(node *memberlist.Node, binaryPath string) error {
	const chunkSize = 1024 * 1024 // 1MB
	file, err := os.Open(binaryPath)
	if err != nil {
		return fmt.Errorf("failed to open binary: %w", err)
	}
	defer file.Close()

	buf := make([]byte, chunkSize)
	var offset int64
	for {
		n, err := file.Read(buf)
		if err == io.EOF {
			break
		}
		if err != nil {
			return fmt.Errorf("failed to read binary: %w", err)
		}

		chunk := BinaryChunk{
			Data:   buf[:n],
			Offset: offset,
			Final:  false,
		}
		offset += int64(n)

		chunkData, err := json.Marshal(chunk)
		if err != nil {
			return fmt.Errorf("failed to marshal chunk: %w", err)
		}

		message := api.VersionMessage{
			Type:    UpdateChunk,
			Payload: chunkData,
		}
		messageData, err := json.Marshal(message)
		if err != nil {
			return fmt.Errorf("failed to marshal message: %w", err)
		}

		if err := h.memberlist.SendReliable(node, messageData); err != nil {
			return fmt.Errorf("failed to send chunk message: %w", err)
		}
	}

	finalChunk := BinaryChunk{
		Data:   nil,
		Offset: offset,
		Final:  true,
	}
	chunkData, err := json.Marshal(finalChunk)
	if err != nil {
		return fmt.Errorf("failed to marshal final chunk: %w", err)
	}

	message := api.VersionMessage{
		Type:    UpdateChunk,
		Payload: chunkData,
	}
	messageData, err := json.Marshal(message)
	if err != nil {
		return fmt.Errorf("failed to marshal final message: %w", err)
	}
	if err := h.memberlist.SendReliable(node, messageData); err != nil {
		return fmt.Errorf("failed to send final chunk message: %w", err)
	}

	return nil
}

// addAudioFilesToConfig scans the provided directory for audio files and updates
// the existing configuration data map with their names and location.
func addAudioFilesToConfig(audioDir string, existingData map[string]any) {
	entries, err := os.ReadDir(audioDir)
	if err != nil {
		log.Printf("Error reading directory %s: %v", audioDir, err)
		return
	}
	var fileNames []string
	for _, entry := range entries {
		if !entry.IsDir() {
			fileNames = append(fileNames, entry.Name())
		}
	}
	existingData["audio_files"] = map[string]any{
		"location": audioDir,
		"files":    fileNames,
	}
}
