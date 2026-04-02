package main

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/routes"
	"io"
	"mime/multipart"
	"net/http"
	"strings"
	"testing"
	"time"

	json "github.com/goccy/go-json"
)

const (
	// Use same server address as audio tests
	softwareUpdateServerAddr = "http://192.168.2.100:8080"
)

// TestSoftwareUpdateUploadAndListSuccess uploads a valid .swu bundle, verifies 201 + metadata,
// then lists all updates and confirms the uploaded file is present.
func TestSoftwareUpdateUploadAndListSuccess(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	// Create a small test .swu bundle with unique content
	timestamp := time.Now().UnixNano()
	bundleName := fmt.Sprintf("test-bundle-v1.2.3-%d", timestamp)
	bundleData := makeTestSWUBundle(bundleName, 1024)
	filename := fmt.Sprintf("test-bundle-v1.2.3-%d.swu", timestamp)
	checksum := calculateSHA256(bundleData)

	// Upload the bundle
	resp := uploadSoftwareUpdate(t, ctx, softwareUpdateServerAddr, filename, bundleData, checksum, http.StatusCreated)

	if resp.Filename != filename {
		t.Errorf("unexpected filename: got %q want %q", resp.Filename, filename)
	}

	if !strings.EqualFold(resp.Checksum, checksum) {
		t.Errorf("unexpected checksum: got %q want %q", resp.Checksum, checksum)
	}

	if resp.SizeBytes != int64(len(bundleData)) {
		t.Errorf("unexpected size_bytes: got %d want %d", resp.SizeBytes, len(bundleData))
	}

	if resp.Uploaded.IsZero() {
		t.Error("uploaded timestamp should not be zero")
	}

	// List all software updates and verify our upload is present
	bundles := listSoftwareUpdates(t, ctx, softwareUpdateServerAddr)

	found := false
	for _, bundle := range bundles {
		if bundle.Filename == filename && strings.EqualFold(bundle.Checksum, checksum) {
			found = true
			if bundle.SizeBytes != int64(len(bundleData)) {
				t.Errorf("listed bundle size mismatch: got %d want %d", bundle.SizeBytes, len(bundleData))
			}
			break
		}
	}

	if !found {
		t.Errorf("uploaded bundle %s not found in list response", filename)
	}
}

// TestSoftwareUpdateUploadChecksumMismatch uploads a bundle with incorrect checksum and expects 400.
func TestSoftwareUpdateUploadChecksumMismatch(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	bundleData := makeTestSWUBundle("checksum-mismatch-test", 512)
	filename := "checksum-mismatch.swu"
	correctChecksum := calculateSHA256(bundleData)

	// Use a different checksum to trigger mismatch
	wrongChecksum := strings.Replace(correctChecksum, "a", "b", 1)

	uploadSoftwareUpdateExpectError(t, ctx, softwareUpdateServerAddr, filename, bundleData, wrongChecksum,
		http.StatusBadRequest, "checksum_mismatch")
}

// TestSoftwareUpdateUploadDuplicate uploads the same bundle twice and expects 409 on the second upload.
func TestSoftwareUpdateUploadDuplicate(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	// Create unique test data
	timestamp := time.Now().UnixNano()
	bundleName := fmt.Sprintf("duplicate-test-%d", timestamp)
	bundleData := makeTestSWUBundle(bundleName, 768)
	filename := fmt.Sprintf("duplicate-test-%d.swu", timestamp)
	checksum := calculateSHA256(bundleData)

	// First upload should succeed
	uploadSoftwareUpdate(t, ctx, softwareUpdateServerAddr, filename, bundleData, checksum, http.StatusCreated)

	// Second upload of same file should return 409
	uploadSoftwareUpdateExpectError(t, ctx, softwareUpdateServerAddr, filename, bundleData, checksum,
		http.StatusConflict, "already_exists")
}

// TestSoftwareUpdateUploadOversized tries to upload a file exceeding size limit and expects 413.
func TestSoftwareUpdateUploadOversized(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Create a bundle larger than the 300MB limit
	oversizedData := make([]byte, api.MaxSoftwareUpdateUploadBytes+1024) // Slightly over limit
	for i := range oversizedData {
		oversizedData[i] = byte(i % 256)
	}

	filename := "oversized.swu"
	checksum := calculateSHA256(oversizedData)

	uploadSoftwareUpdateExpectError(t, ctx, softwareUpdateServerAddr, filename, oversizedData, checksum,
		http.StatusRequestEntityTooLarge, "file_too_large")
}

