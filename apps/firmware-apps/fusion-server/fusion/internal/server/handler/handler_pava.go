package handler

import (
	"crypto/rand"
	"errors"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/persistence"
	"fusion/internal/utils"
	"io"
	"mime"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	json "github.com/goccy/go-json"

	"github.com/oklog/ulid/v2"
)

// HandleAudioList returns all audio metadata, optionally filtered by one or more tags.
//
// Query params:
//
//	?tag=Emergencies&tag=Fire+Drill   -> return files that have *any* of those tags
func (h *Handler) HandleAudioList(w http.ResponseWriter, r *http.Request) {
	logger := logging.GetLogger()

	// Collect all tag query params
	tags := r.URL.Query()["tag"]
	normalizedTags := make([]string, 0, len(tags))
	for _, t := range tags {
		if s := strings.TrimSpace(t); s != "" {
			normalizedTags = append(normalizedTags, strings.ToLower(s))
		}
	}

	metas, err := h.persistence.ListAudioMetadata(r.Context())
	if err != nil {
		logger.Error("Error listing audio metadata: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	// If no tags provided, return everything
	if len(normalizedTags) == 0 {
		w.Header().Set("Content-Type", "application/json")
		if err := json.NewEncoder(w).Encode(metas); err != nil {
			logger.Error("Error encoding audio metadata list: %v", err)
			http.Error(w, "Server error", http.StatusInternalServerError)
		}
		return
	}

	// Filter
	filtered := make([]*persistence.AudioMetadata, 0, len(metas))
	for _, m := range metas {
		// Build a lowercase set of tags on the item
		itemTags := make(map[string]struct{}, len(m.Tags))
		for _, t := range m.Tags {
			itemTags[strings.ToLower(t)] = struct{}{}
		}

		// OR semantics: include if any requested tag is present
		match := false
		for _, wanted := range normalizedTags {
			if _, ok := itemTags[wanted]; ok {
				match = true
				break
			}
		}

		if match {
			filtered = append(filtered, m)
		}
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(filtered); err != nil {
		logger.Error("Error encoding filtered audio metadata list: %v", err)
	}
}

// HandleAudioUpload handles the upload of an audio file.
// Form field:
//
//	binary: 	  The file 	(required)
//	display_name: Name 		(optional
//			  	  Defaults to filename without extension
func (h *Handler) HandleAudioUpload(w http.ResponseWriter, r *http.Request) {
	logger := logging.GetLogger()

	// Limit overall body size
	r.Body = http.MaxBytesReader(w, r.Body, maxUploadBytes)

	// Reasonable memory cap for form parsing; adjust as needed.
	if err := r.ParseMultipartForm(maxFormSize); err != nil {
		logger.Error("Error parsing multipart form: %v", err)
		http.Error(w, "Error parsing form data", http.StatusBadRequest)
		return
	}

	file, header, err := r.FormFile("binary")
	if err != nil {
		logger.Error("Error reading form file \"binary\": %v", err)
		http.Error(w, "Missing file", http.StatusBadRequest)
		return
	}
	defer file.Close()

	// Basic validation / normalization
	origName := header.Filename
	ext := strings.ToLower(filepath.Ext(origName))
	if ext == "" {
		// Try to guess an extension from content-type later; for now require an ext.
		http.Error(w, "File extension required", http.StatusBadRequest)
		return
	}

	if !isAllowedAudioExt(ext) {
		http.Error(w, "Unsupported audio type", http.StatusUnsupportedMediaType)
		return
	}

	// Optional user-provided display name (fallback to original filename w/o ext).
	displayName := strings.TrimSpace(r.FormValue("display_name"))
	if displayName == "" {
		displayName = strings.TrimSuffix(origName, ext)
	}

	// Get the audio file using the display name
	existing, err := h.persistence.GetAudioByDisplayName(displayName)
	if err != nil {
		logger.Error("Error getting audio with display name: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	// Check if display name already exists
	if existing != nil {
		http.Error(w, "An audio file with this display name already exists", http.StatusConflict)
		return
	}

	// Create destination directory.
	if err := os.MkdirAll(api.AudioFilesLocation, 0755); err != nil {
		logger.Error("Error creating destination directory: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	// Generate stable ID and on-disk filename.
	id := newULID()
	onDiskName := id + ext

	// Write to a temporary file first, then atomically rename.
	tmp, err := os.CreateTemp(api.AudioFilesLocation, onDiskName+".*.part")
	if err != nil {
		logger.Error("Error creating temp destination: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	finalPath := filepath.Join(api.AudioFilesLocation, onDiskName)

	// Optionally sniff content type using the first 512 bytes.
	// We'll tee the first N bytes into a buffer for sniffing, then continue the copy.
	sniffBuf := make([]byte, 512)
	n, _ := io.ReadFull(file, sniffBuf) // n may be < 512 for small files
	// Write what we read into dst first
	if _, err := tmp.Write(sniffBuf[:n]); err != nil {
		tmp.Close()
		_ = os.Remove(tmp.Name())
		logger.Error("Error writing to temp file (sniff prewrite): %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	// Now copy the rest
	written, err := io.Copy(tmp, file)
	if err != nil {
		tmp.Close()
		_ = os.Remove(tmp.Name())
		logger.Error("Error copying file to destination: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	totalSize := int64(n) + written

	if err := tmp.Sync(); err != nil {
		tmp.Close()
		_ = os.Remove(tmp.Name())
		logger.Error("Error syncing temp file: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	if err := tmp.Close(); err != nil {
		_ = os.Remove(tmp.Name())
		logger.Error("Error closing temp file: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	// Determine MIME type
	mimeType := http.DetectContentType(sniffBuf[:n])
	if mimeType == "application/octet-stream" || mimeType == "" {
		// Try by extension
		if byExt := mime.TypeByExtension(ext); byExt != "" {
			mimeType = byExt
		}
	}

	// Move into place atomically.
	if err := os.Rename(tmp.Name(), finalPath); err != nil {
		_ = os.Remove(tmp.Name())
		logger.Error("Error renaming temp file into place: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	// Get the metadata tags
	tags := r.Form["tags"]
	normalized := make([]string, 0, len(tags))
	for _, t := range tags {
		if s := strings.TrimSpace(t); s != "" {
			normalized = append(normalized, s)
		}
	}

	// Build metadata record.
	meta := &persistence.AudioMetadata{
		Id:          id,
		OrigName:    origName,
		DisplayName: displayName,
		Filename:    onDiskName,
		MimeType:    mimeType,
		Uploaded:    time.Now().UTC(),
		SizeBytes:   totalSize,
		Tags:        normalized,
	}

	if err := h.persistence.SaveAudioMeta(meta); err != nil {
		logger.Error("Error storing audio metadata: %v", err)
		// Roll back file if DB write fails
		_ = os.Remove(finalPath)
		http.Error(w, "Error storing audio metadata", http.StatusInternalServerError)
		return
	}

	// Return created metadata
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	if err := json.NewEncoder(w).Encode(meta); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

// HandleAudioGet returns metadata for a single audio file.
func (h *Handler) HandleAudioGet(w http.ResponseWriter, r *http.Request) {
	id, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, "invalid id", http.StatusBadRequest)
		return
	}

	meta, err := h.persistence.GetAudioMetadata(id)
	if err != nil {
		http.Error(w, "not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(meta); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

// HandleAudioGet serves an audio file by ID with range support.
func (h *Handler) HandleAudioStream(w http.ResponseWriter, r *http.Request) {
	logger := logging.GetLogger()

	id, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, "invalid id", http.StatusBadRequest)
		return
	}

	meta, err := h.persistence.GetAudioMetadata(id)
	if err != nil {
		http.Error(w, "not found", http.StatusNotFound)
		return
	}

	filePath := filepath.Join(api.AudioFilesLocation, meta.Filename)
	f, err := os.Open(filePath)
	if err != nil {
		logger.Error("error opening audio file: %v", err)
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	defer f.Close()

	stat, err := f.Stat()
	if err != nil {
		http.Error(w, "server error", http.StatusInternalServerError)
		return
	}
	size := stat.Size()

	// Tell the client we can handle ranges
	w.Header().Set("Accept-Ranges", "bytes")
	w.Header().Set("Content-Type", canonicalMime(filepath.Ext(meta.Filename), meta.MimeType))

	// Check if client asked for a range
	if rng := r.Header.Get("Range"); rng != "" {
		// Example: "bytes=0-1023"
		start, end := int64(0), size-1
		if _, err := fmt.Sscanf(rng, "bytes=%d-%d", &start, &end); err != nil {
			http.Error(w, "invalid range", http.StatusRequestedRangeNotSatisfiable)
			return
		}
		if end >= size {
			end = size - 1
		}
		if start > end {
			http.Error(w, "invalid range", http.StatusRequestedRangeNotSatisfiable)
			return
		}
		length := end - start + 1

		w.Header().Set("Content-Range",
			fmt.Sprintf("bytes %d-%d/%d", start, end, size))
		w.Header().Set("Content-Length", fmt.Sprintf("%d", length))
		w.WriteHeader(http.StatusPartialContent)

		_, err = f.Seek(start, io.SeekStart)
		if err != nil {
			http.Error(w, "server error", http.StatusInternalServerError)
			return
		}
		_, _ = io.CopyN(w, f, length)
		return
	}

	// Fallback: send whole file
	w.Header().Set("Content-Length", fmt.Sprintf("%d", size))
	w.WriteHeader(http.StatusOK)
	_, _ = io.Copy(w, f)
}

// HandleAudioRemove deletes a previously uploaded audio file and its metadata.
func (h *Handler) HandleAudioRemove(w http.ResponseWriter, r *http.Request) {
	logger := logging.GetLogger()

	id, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Use the metadata to resolve the filename.
	meta, err := h.persistence.GetAudioMetadata(id)
	if err != nil {
		if errors.Is(err, persistence.ErrNotFound) {
			logger.Error("Error getting audio metadata for id %q: %v", id, err)
			http.Error(w, "Not found", http.StatusNotFound)
			return
		}
		logger.Error("Error reading audio metadata for id %q: %v", id, err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	if meta == nil {
		http.Error(w, "Audio metadata not found", http.StatusNotFound)
		return
	}

	destPath := filepath.Join(api.AudioFilesLocation, meta.Filename)
	if err := os.Remove(destPath); err != nil && !os.IsNotExist(err) {
		logger.Error("Error removing file %q: %v", destPath, err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	if err := h.persistence.DeleteAudioMetadata(id); err != nil {
		logger.Error("Error deleting audio metadata for id %q: %v", id, err)
		http.Error(w, "Error deleting audio metadata", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// HandleAudioTagList returns all unique tags present across audio files.
func (h *Handler) HandleAudioTagList(w http.ResponseWriter, r *http.Request) {
	logger := logging.GetLogger()

	tags, err := h.persistence.ListAllTags(r.Context())
	if err != nil {
		logger.Error("Error listing tags: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(tags); err != nil {
		logger.Error("Error encoding tag list: %v", err)
	}
}

// newULID generates a lexicographically sortable unique ID.
func newULID() string {
	entropy := ulid.Monotonic(rand.Reader, 0)
	return ulid.MustNew(ulid.Timestamp(time.Now()), entropy).String()
}

// isAllowedAudioExt returns true if audio type is allowed
func isAllowedAudioExt(ext string) bool {
	switch ext {
	case ".wav", ".mp3", ".flac", ".aac", ".ogg", ".m4a":
		return true
	default:
		return false
	}
}

// canonicalMime normalizes mime types to standard types
func canonicalMime(ext, sniffed string) string {
	// extension-based fallback
	switch strings.ToLower(ext) {
	case ".wav":
		return "audio/wav"
	case ".mp3":
		return "audio/mpeg"
	case ".flac":
		return "audio/flac"
	case ".ogg":
		return "audio/ogg"
	case ".aac":
		return "audio/aac"
	case ".m4a":
		return "audio/mp4"
	}

	// fix sniffed oddities
	switch sniffed {
	case "audio/wave", "audio/x-wav":
		return "audio/wav"
	case "audio/mpeg3", "audio/x-mpeg-3":
		return "audio/mpeg"
	}

	if sniffed != "" {
		return sniffed
	}
	return "application/octet-stream"
}
