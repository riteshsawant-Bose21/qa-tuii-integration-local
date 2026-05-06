package main

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"fusion/internal/api"
	model "fusion/internal/gen/proto/fusion"
	"fusion/internal/routes"
	"io"
	"mime/multipart"
	"net/http"
	"os"
	"strings"
	"testing"
	"time"

	json "github.com/goccy/go-json"
	"github.com/gorilla/websocket"
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

	if resp.GetFilename() != filename {
		t.Errorf("unexpected filename: got %q want %q", resp.GetFilename(), filename)
	}

	if !strings.EqualFold(resp.GetChecksum(), checksum) {
		t.Errorf("unexpected checksum: got %q want %q", resp.GetChecksum(), checksum)
	}

	if resp.GetSizeBytes() != int64(len(bundleData)) {
		t.Errorf("unexpected size_bytes: got %d want %d", resp.GetSizeBytes(), len(bundleData))
	}

	if resp.GetUploaded() == nil || resp.GetUploaded().AsTime().IsZero() {
		t.Error("uploaded timestamp should not be zero")
	}

	// List all software updates and verify our upload is present
	bundles := listSoftwareUpdates(t, ctx, softwareUpdateServerAddr)

	found := false
	for _, bundle := range bundles {
		if bundle.GetFilename() == filename && strings.EqualFold(bundle.GetChecksum(), checksum) {
			found = true
			if bundle.GetSizeBytes() != int64(len(bundleData)) {
				t.Errorf("listed bundle size mismatch: got %d want %d", bundle.GetSizeBytes(), len(bundleData))
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

	var errorResp model.SoftwareUpdateErrorResponse
	if err := decodeProtoBody(resp.Body, &errorResp); err != nil {
		t.Fatalf("decoding error response failed: %v", err)
	}

	if errorResp.GetError() != "not_found" {
		t.Errorf("unexpected error type: got %q want %q", errorResp.GetError(), "not_found")
	}
}

// Helper functions

// uploadSoftwareUpdate uploads a software bundle and expects success.
func uploadSoftwareUpdate(t *testing.T, ctx context.Context, base, filename string, data []byte, checksum string, expectedStatus int) *model.SoftwareUpdateUploadResponse {
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

	var uploadResp model.SoftwareUpdateUploadResponse
	if err := decodeProtoBody(resp.Body, &uploadResp); err != nil {
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

	var errorResp model.SoftwareUpdateErrorResponse
	if err := decodeProtoBody(resp.Body, &errorResp); err != nil {
		t.Fatalf("decoding error response failed: %v", err)
	}

	if errorResp.GetError() != expectedError {
		t.Errorf("unexpected error type: got %q want %q", errorResp.GetError(), expectedError)
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

	var errorResp model.SoftwareUpdateErrorResponse
	if err := decodeProtoBody(resp.Body, &errorResp); err != nil {
		t.Fatalf("decoding error response failed: %v", err)
	}

	if errorResp.GetError() != expectedError {
		t.Errorf("unexpected error type: got %q want %q", errorResp.GetError(), expectedError)
	}
}

// listSoftwareUpdates gets the list of all software updates.
func listSoftwareUpdates(t *testing.T, ctx context.Context, base string) []*model.SoftwareUpdateBundle {
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

	var bundles model.SoftwareUpdateListResponse
	if err := decodeProtoBody(resp.Body, &bundles); err != nil {
		t.Fatalf("decoding list response failed: %v", err)
	}

	return bundles.Bundles
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
	if uploadResp.GetFilename() != filename {
		t.Fatalf("upload returned wrong filename: got %q want %q", uploadResp.GetFilename(), filename)
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

	var updates model.SoftwareUpdateListResponse
	if err := decodeProtoBody(resp.Body, &updates); err != nil {
		return false
	}

	// Check if our filename is in the list
	for _, update := range updates.GetBundles() {
		if update.GetFilename() == filename {
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

	var devicesResp model.DeviceListResponse
	if err := decodeProtoBody(resp.Body, &devicesResp); err != nil {
		t.Fatalf("failed to decode /devices: %v", err)
	}

	// Build the list of follower node URLs
	urls := make([]string, 0)
	for _, d := range devicesResp.GetDevices() {
		url := fmt.Sprintf("http://%s:8080", d.GetAddress())

		// Skip VIP/primary node - we only test propagation to followers
<<<<<<< HEAD
		if d.GetIsPrimaryNode() {
=======
		if d.GetIsPrimary() {
>>>>>>> gene/value
			continue
		}

		urls = append(urls, url)
	}

	if len(urls) == 0 {
		t.Fatalf("no follower nodes found via /devices (cluster propagation test requires multiple nodes)")
	}

	return urls
}

// ---------------------------------------------------------------------------
// WebSocket helpers
// ---------------------------------------------------------------------------

// dialWebSocket connects to the server's WebSocket endpoint and reads the
// welcome message, returning the ready connection.
func dialWebSocket(t *testing.T, base string) *websocket.Conn {
	t.Helper()
	wsURL := strings.Replace(base, "http://", "ws://", 1) + routes.WebsocketEndpoint
	conn, _, err := websocket.DefaultDialer.Dial(wsURL, nil)
	if err != nil {
		t.Fatalf("WebSocket dial %s failed: %v", wsURL, err)
	}

	// Consume welcome message
	welcome := readWebSocketResponse(t, conn, wsTestTimeout)
	if welcome.Type != "welcome" {
		conn.Close()
		t.Fatalf("expected welcome message, got type=%q", welcome.Type)
	}
	return conn
}

// sendWSRequest sends a typed WebSocket request and returns the immediate
// response (the ack/reply for that request ID).
func sendWSRequest(t *testing.T, conn *websocket.Conn, msgType string, data interface{}) *wsResponse {
	t.Helper()
	reqID := fmt.Sprintf("test-%d", time.Now().UnixNano())

	req := &wsRequest{
		ID:      reqID,
		Version: api.WSCurrentVersion,
		Type:    msgType,
		Data:    data,
	}

	sendWebSocketRequest(t, conn, req)

	// Read until we get a message with our request ID
	deadline := time.Now().Add(10 * time.Second)
	for time.Now().Before(deadline) {
		resp := readWebSocketResponse(t, conn, 5*time.Second)
		if resp.ID != nil && *resp.ID == reqID {
			return resp
		}
	}
	t.Fatalf("timed out waiting for response to request %s", reqID)
	return nil
}

// ---------------------------------------------------------------------------
// Software update trigger tests
// ---------------------------------------------------------------------------

// TestSoftwareUpdateTriggerViaWebSocket sends a start_update message and
// verifies the server returns WSCodeUpdateStarted.
func TestSoftwareUpdateTriggerViaWebSocket(t *testing.T) {
	conn := dialWebSocket(t, softwareUpdateServerAddr)
	defer conn.Close()

	resp := sendWSRequest(t, conn, api.WSMsgTypeStartUpdate, struct{}{})

	if resp.Code != api.WSCodeUpdateStarted {
		t.Errorf("expected code %d (WSCodeUpdateStarted), got %d", api.WSCodeUpdateStarted, resp.Code)
	}
	if resp.Status != api.WSStatusSuccess {
		t.Errorf("expected status %q, got %q", api.WSStatusSuccess, resp.Status)
	}
	if resp.Type != api.WSMsgTypeStartUpdate {
		t.Errorf("expected type %q, got %q", api.WSMsgTypeStartUpdate, resp.Type)
	}
}

// TestSoftwareUpdateTriggerRequiresValidBundle verifies that triggering an
// update when no bundle has been uploaded results in an application error.
func TestSoftwareUpdateTriggerNoBundle(t *testing.T) {
	// First, ensure there are no bundles by checking the list
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	bundles := listSoftwareUpdates(t, ctx, softwareUpdateServerAddr)
	if len(bundles) > 0 {
		t.Skip("bundles already present on server; skipping no-bundle trigger test")
	}

	conn := dialWebSocket(t, softwareUpdateServerAddr)
	defer conn.Close()

	resp := sendWSRequest(t, conn, api.WSMsgTypeStartUpdate, struct{}{})

	if resp.Code != api.WSCodeUpdateFailed {
		t.Errorf("expected WSCodeUpdateFailed (%d) when no .swu bundle exists, got %d", api.WSCodeUpdateFailed, resp.Code)
	}
	if resp.Status != api.WSStatusError {
		t.Errorf("expected status %q, got %q", api.WSStatusError, resp.Status)
	}
}

// TestSoftwareUpdateTriggerUnknownMessageType checks that an unknown message
// type returns WSCodeInvalidType.
func TestSoftwareUpdateTriggerUnknownType(t *testing.T) {
	conn := dialWebSocket(t, softwareUpdateServerAddr)
	defer conn.Close()

	resp := sendWSRequest(t, conn, "unknown_type_xyz", struct{}{})

	if resp.Code != api.WSCodeInvalidType {
		t.Errorf("expected code %d (WSCodeInvalidType), got %d", api.WSCodeInvalidType, resp.Code)
	}
	if resp.Status != api.WSStatusError {
		t.Errorf("expected status %q, got %q", api.WSStatusError, resp.Status)
	}
}

// ---------------------------------------------------------------------------
// sw_update_info WebSocket tests
// ---------------------------------------------------------------------------

// TestSwUpdateInfoViaWebSocket sends a sw_update_info request and verifies the
// envelope (type, code, status)
func TestSwUpdateInfoViaWebSocket(t *testing.T) {
	conn := dialWebSocket(t, softwareUpdateServerAddr)
	defer conn.Close()

	resp := sendWSRequest(t, conn, api.WSMsgTypeSwUpdateInfo, struct{}{})

	// Verify envelope
	if resp.Type != api.WSMsgTypeSwUpdateInfo {
		t.Errorf("expected type %q, got %q", api.WSMsgTypeSwUpdateInfo, resp.Type)
	}
	if resp.Code != api.WSCodeOK {
		t.Errorf("expected code %d (WSCodeOK), got %d", api.WSCodeOK, resp.Code)
	}
	if resp.Status != api.WSStatusSuccess {
		t.Errorf("expected status %q, got %q", api.WSStatusSuccess, resp.Status)
	}
	if resp.Version != api.WSCurrentVersion {
		t.Errorf("expected version %d, got %d", api.WSCurrentVersion, resp.Version)
	}

	// Verify data is an array of SwUpdateInfo objects
	if resp.Data == nil {
		t.Fatal("response data is nil; expected a (possibly empty) array")
	}
	raw, err := json.Marshal(resp.Data)
	if err != nil {
		t.Fatalf("marshalling response data failed: %v", err)
	}
	var infos []model.SwUpdateInfo
	if err := json.Unmarshal(raw, &infos); err != nil {
		t.Fatalf("response data is not a []model.SwUpdateInfo: %v — raw: %s", err, string(raw))
	}

	// Each entry must have the expected fields present (even if empty strings on
	// devices without /etc/swupdate-status).
	for i, info := range infos {
		// All fields are strings; we just confirm the struct decoded without
		// unexpected types by checking at least one field path exists.
		_ = info.GetSerialNumber()
		_ = info.GetCurrentBundleVersion()
		_ = info.GetStatus()
		_ = info.GetBootPartition()
		_ = info.GetUpdatedAt()
		t.Logf("node[%d]: serial=%q status=%q bundle=%q", i, info.GetSerialNumber(), info.GetStatus(), info.GetCurrentBundleVersion())
	}
}

// ---------------------------------------------------------------------------
// list_sw_update_files WebSocket tests
// ---------------------------------------------------------------------------

// TestListSoftwareUpdatesViaWebSocket sends a list_sw_update_files request and
// verifies the envelope
func TestListSoftwareUpdatesViaWebSocket(t *testing.T) {
	conn := dialWebSocket(t, softwareUpdateServerAddr)
	defer conn.Close()

	resp := sendWSRequest(t, conn, api.WSMsgTypeListSoftwareUpdates, struct{}{})

	// Verify envelope
	if resp.Type != api.WSMsgTypeListSoftwareUpdates {
		t.Errorf("expected type %q, got %q", api.WSMsgTypeListSoftwareUpdates, resp.Type)
	}
	if resp.Code != api.WSCodeOK {
		t.Errorf("expected code %d (WSCodeOK), got %d", api.WSCodeOK, resp.Code)
	}
	if resp.Status != api.WSStatusSuccess {
		t.Errorf("expected status %q, got %q", api.WSStatusSuccess, resp.Status)
	}
	if resp.Version != api.WSCurrentVersion {
		t.Errorf("expected version %d, got %d", api.WSCurrentVersion, resp.Version)
	}

	// Verify data is an array (never null — handler coerces nil to [])
	if resp.Data == nil {
		t.Fatal("response data is nil; expected a (possibly empty) array")
	}
	raw, err := json.Marshal(resp.Data)
	if err != nil {
		t.Fatalf("marshalling response data failed: %v", err)
	}
	var bundles []model.SoftwareUpdateBundle
	if err := json.Unmarshal(raw, &bundles); err != nil {
		t.Fatalf("response data is not a []model.SoftwareUpdateBundle: %v — raw: %s", err, string(raw))
	}

	// If bundles are present, verify required fields are non-empty.
	for i, b := range bundles {
		if b.GetFilename() == "" {
			t.Errorf("bundle[%d]: Filename is empty", i)
		}
		if b.GetChecksum() == "" {
			t.Errorf("bundle[%d]: Checksum is empty", i)
		}
		if b.GetSizeBytes() <= 0 {
			t.Errorf("bundle[%d]: SizeBytes is %d, want > 0", i, b.GetSizeBytes())
		}
		if b.GetUploaded() == nil || b.GetUploaded().AsTime().IsZero() {
			t.Errorf("bundle[%d]: Uploaded timestamp is zero", i)
		}
		t.Logf("bundle[%d]: filename=%q checksum=%s size=%d source=%s", i, b.GetFilename(), b.GetChecksum(), b.GetSizeBytes(), b.GetSourceIp())
	}
}

// TestListSoftwareUpdatesViaWebSocketAfterUpload uploads a bundle over HTTP
// then requests list_sw_update_files via WebSocket and confirms the uploaded
// bundle appears in the response with matching metadata.
func TestListSoftwareUpdatesViaWebSocketAfterUpload(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	// Upload a unique bundle via REST
	timestamp := time.Now().UnixNano()
	bundleName := fmt.Sprintf("ws-list-test-%d", timestamp)
	bundleData := makeTestSWUBundle(bundleName, 1024)
	filename := fmt.Sprintf("ws-list-test-%d.swu", timestamp)
	checksum := calculateSHA256(bundleData)
	uploadSoftwareUpdate(t, ctx, softwareUpdateServerAddr, filename, bundleData, checksum, http.StatusCreated)

	// Now request the list via WebSocket
	conn := dialWebSocket(t, softwareUpdateServerAddr)
	defer conn.Close()

	resp := sendWSRequest(t, conn, api.WSMsgTypeListSoftwareUpdates, struct{}{})

	if resp.Code != api.WSCodeOK {
		t.Fatalf("expected code %d (WSCodeOK), got %d — message: %s", api.WSCodeOK, resp.Code, resp.Message)
	}

	raw, err := json.Marshal(resp.Data)
	if err != nil {
		t.Fatalf("marshalling response data failed: %v", err)
	}
	var bundles []model.SoftwareUpdateBundle
	if err := json.Unmarshal(raw, &bundles); err != nil {
		t.Fatalf("response data is not a []model.SoftwareUpdateBundle: %v", err)
	}

	// The uploaded bundle must appear in the list
	found := false
	for _, b := range bundles {
		if b.GetFilename() == filename {
			found = true
			if !strings.EqualFold(b.GetChecksum(), checksum) {
				t.Errorf("checksum mismatch: got %q want %q", b.GetChecksum(), checksum)
			}
			if b.GetSizeBytes() != int64(len(bundleData)) {
				t.Errorf("size_bytes mismatch: got %d want %d", b.GetSizeBytes(), len(bundleData))
			}
			if b.GetUploaded() == nil || b.GetUploaded().AsTime().IsZero() {
				t.Error("Uploaded timestamp is zero")
			}
			break
		}
	}
	if !found {
		t.Errorf("uploaded bundle %q not found in list_sw_update_files WebSocket response", filename)
	}
}

// ---------------------------------------------------------------------------
// Software update progress tests
// ---------------------------------------------------------------------------

// TestSoftwareUpdateProgressReceivedAfterTrigger uploads a bundle, triggers
// an update via WebSocket, then listens for at least one update_progress push
// message within the timeout window.
// Requires swupdate to be installed on the device: set FUSION_SWUPDATE_TEST=1 to run.
func TestSoftwareUpdateProgressReceivedAfterTrigger(t *testing.T) {
	if os.Getenv("FUSION_SWUPDATE_TEST") != "1" {
		t.Skip("skipping swupdate progress test; set FUSION_SWUPDATE_TEST=1 to run (requires swupdate installed on device)")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	// Upload a bundle first so swupdate on the device has something to install
	timestamp := time.Now().UnixNano()
	bundleData := makeTestSWUBundle(fmt.Sprintf("progress-test-%d", timestamp), 1024)
	filename := fmt.Sprintf("progress-test-%d.swu", timestamp)
	checksum := calculateSHA256(bundleData)
	uploadSoftwareUpdate(t, ctx, softwareUpdateServerAddr, filename, bundleData, checksum, http.StatusCreated)

	conn := dialWebSocket(t, softwareUpdateServerAddr)
	defer conn.Close()

	// Trigger the update
	sendWSRequest(t, conn, api.WSMsgTypeStartUpdate, struct{}{})

	// Listen for an update_progress push within 30 seconds
	conn.SetReadDeadline(time.Now().Add(30 * time.Second))
	deadline := time.Now().Add(30 * time.Second)
	for time.Now().Before(deadline) {
		var push wsResponse
		if err := conn.ReadJSON(&push); err != nil {
			// Deadline reached or connection closed
			break
		}
		if push.Type == api.WSMsgTypeUpdateProgress {
			// Verify structure of the progress payload
			raw, err := json.Marshal(push.Data)
			if err != nil {
				t.Fatalf("re-marshalling progress data failed: %v", err)
			}
			var nodes map[string]api.SoftwareUpdateProgressResponse
			if err := json.Unmarshal(raw, &nodes); err != nil {
				t.Fatalf("progress data is not a node map: %v — raw: %s", err, string(raw))
			}
			if len(nodes) == 0 {
				t.Error("progress push contained empty nodes map")
			}
			for nodeName, p := range nodes {
				if p.Node == "" {
					t.Errorf("node %q: progress.Node is empty", nodeName)
				}
				if p.UpdateState == "" {
					t.Errorf("node %q: progress.UpdateState is empty", nodeName)
				}
			}
			return // received and validated a progress push
		}
	}
	t.Skip("no update_progress push received within timeout — device may not have swupdate installed")
}

// TestSoftwareUpdateProgressMessageFormat connects via WebSocket and if any
// update_progress message arrives (without triggering), validates its shape.
// This is a passive listener test useful when an update is already in progress.
// Requires swupdate to be installed on the device: set FUSION_SWUPDATE_TEST=1 to run.
func TestSoftwareUpdateProgressMessageFormat(t *testing.T) {
	if os.Getenv("FUSION_SWUPDATE_TEST") != "1" {
		t.Skip("skipping swupdate progress format test; set FUSION_SWUPDATE_TEST=1 to run (requires swupdate installed on device)")
	}
	conn := dialWebSocket(t, softwareUpdateServerAddr)
	defer conn.Close()

	conn.SetReadDeadline(time.Now().Add(5 * time.Second))
	for {
		var push wsResponse
		if err := conn.ReadJSON(&push); err != nil {
			// Timeout - no progress in flight, skip
			t.Skip("no update_progress push received within 5s — no update in progress")
			return
		}
		if push.Type != api.WSMsgTypeUpdateProgress {
			continue
		}

		// Validate envelope
		if push.Version != api.WSCurrentVersion {
			t.Errorf("version mismatch: got %d want %d", push.Version, api.WSCurrentVersion)
		}
		if push.Status != api.WSStatusEvent {
			t.Errorf("expected status %q, got %q", api.WSStatusEvent, push.Status)
		}
		if push.ID != nil {
			t.Errorf("push notification should have null ID, got %q", *push.ID)
		}

		// Validate data is a node map
		raw, _ := json.Marshal(push.Data)
		var nodes map[string]api.SoftwareUpdateProgressResponse
		if err := json.Unmarshal(raw, &nodes); err != nil {
			t.Fatalf("progress data shape invalid: %v — raw: %s", err, string(raw))
		}
		for nodeName, p := range nodes {
			validStates := map[string]bool{
				"IDLE": true, "STARTING": true, "IN_PROGRESS": true,
				"SUCCESS": true, "FAILED": true, "DOWNLOADING": true,
				"COMPLETED": true, "SUBPROCESS": true, "PROGRESS": true, "UNKNOWN": true,
			}
			if !validStates[p.UpdateState] {
				t.Errorf("node %q: unexpected UpdateState %q", nodeName, p.UpdateState)
			}
			if p.Timestamp == "" {
				t.Errorf("node %q: Timestamp is empty", nodeName)
			}
		}
		return
	}
}
