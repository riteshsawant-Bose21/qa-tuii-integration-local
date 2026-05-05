package main

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/binary"
	"encoding/hex"
	"fmt"
	fusionpb "fusion/internal/gen/proto/fusion"
	"fusion/internal/routes"
	"io"
	"mime/multipart"
	"net"
	"net/http"
	"path/filepath"
	"strings"
	"testing"
	"time"

	json "github.com/goccy/go-json"
	"google.golang.org/protobuf/types/known/timestamppb"
)

const (
	audioServerAddr = "http://192.168.2.100:8080"
)

type messageTriggerPayload struct {
	ID        string   `json:"id"`
	Path      string   `json:"path"`
	Priority  int      `json:"priority,omitempty"`
	Zones     []string `json:"zones,omitempty"`
	Timestamp int64    `json:"timestamp"`
}

func uniqueAudioNames(prefix string) (string, string) {
	suffix := fmt.Sprintf("%d", time.Now().UnixNano())
	base := fmt.Sprintf("%s_%s", prefix, suffix)
	return base + ".wav", base
}

func localAudioBaseURL(t *testing.T) string {
	t.Helper()

	if !isLocalTestMode() {
		t.Skip("message trigger UDP payload tests require local mode with FUSION_TEST_LOCAL=1, FUSION_TEST_NODES=127.0.0.1:8080, and FUSION_TEST_VIP=127.0.0.1:8080")
	}

	if clusterConfig == nil || clusterConfig.vip == "" {
		t.Fatal("cluster configuration not initialized")
	}

	return clusterConfig.vip
}

func listenForMessageTrigger(t *testing.T) *net.UDPConn {
	t.Helper()

	addr, err := net.ResolveUDPAddr("udp4", "127.0.0.1:7949")
	if err != nil {
		t.Fatalf("resolve trigger listener: %v", err)
	}

	conn, err := net.ListenUDP("udp4", addr)
	if err != nil {
		t.Skipf("unable to listen on 127.0.0.1:7949 for message trigger payloads: %v", err)
	}

	return conn
}

func awaitMessageTriggerPayload(t *testing.T, conn *net.UDPConn, timeout time.Duration) messageTriggerPayload {
	t.Helper()

	_ = conn.SetReadDeadline(time.Now().Add(timeout))

	buf := make([]byte, 4096)
	n, _, err := conn.ReadFromUDP(buf)
	if err != nil {
		t.Fatalf("read message trigger payload: %v", err)
	}

	var payload messageTriggerPayload
	if err := json.Unmarshal(buf[:n], &payload); err != nil {
		t.Fatalf("decode message trigger payload: %v; raw=%s", err, string(buf[:n]))
	}

	return payload
}

// TestAudioUploadAndDeleteSuccess uploads a small WAV, verifies 201 + metadata,
// then deletes it by id and expects 204.
func TestAudioUploadAndDeleteSuccess(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Create a tiny valid 8kHz mono PCM WAV (0.25s of silence)
	wav := makeTestWAV(8000, 1, 16, 200*time.Millisecond)
	filename, displayName := uniqueAudioNames("unit_test_clip")

	meta := uploadAudio(t, ctx, audioServerAddr, filename, wav, displayName)
	if meta.Id == "" {
		t.Fatalf("upload returned empty id: %+v", meta)
	}

	if meta.DisplayName != displayName {
		t.Errorf("unexpected display_name: got %q want %q", meta.DisplayName, displayName)
	}

	if meta.SizeBytes == 0 {
		t.Errorf("unexpected size_bytes: got %d", meta.SizeBytes)
	}

	deleteAudio(t, ctx, audioServerAddr, meta.Id)
}