// TestSoftwareUpdateUploadMissingFields tests various missing field scenarios.
func TestSoftwareUpdateUploadMissingFields(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	bundleData := makeTestSWUBundle("missing-fields-test", 256)

	tests := []struct {
		name            string
		includeBundle   bool
		includeChecksum bool
		filename        string
		expectedError   string
	}{
		{
			name:            "missing bundle",
			includeBundle:   false,
			includeChecksum: true,
			filename:        "test.swu",
			expectedError:   "missing_field",
		},
		{
			name:            "missing checksum",
			includeBundle:   true,
			includeChecksum: false,
			filename:        "test.swu",
			expectedError:   "missing_field",
		},
		{
			name:            "invalid file type",
			includeBundle:   true,
			includeChecksum: true,
			filename:        "test.txt",
			expectedError:   "invalid_file_type",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			uploadSoftwareUpdateMissingFields(t, ctx, softwareUpdateServerAddr, tt.filename, bundleData,
				tt.includeBundle, tt.includeChecksum, http.StatusBadRequest, tt.expectedError)
		})
	}
}

// TestSoftwareUpdateDownload tests downloading uploaded bundles and handling 404 for missing files.
func TestSoftwareUpdateDownload(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	// Upload a bundle to download with unique content
	timestamp := time.Now().UnixNano()
	bundleName := fmt.Sprintf("download-test-%d", timestamp)
	bundleData := makeTestSWUBundle(bundleName, 1024)
	filename := fmt.Sprintf("download-test-%d.swu", timestamp)
	checksum := calculateSHA256(bundleData)

	uploadSoftwareUpdate(t, ctx, softwareUpdateServerAddr, filename, bundleData, checksum, http.StatusCreated)

	// Download the uploaded bundle
	downloadedData := downloadSoftwareUpdate(t, ctx, softwareUpdateServerAddr, filename)

	if len(downloadedData) != len(bundleData) {
		t.Errorf("downloaded size mismatch: got %d want %d", len(downloadedData), len(bundleData))
	}

	downloadedChecksum := calculateSHA256(downloadedData)
	if !strings.EqualFold(downloadedChecksum, checksum) {
		t.Errorf("downloaded checksum mismatch: got %s want %s", downloadedChecksum, checksum)
	}

	if !bytes.Equal(downloadedData, bundleData) {
		t.Error("downloaded content does not match uploaded content")
	}
}