// TestAudioUploadBinaryIntegrity verifies upload metadata checksum and streamed bytes
// both match the original uploaded payload exactly.
func TestAudioUploadBinaryIntegrity(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	wav := makeTestWAV(8000, 1, 16, 200*time.Millisecond)
	filename, displayName := uniqueAudioNames("binary_integrity_clip")

	meta := uploadAudio(t, ctx, audioServerAddr, filename, wav, displayName)
	defer deleteAudio(t, ctx, audioServerAddr, meta.Id)

	expectedSum := sha256.Sum256(wav)
	expectedChecksum := hex.EncodeToString(expectedSum[:])

	if meta.Checksum != expectedChecksum {
		t.Fatalf("unexpected checksum: got %s want %s", meta.Checksum, expectedChecksum)
	}

	if meta.SizeBytes != int64(len(wav)) {
		t.Fatalf("unexpected size_bytes: got %d want %d", meta.SizeBytes, len(wav))
	}

	streamEndpoint := strings.Replace(routes.PAVAMessageStreamEndpoint, "{id}", meta.Id, 1)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, fmt.Sprintf("%s%s", audioServerAddr, streamEndpoint), nil)
	if err != nil {
		t.Fatalf("creating stream request failed: %v", err)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("GET %s failed: %v", routes.PAVAMessageStreamEndpoint, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("GET %s returned %d, want 200; body=%s", routes.PAVAMessageStreamEndpoint, resp.StatusCode, string(body))
	}

	if got := resp.Header.Get("Content-Type"); got != "audio/wav" {
		t.Fatalf("unexpected content-type: got %q want %q", got, "audio/wav")
	}

	streamed, err := io.ReadAll(resp.Body)
	if err != nil {
		t.Fatalf("reading stream failed: %v", err)
	}

	if !bytes.Equal(streamed, wav) {
		t.Fatalf("streamed payload differs from uploaded payload: got %d bytes want %d", len(streamed), len(wav))
	}

	streamedSum := sha256.Sum256(streamed)
	if got := hex.EncodeToString(streamedSum[:]); got != expectedChecksum {
		t.Fatalf("stream checksum mismatch: got %s want %s", got, expectedChecksum)
	}
}

// TestAudioDeleteNotFound tries to delete a random id and expects 404.
func TestAudioDeleteNotFound(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Use a clearly bogus id (ULID-like shape but not present)
	bogus := "01HZY0ZZZZZZZZZZZZZZZZZZZZ"
	req, err := http.NewRequestWithContext(ctx, "DELETE",
		fmt.Sprintf("%s%s/%s", audioServerAddr, routes.PAVAMessagesEndpoint, bogus), nil)
	if err != nil {
		t.Fatalf("creating DELETE request failed: %v", err)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("DELETE %s failed: %v", routes.PAVAMessagesEndpoint, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusNotFound {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("DELETE %s returned %d, want 404; body=%s", routes.PAVAMessagesEndpoint, resp.StatusCode, string(body))
	}
}

// TestAudioUploadMissingFile posts the multipart form without the "binary" part and expects 400.
func TestAudioUploadMissingFile(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var buf bytes.Buffer
	w := multipart.NewWriter(&buf)
	// Intentionally DO NOT add "binary" part
	_ = w.WriteField("display_name", "no file provided")
	_ = w.Close()

	req, err := http.NewRequestWithContext(ctx, "POST", fmt.Sprintf("%s%s", audioServerAddr, routes.PAVAMessagesEndpoint), &buf)
	if err != nil {
		t.Fatalf("creating POST request failed: %v", err)
	}
	req.Header.Set("Content-Type", w.FormDataContentType())

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("POST %s failed: %v", routes.PAVAMessagesEndpoint, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusBadRequest {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("POST %s returned %d, want 400; body=%s", routes.PAVAMessagesEndpoint, resp.StatusCode, string(body))
	}
}

// uploadAudio is a helper that performs a multipart/form-data upload to POST /pava/messages
// with the "binary" file part and optional "display_name". It asserts 201 and
// returns the parsed metadata.
func uploadAudio(t *testing.T, ctx context.Context, base, filename string, data []byte, displayName string) *fusionpb.AudioMetadata {
	t.Helper()

	var buf bytes.Buffer
	w := multipart.NewWriter(&buf)

	// Add the file part with field name "binary"
	fw, err := w.CreateFormFile("binary", filename)
	if err != nil {
		t.Fatalf("CreateFormFile failed: %v", err)
	}

	if _, err := fw.Write(data); err != nil {
		t.Fatalf("writing file data failed: %v", err)
	}

	// Optional display name
	if displayName != "" {
		_ = w.WriteField("display_name", displayName)
	}

	if err := w.Close(); err != nil {
		t.Fatalf("closing multipart writer failed: %v", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", fmt.Sprintf("%s%s", base, routes.PAVAMessagesEndpoint), &buf)
	if err != nil {
		t.Fatalf("creating POST request failed: %v", err)
	}
	req.Header.Set("Content-Type", w.FormDataContentType())

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("POST %s failed: %v", routes.PAVAMessagesEndpoint, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusCreated {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("POST %s returned %d, want 201; body=%s", routes.PAVAMessagesEndpoint, resp.StatusCode, string(body))
	}

	var meta fusionpb.AudioMetadata
	if err := decodeProtoBody(resp.Body, &meta); err != nil {
		t.Fatalf("decoding metadata failed: %v", err)
	}

	return &meta
}

func TestTriggerMessageRecordsImmediateManualHistory(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	clearHistory(t)

	wav := makeTestWAV(8000, 1, 16, 200*time.Millisecond)
	filename, displayName := uniqueAudioNames("trigger_history_clip")
	meta := uploadAudio(t, ctx, audioServerAddr, filename, wav, displayName)
	defer deleteAudio(t, ctx, audioServerAddr, meta.Id)

	triggerEndpoint := strings.Replace(routes.PAVAMessageTriggerEndpoint, "{id}", meta.Id, 1)
	reqBody := marshalProtoMessage(t, &fusionpb.TriggerMessageRequest{Priority: 100})
	req, err := http.NewRequestWithContext(ctx, http.MethodPut, fmt.Sprintf("%s%s", audioServerAddr, triggerEndpoint), bytes.NewReader(reqBody))
	if err != nil {
		t.Fatalf("creating trigger request failed: %v", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("PUT %s failed: %v", routes.PAVAMessageTriggerEndpoint, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("PUT %s returned %d, want 204; body=%s", routes.PAVAMessageTriggerEndpoint, resp.StatusCode, string(body))
	}

	history := fetchHistory(t)
	if len(history) == 0 {
		t.Fatalf("expected at least one history record after immediate trigger")
	}

	found := false
	for _, rec := range history {
		if rec.GetTaskId() == "message_trigger_immediate" {
			found = true
			if rec.GetDescription() != "Immediate/manual audio message trigger" {
				t.Fatalf("unexpected history description: got %q", rec.GetDescription())
			}
			if rec.GetStatus() != "success" {
				t.Fatalf("unexpected history status: got %q want %q", rec.GetStatus(), "success")
			}
		}
	}

	if !found {
		t.Fatalf("expected history entry for immediate/manual audio trigger, got %#v", history)
	}
}

func TestTriggerMessageEmitsZonesPayloadLocal(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	baseURL := localAudioBaseURL(t)
	listener := listenForMessageTrigger(t)
	defer listener.Close()

	wav := makeTestWAV(8000, 1, 16, 200*time.Millisecond)
	filename, displayName := uniqueAudioNames("trigger_zones_payload")
	meta := uploadAudio(t, ctx, baseURL, filename, wav, displayName)
	defer deleteAudio(t, ctx, baseURL, meta.Id)

	triggerEndpoint := strings.Replace(routes.PAVAMessageTriggerEndpoint, "{id}", meta.Id, 1)
	reqBody := marshalProtoMessage(t, &fusionpb.TriggerMessageRequest{
		Priority: 77,
		Zones:    []string{"lobby", "gym"},
	})
	req, err := http.NewRequestWithContext(ctx, http.MethodPut, fmt.Sprintf("%s%s", baseURL, triggerEndpoint), bytes.NewReader(reqBody))
	if err != nil {
		t.Fatalf("creating trigger request failed: %v", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("PUT %s failed: %v", routes.PAVAMessageTriggerEndpoint, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("PUT %s returned %d, want 204; body=%s", routes.PAVAMessageTriggerEndpoint, resp.StatusCode, string(body))
	}

	payload := awaitMessageTriggerPayload(t, listener, 3*time.Second)
	if payload.ID != meta.Id {
		t.Fatalf("unexpected payload id: got %q want %q", payload.ID, meta.Id)
	}
	if payload.Priority != 77 {
		t.Fatalf("unexpected payload priority: got %d want %d", payload.Priority, 77)
	}
	if strings.Join(payload.Zones, ",") != "lobby,gym" {
		t.Fatalf("unexpected payload zones: got %v want %v", payload.Zones, []string{"lobby", "gym"})
	}
	if !strings.HasSuffix(payload.Path, filepath.Base(meta.Filename)) && !strings.HasSuffix(payload.Path, meta.Id+".wav") {
		t.Fatalf("unexpected payload path: got %q", payload.Path)
	}
	if payload.Timestamp == 0 {
		t.Fatal("expected non-zero payload timestamp")
	}
}

func deleteAudio(t *testing.T, ctx context.Context, base, id string) {
	t.Helper()

	req, err := http.NewRequestWithContext(ctx, http.MethodDelete,
		fmt.Sprintf("%s%s/%s", base, routes.PAVAMessagesEndpoint, id), nil)
	if err != nil {
		t.Fatalf("creating DELETE request failed: %v", err)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("DELETE %s failed: %v", routes.PAVAMessagesEndpoint, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("DELETE %s returned %d, want 204; body=%s", routes.PAVAMessagesEndpoint, resp.StatusCode, string(body))
	}
}

// makeTestWAV constructs a minimal PCM RIFF/WAVE file with the given
// sample rate, channels, bits-per-sample, and duration. Samples are silence.
func makeTestWAV(sampleRate, channels, bitsPerSample int, dur time.Duration) []byte {
	if channels <= 0 {
		channels = 1
	}
	if sampleRate <= 0 {
		sampleRate = 8000
	}
	if bitsPerSample != 8 && bitsPerSample != 16 {
		bitsPerSample = 16
	}

	numSamples := int(float64(sampleRate) * dur.Seconds())
	if numSamples < 1 {
		numSamples = sampleRate / 4 // default to 0.25s if too small
	}

	bytesPerSample := bitsPerSample / 8
	blockAlign := channels * bytesPerSample
	byteRate := sampleRate * blockAlign
	dataSize := numSamples * blockAlign

	// RIFF header is 44 bytes for PCM
	out := &bytes.Buffer{}

	// RIFF chunk descriptor
	out.WriteString("RIFF")
	binary.Write(out, binary.LittleEndian, uint32(36+dataSize)) // ChunkSize
	out.WriteString("WAVE")

	// fmt subchunk
	out.WriteString("fmt ")
	binary.Write(out, binary.LittleEndian, uint32(16))            // Subchunk1Size for PCM
	binary.Write(out, binary.LittleEndian, uint16(1))             // AudioFormat = 1 (PCM)
	binary.Write(out, binary.LittleEndian, uint16(channels))      // NumChannels
	binary.Write(out, binary.LittleEndian, uint32(sampleRate))    // SampleRate
	binary.Write(out, binary.LittleEndian, uint32(byteRate))      // ByteRate
	binary.Write(out, binary.LittleEndian, uint16(blockAlign))    // BlockAlign
	binary.Write(out, binary.LittleEndian, uint16(bitsPerSample)) // BitsPerSample

	// data subchunk
	out.WriteString("data")
	binary.Write(out, binary.LittleEndian, uint32(dataSize))

	// Write silence samples
	silence := make([]byte, dataSize)
	out.Write(silence)

	return out.Bytes()
}

// TestAudioUploadWithTags uploads a WAV with tags and verifies they round-trip.
func TestAudioUploadWithTags(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	wav := makeTestWAV(8000, 1, 16, 200*time.Millisecond)
	filename, displayName := uniqueAudioNames("test_tags")

	// Create multipart with tags
	var buf bytes.Buffer
	w := multipart.NewWriter(&buf)

	// File part
	fw, err := w.CreateFormFile("binary", filename)
	if err != nil {
		t.Fatalf("CreateFormFile failed: %v", err)
	}
	if _, err := fw.Write(wav); err != nil {
		t.Fatalf("writing file data failed: %v", err)
	}

	// Add tags
	_ = w.WriteField("display_name", displayName)
	_ = w.WriteField("tags", "Fire Drill")
	_ = w.WriteField("tags", "Emergencies")

	if err := w.Close(); err != nil {
		t.Fatalf("closing multipart writer failed: %v", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", fmt.Sprintf("%s%s", audioServerAddr, routes.PAVAMessagesEndpoint), &buf)
	if err != nil {
		t.Fatalf("creating POST request failed: %v", err)
	}
	req.Header.Set("Content-Type", w.FormDataContentType())

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("POST %s failed: %v", routes.PAVAMessagesEndpoint, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusCreated {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("POST %s returned %d, want 201; body=%s", routes.PAVAMessagesEndpoint, resp.StatusCode, string(body))
	}

	var meta fusionpb.AudioMetadata
	if err := decodeProtoBody(resp.Body, &meta); err != nil {
		t.Fatalf("decoding metadata failed: %v", err)
	}

	if len(meta.Tags) != 2 {
		t.Errorf("expected 2 tags, got %d: %+v", len(meta.Tags), meta.Tags)
	}
}

// TestAudioListFilterByTag ensures that filtering by tag returns only matching entries.
func TestAudioListFilterByTag(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Ask for files tagged "Emergencies"
	req, err := http.NewRequestWithContext(ctx, "GET",
		fmt.Sprintf("%s%s?tag=Emergencies", audioServerAddr, routes.PAVAMessagesEndpoint), nil)
	if err != nil {
		t.Fatalf("creating GET request failed: %v", err)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("GET %s failed: %v", routes.PAVAMessagesEndpoint, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("GET %s returned %d, want 200; body=%s", routes.PAVAMessagesEndpoint, resp.StatusCode, string(body))
	}

	metas, err := decodeAudioMetadataListResponse(resp.Body)
	if err != nil {
		t.Fatalf("decoding metadata failed: %v", err)
	}

	for _, m := range metas.GetMessages() {
		found := false
		for _, t := range m.GetTags() {
			if strings.EqualFold(t, "Emergencies") {
				found = true
				break
			}
		}
		if !found {
			t.Errorf("file %s missing expected tag 'Emergencies'", m.Id)
		}
	}
}

// TestListAllTags fetches the global tag list and ensures known tags are present.
func TestListAllTags(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, "GET", fmt.Sprintf("%s%s", audioServerAddr, routes.PAVAMessagesTagsEndpoint), nil)
	if err != nil {
		t.Fatalf("creating GET request failed: %v", err)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("GET %s failed: %v", routes.PAVAMessagesTagsEndpoint, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("GET %s returned %d, want 200; body=%s", routes.PAVAMessagesTagsEndpoint, resp.StatusCode, string(body))
	}

	tagsResp, err := decodeAudioTagListResponse(resp.Body)
	if err != nil {
		t.Fatalf("decoding tags failed: %v", err)
	}

	// Expect at least Fire Drill and Emergencies from earlier tests
	expected := []string{"Fire Drill", "Emergencies"}
	for _, e := range expected {
		found := false
		for _, t := range tagsResp.GetTags() {
			if strings.EqualFold(t, e) {
				found = true
				break
			}
		}
		if !found {
			t.Errorf("expected tag %q in tag list, got %v", e, tagsResp.GetTags())
		}
	}
}

func decodeAudioMetadataListResponse(body io.Reader) (*fusionpb.AudioMetadataListResponse, error) {
	data, err := io.ReadAll(body)
	if err != nil {
		return nil, err
	}

	var protoResp fusionpb.AudioMetadataListResponse
	if err := decodeProtoBody(bytes.NewReader(data), &protoResp); err == nil {
		return &protoResp, nil
	}

	var legacy []struct {
		Id          string        `json:"id"`
		OrigName    string        `json:"orig_name"`
		DisplayName string        `json:"display_name"`
		Filename    string        `json:"filename"`
		MimeType    string        `json:"mime_type"`
		Uploaded    time.Time     `json:"uploaded"`
		Duration    time.Duration `json:"duration,omitempty"`
		SizeBytes   int64         `json:"size_bytes"`
		Tags        []string      `json:"tags"`
		Checksum    string        `json:"checksum"`
	}
	if err := json.Unmarshal(data, &legacy); err != nil {
		return nil, err
	}

	out := make([]*fusionpb.AudioMetadata, 0, len(legacy))
	for _, meta := range legacy {
		out = append(out, &fusionpb.AudioMetadata{
			Id:          meta.Id,
			OrigName:    meta.OrigName,
			DisplayName: meta.DisplayName,
			Filename:    meta.Filename,
			MimeType:    meta.MimeType,
			Uploaded:    timestamppb.New(meta.Uploaded),
			Duration:    int64(meta.Duration),
			SizeBytes:   meta.SizeBytes,
			Tags:        append([]string(nil), meta.Tags...),
			Checksum:    meta.Checksum,
		})
	}

	return &fusionpb.AudioMetadataListResponse{Messages: out}, nil
}

func decodeAudioTagListResponse(body io.Reader) (*fusionpb.AudioTagListResponse, error) {
	data, err := io.ReadAll(body)
	if err != nil {
		return nil, err
	}

	var protoResp fusionpb.AudioTagListResponse
	if err := decodeProtoBody(bytes.NewReader(data), &protoResp); err == nil {
		return &protoResp, nil
	}

	var legacy []string
	if err := json.Unmarshal(data, &legacy); err != nil {
		return nil, err
	}

	return &fusionpb.AudioTagListResponse{Tags: legacy}, nil
}

func TestAudioSyncAcrossNodes(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	nodes := getClusterNodeURLs(t, ctx, audioServerAddr)

	// Create a short WAV
	wav := makeTestWAV(8000, 1, 16, 200*time.Millisecond)
	filename, displayName := uniqueAudioNames("sync_test_clip")

	// Upload to VIP
	meta := uploadAudio(t, ctx, audioServerAddr, filename, wav, displayName)
	if meta.Id == "" {
		t.Fatalf("upload returned empty id")
	}

	// Wait for each node to sync metadata
	for _, node := range nodes {
		waitForMetadata(t, ctx, node, meta.Id)
	}

	// Verify file bytes on each node
	for _, node := range nodes {
		verifyAudioSynced(t, ctx, node, meta)
	}
}

func waitForMetadata(t *testing.T, ctx context.Context, base string, id string) {
	ticker := time.NewTicker(300 * time.Millisecond)
	defer ticker.Stop()

	timeout := time.After(15 * time.Second)

	for {
		select {
		case <-ctx.Done():
			t.Fatalf("context canceled while waiting for metadata sync on %s", base)
		case <-timeout:
			t.Fatalf("timeout waiting for metadata ID=%s on %s", id, base)
		case <-ticker.C:
			if hasMetadata(t, base, id) {
				return
			}
		}
	}
}

func hasMetadata(_ *testing.T, base, id string) bool {
	url := fmt.Sprintf("%s%s/%s", base, routes.PAVAMessagesEndpoint, id)
	//t.Logf("Waiting for: %s", id)
	resp, err := http.Get(url)
	if err != nil {
		return false
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return false
	}

	var meta fusionpb.AudioMetadata
	if err := decodeProtoBody(resp.Body, &meta); err != nil {
		return false
	}

	return meta.GetId() == id
}

func verifyAudioSynced(t *testing.T, ctx context.Context, base string, meta *fusionpb.AudioMetadata) {

	streamEndpoint := strings.Replace(routes.PAVAMessageStreamEndpoint, "{id}", meta.Id, 1)
	url := fmt.Sprintf("%s%s", base, streamEndpoint)

	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		t.Fatalf("creating GET failed: %v", err)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("GET stream failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("GET stream returned %d; body=%s", resp.StatusCode, string(body))
	}

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		t.Fatalf("reading stream failed: %v", err)
	}

	// Compute checksum of received data
	sum := sha256.Sum256(data)
	got := hex.EncodeToString(sum[:])

	if got != meta.Checksum {
		t.Fatalf("checksum mismatch on node %s: want=%s got=%s", base, meta.Checksum, got)
	}
}

// getClusterNodeURLs returns URLs for all nodes except the VIP itself
func getClusterNodeURLs(t *testing.T, ctx context.Context, vipURL string) []string {
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

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		t.Fatalf("failed to read /devices response: %v", err)
	}

	var devicesResp fusionpb.DeviceListResponse
	if err := decodeProtoBody(bytes.NewReader(body), &devicesResp); err != nil {
		t.Fatalf("failed to decode /devices: %v; body=%s", err, string(body))
	}

	if len(devicesResp.Devices) == 0 {
		t.Fatalf("/devices returned no devices; body=%s", string(body))
	}

	// Build the list of URLs
	urls := make([]string, 0)
	for _, d := range devicesResp.Devices {
		url := fmt.Sprintf("http://%s:8080", d.GetAddress())

		// skip VIP node
		if d.GetIsPrimary() {
			continue
		}

		urls = append(urls, url)
	}

	if len(urls) == 0 {
		t.Fatalf("no follower nodes found via /devices")
	}

	return urls
}

func TestAudioDeleteAcrossNodes(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	vip := audioServerAddr
	nodes := getClusterNodeURLs(t, ctx, vip)

	// Create a short WAV
	wav := makeTestWAV(8000, 1, 16, 200*time.Millisecond)
	filename, displayName := uniqueAudioNames("delete_sync_test_clip")

	// Upload to VIP
	meta := uploadAudio(t, ctx, vip, filename, wav, displayName)
	if meta.Id == "" {
		t.Fatalf("upload returned empty id")
	}

	// Wait for sync on each node
	for _, node := range nodes {
		waitForMetadata(t, ctx, node, meta.Id)
	}

	// Verify synced bytes
	for _, node := range nodes {
		verifyAudioSynced(t, ctx, node, meta)
	}

	// Delete the audio using the REST API
	deleteURL := fmt.Sprintf("%s%s/%s", vip, routes.PAVAMessagesEndpoint, meta.Id)
	req, err := http.NewRequestWithContext(ctx, http.MethodDelete, deleteURL, nil)
	if err != nil {
		t.Fatalf("DELETE request creation failed: %v", err)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("DELETE request failed: %v", err)
	}
	resp.Body.Close()

	if resp.StatusCode != http.StatusNoContent {
		t.Fatalf("DELETE returned %d, want 204", resp.StatusCode)
	}

	// Wait for deletion on all nodes
	for _, node := range nodes {
		waitForMetadataDeletion(t, ctx, node, meta.Id)
		waitForFileDeletion(t, ctx, node, meta.Filename)
	}
}

func waitForMetadataDeletion(t *testing.T, ctx context.Context, base, id string) {
	ticker := time.NewTicker(300 * time.Millisecond)
	defer ticker.Stop()

	timeout := time.After(15 * time.Second)

	url := fmt.Sprintf("%s%s/%s", base, routes.PAVAMessagesEndpoint, id)

	for {
		select {
		case <-ctx.Done():
			t.Fatalf("context canceled while waiting for metadata deletion on %s", base)

		case <-timeout:
			t.Fatalf("timeout waiting for metadata deletion ID=%s on %s", id, base)

		case <-ticker.C:
			resp, err := http.Get(url)
			if err != nil {
				// network hiccup? keep waiting
				continue
			}
			resp.Body.Close()

			if resp.StatusCode == http.StatusNotFound {
				return
			}
		}
	}
}

func waitForFileDeletion(t *testing.T, ctx context.Context, base, filename string) {
	ticker := time.NewTicker(300 * time.Millisecond)
	defer ticker.Stop()
	timeout := time.After(15 * time.Second)

	// We need ID, but filename alone is fine by checking 404 on stream
	id := strings.TrimSuffix(filename, filepath.Ext(filename))
	stream := strings.Replace(routes.PAVAMessageStreamEndpoint, "{id}", id, 1)
	url := fmt.Sprintf("%s%s", base, stream)

	for {
		select {
		case <-ctx.Done():
			t.Fatalf("context canceled waiting for file deletion on %s", base)

		case <-timeout:
			t.Fatalf("timeout waiting for audio file deletion %s on %s", filename, base)

		case <-ticker.C:
			req, _ := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
			resp, err := http.DefaultClient.Do(req)
			if err != nil {
				continue
			}
			resp.Body.Close()

			if resp.StatusCode == http.StatusNotFound {
				return
			}
		}
	}
}