// TestSoftwareUpdateDownloadNotFound tries to download a nonexistent bundle and expects 404.
func TestSoftwareUpdateDownloadNotFound(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Try to download a file that doesn't exist
	nonexistentFile := "nonexistent-bundle.swu"

	downloadURL := fmt.Sprintf("%s%s", softwareUpdateServerAddr,
		strings.Replace(routes.SoftwareUpdateDownloadEndpoint, "{filename}", nonexistentFile, 1))

	req, err := http.NewRequestWithContext(ctx, "GET", downloadURL, nil)
	if err != nil {
		t.Fatalf("creating GET request failed: %v", err)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("GET download failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusNotFound {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("download returned %d, want 404; body=%s", resp.StatusCode, string(body))
	}

	var errorResp api.SoftwareUpdateErrorResponse
	if err := json.NewDecoder(resp.Body).Decode(&errorResp); err != nil {
		t.Fatalf("decoding error response failed: %v", err)
	}

	if errorResp.Error != "not_found" {
		t.Errorf("unexpected error type: got %q want %q", errorResp.Error, "not_found")
	}
}

// Helper functions

// uploadSoftwareUpdate uploads a software bundle and expects success.
func uploadSoftwareUpdate(t *testing.T, ctx context.Context, base, filename string, data []byte, checksum string, expectedStatus int) *api.SoftwareUpdateUploadResponse {
	t.Helper()

	var buf bytes.Buffer
	w := multipart.NewWriter(&buf)

	// Add the bundle file part
	fw, err := w.CreateFormFile("bundle", filename)
	if err != nil {
		t.Fatalf("CreateFormFile failed: %v", err)
	}

	if _, err := fw.Write(data); err != nil {
		t.Fatalf("writing file data failed: %v", err)
	}

	// Add checksum field
	if err := w.WriteField("checksum", checksum); err != nil {
		t.Fatalf("WriteField checksum failed: %v", err)
	}

	if err := w.Close(); err != nil {
		t.Fatalf("closing multipart writer failed: %v", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST",
		fmt.Sprintf("%s%s", base, routes.SoftwareUpdateUploadEndpoint), &buf)
	if err != nil {
		t.Fatalf("creating POST request failed: %v", err)
	}
	req.Header.Set("Content-Type", w.FormDataContentType())

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("POST %s failed: %v", routes.SoftwareUpdateUploadEndpoint, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != expectedStatus {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("POST %s returned %d, want %d; body=%s",
			routes.SoftwareUpdateUploadEndpoint, resp.StatusCode, expectedStatus, string(body))
	}

	var uploadResp api.SoftwareUpdateUploadResponse
	if err := json.NewDecoder(resp.Body).Decode(&uploadResp); err != nil {
		t.Fatalf("decoding upload response failed: %v", err)
	}

	return &uploadResp
}

// uploadSoftwareUpdateExpectError uploads a software bundle and expects an error response.
func uploadSoftwareUpdateExpectError(t *testing.T, ctx context.Context, base, filename string, data []byte,
	checksum string, expectedStatus int, expectedError string) {
	t.Helper()

	var buf bytes.Buffer
	w := multipart.NewWriter(&buf)

	fw, err := w.CreateFormFile("bundle", filename)
	if err != nil {
		t.Fatalf("CreateFormFile failed: %v", err)
	}

	if _, err := fw.Write(data); err != nil {
		t.Fatalf("writing file data failed: %v", err)
	}

	if err := w.WriteField("checksum", checksum); err != nil {
		t.Fatalf("WriteField checksum failed: %v", err)
	}

	if err := w.Close(); err != nil {
		t.Fatalf("closing multipart writer failed: %v", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST",
		fmt.Sprintf("%s%s", base, routes.SoftwareUpdateUploadEndpoint), &buf)
	if err != nil {
		t.Fatalf("creating POST request failed: %v", err)
	}
	req.Header.Set("Content-Type", w.FormDataContentType())

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("POST %s failed: %v", routes.SoftwareUpdateUploadEndpoint, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != expectedStatus {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("POST %s returned %d, want %d; body=%s",
			routes.SoftwareUpdateUploadEndpoint, resp.StatusCode, expectedStatus, string(body))
	}

	var errorResp api.SoftwareUpdateErrorResponse
	if err := json.NewDecoder(resp.Body).Decode(&errorResp); err != nil {
		t.Fatalf("decoding error response failed: %v", err)
	}

	if errorResp.Error != expectedError {
		t.Errorf("unexpected error type: got %q want %q", errorResp.Error, expectedError)
	}
}

// uploadSoftwareUpdateMissingFields tests uploads with missing fields.
func uploadSoftwareUpdateMissingFields(t *testing.T, ctx context.Context, base, filename string, data []byte,
	includeBundle, includeChecksum bool, expectedStatus int, expectedError string) {
	t.Helper()

	var buf bytes.Buffer
	w := multipart.NewWriter(&buf)

	if includeBundle {
		fw, err := w.CreateFormFile("bundle", filename)
		if err != nil {
			t.Fatalf("CreateFormFile failed: %v", err)
		}

		if _, err := fw.Write(data); err != nil {
			t.Fatalf("writing file data failed: %v", err)
		}
	}

	if includeChecksum {
		checksum := calculateSHA256(data)
		if err := w.WriteField("checksum", checksum); err != nil {
			t.Fatalf("WriteField checksum failed: %v", err)
		}
	}

	if err := w.Close(); err != nil {
		t.Fatalf("closing multipart writer failed: %v", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST",
		fmt.Sprintf("%s%s", base, routes.SoftwareUpdateUploadEndpoint), &buf)
	if err != nil {
		t.Fatalf("creating POST request failed: %v", err)
	}
	req.Header.Set("Content-Type", w.FormDataContentType())

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("POST %s failed: %v", routes.SoftwareUpdateUploadEndpoint, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != expectedStatus {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("POST %s returned %d, want %d; body=%s",
			routes.SoftwareUpdateUploadEndpoint, resp.StatusCode, expectedStatus, string(body))
	}

	var errorResp api.SoftwareUpdateErrorResponse
	if err := json.NewDecoder(resp.Body).Decode(&errorResp); err != nil {
		t.Fatalf("decoding error response failed: %v", err)
	}

	if errorResp.Error != expectedError {
		t.Errorf("unexpected error type: got %q want %q", errorResp.Error, expectedError)
	}
}

// listSoftwareUpdates gets the list of all software updates.
func listSoftwareUpdates(t *testing.T, ctx context.Context, base string) []api.SoftwareUpdateSync {
	t.Helper()

	req, err := http.NewRequestWithContext(ctx, "GET",
		fmt.Sprintf("%s%s", base, routes.SoftwareUpdateListEndpoint), nil)
	if err != nil {
		t.Fatalf("creating GET request failed: %v", err)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("GET %s failed: %v", routes.SoftwareUpdateListEndpoint, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("GET %s returned %d, want 200; body=%s",
			routes.SoftwareUpdateListEndpoint, resp.StatusCode, string(body))
	}

	var bundles []api.SoftwareUpdateSync
	if err := json.NewDecoder(resp.Body).Decode(&bundles); err != nil {
		t.Fatalf("decoding list response failed: %v", err)
	}

	return bundles
}

// downloadSoftwareUpdate downloads a software bundle by filename.
func downloadSoftwareUpdate(t *testing.T, ctx context.Context, base, filename string) []byte {
	t.Helper()

	downloadURL := fmt.Sprintf("%s%s", base,
		strings.Replace(routes.SoftwareUpdateDownloadEndpoint, "{filename}", filename, 1))

	req, err := http.NewRequestWithContext(ctx, "GET", downloadURL, nil)
	if err != nil {
		t.Fatalf("creating GET request failed: %v", err)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("GET download failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("download returned %d, want 200; body=%s", resp.StatusCode, string(body))
	}

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		t.Fatalf("reading download response failed: %v", err)
	}

	return data
}

// makeTestSWUBundle creates a test software update bundle with specified name and size.
func makeTestSWUBundle(bundleName string, sizeBytes int) []byte {
	if sizeBytes < 64 {
		sizeBytes = 64 // Minimum reasonable size
	}

	// Create a simple test bundle with a header-like structure
	bundle := make([]byte, sizeBytes)

	// Add a simple header pattern
	header := fmt.Sprintf("SWU-BUNDLE:%s", bundleName)
	copy(bundle, header)

	// Fill the rest with a pattern for easy verification
	for i := len(header); i < sizeBytes; i++ {
		bundle[i] = byte((i * 37) % 256)
	}

	return bundle
}

// calculateSHA256 calculates the SHA-256 checksum of data.
func calculateSHA256(data []byte) string {
	hasher := sha256.New()
	hasher.Write(data)
	return hex.EncodeToString(hasher.Sum(nil))
}

// TestSoftwareUpdateSyncAcrossNodes uploads a software update to the VIP and verifies
// it propagates correctly to all follower nodes in the cluster.
func TestSoftwareUpdateSyncAcrossNodes(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 45*time.Second)
	defer cancel()

	// Get cluster node URLs (excluding VIP)
	nodes := getSoftwareUpdateClusterNodeURLs(t, ctx, softwareUpdateServerAddr)

	// Create a test bundle with unique content
	timestamp := time.Now().UnixNano()
	bundleName := fmt.Sprintf("cluster-sync-test-%d", timestamp)
	bundleData := makeTestSWUBundle(bundleName, 2048) // Larger bundle for better verification
	filename := fmt.Sprintf("cluster-sync-test-%d.swu", timestamp)
	checksum := calculateSHA256(bundleData)

	// Upload to VIP
	uploadResp := uploadSoftwareUpdate(t, ctx, softwareUpdateServerAddr, filename, bundleData, checksum, http.StatusCreated)
	if uploadResp.Filename != filename {
		t.Fatalf("upload returned wrong filename: got %q want %q", uploadResp.Filename, filename)
	}

	// Wait for each follower node to sync the software update metadata
	for _, node := range nodes {
		waitForSoftwareUpdateMetadata(t, ctx, node, filename)
	}

	// Verify file content on each follower node matches the original
	for _, node := range nodes {
		verifySoftwareUpdateSynced(t, ctx, node, filename, bundleData, checksum)
	}
}

// waitForSoftwareUpdateMetadata waits for a software update file to appear in the list endpoint on a specific node.
func waitForSoftwareUpdateMetadata(t *testing.T, ctx context.Context, baseURL string, filename string) {
	ticker := time.NewTicker(500 * time.Millisecond)
	defer ticker.Stop()

	timeout := time.After(20 * time.Second)

	for {
		select {
		case <-ctx.Done():
			t.Fatalf("context canceled while waiting for software update metadata sync on %s", baseURL)
		case <-timeout:
			t.Fatalf("timeout waiting for software update filename=%s on %s", filename, baseURL)
		case <-ticker.C:
			if hasSoftwareUpdateMetadata(t, baseURL, filename) {
				return
			}
		}
	}
}

// hasSoftwareUpdateMetadata checks if a software update file exists in the list on a specific node.
func hasSoftwareUpdateMetadata(_ *testing.T, baseURL, filename string) bool {
	url := fmt.Sprintf("%s/softwareUpdate/list", baseURL)
	resp, err := http.Get(url)
	if err != nil {
		return false
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return false
	}

	var updates []api.SoftwareUpdateSync
	if err := json.NewDecoder(resp.Body).Decode(&updates); err != nil {
		return false
	}

	// Check if our filename is in the list
	for _, update := range updates {
		if update.Filename == filename {
			return true
		}
	}

	return false
}

// verifySoftwareUpdateSynced downloads a software update from a specific node and verifies
// the content and checksum match the expected values.
func verifySoftwareUpdateSynced(t *testing.T, ctx context.Context, baseURL, filename string, expectedData []byte, expectedChecksum string) {
	url := fmt.Sprintf("%s/softwareUpdate/download/%s", baseURL, filename)

	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		t.Fatalf("creating download request failed: %v", err)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("download from %s failed: %v", baseURL, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("download from %s returned %d; body=%s", baseURL, resp.StatusCode, string(body))
	}

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		t.Fatalf("reading download response from %s failed: %v", baseURL, err)
	}

	// Verify the content matches exactly
	if !bytes.Equal(data, expectedData) {
		t.Fatalf("content mismatch on node %s: expected %d bytes, got %d bytes", baseURL, len(expectedData), len(data))
	}

	// Verify checksum
	actualChecksum := calculateSHA256(data)
	if !strings.EqualFold(actualChecksum, expectedChecksum) {
		t.Fatalf("checksum mismatch on node %s: want=%s got=%s", baseURL, expectedChecksum, actualChecksum)
	}
}

// getSoftwareUpdateClusterNodeURLs returns URLs for all follower nodes (excluding the VIP).
// This is similar to getClusterNodeURLs in audio_test.go but specific to software update testing.
func getSoftwareUpdateClusterNodeURLs(t *testing.T, ctx context.Context, vipURL string) []string {
	req, err := http.NewRequestWithContext(ctx, "GET", vipURL+"/devices", nil)
	if err != nil {
		t.Fatalf("failed to create /devices request: %v", err)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("/devices request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("/devices returned %d: %s", resp.StatusCode, string(body))
	}

	var devices []api.DeviceInfo
	if err := json.NewDecoder(resp.Body).Decode(&devices); err != nil {
		t.Fatalf("failed to decode /devices: %v", err)
	}

	// Build the list of follower node URLs
	urls := make([]string, 0)
	for _, d := range devices {
		url := fmt.Sprintf("http://%s:8080", d.Address)

		// Skip VIP/primary node - we only test propagation to followers
		if d.IsPrimaryNode {
			continue
		}

		urls = append(urls, url)
	}

	if len(urls) == 0 {
		t.Fatalf("no follower nodes found via /devices (cluster propagation test requires multiple nodes)")
	}

	return urls
}
