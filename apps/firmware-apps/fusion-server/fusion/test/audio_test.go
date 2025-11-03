package main

import (
	"bytes"
	"context"
	"encoding/binary"
	"fmt"
	"fusion/internal/persistence"
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
	audioServerAddr = "http://192.168.64.100:8080"
)

// TestAudioUploadAndDeleteSuccess uploads a small WAV, verifies 201 + metadata,
// then deletes it by id and expects 204.
func TestAudioUploadAndDeleteSuccess(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Create a tiny valid 8kHz mono PCM WAV (0.25s of silence)
	wav := makeTestWAV(8000, 1, 16, 200*time.Millisecond)
	filename := "test_upload.wav"
	displayName := "Unit Test Clip"

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

	// Delete the uploaded asset
	req, err := http.NewRequestWithContext(ctx, "DELETE",
		fmt.Sprintf("%s%s/%s", audioServerAddr, routes.PAVAMessagesEndpoint, meta.Id), nil)
	if err != nil {
		t.Fatalf("creating DELETE request failed: %v", err)
	}

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		t.Fatalf("DELETE %s failed: %v", routes.PAVAMessagesEndpoint, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("DELETE %s returned %d, want 204; body=%s", routes.PAVAMessagesEndpoint, resp.StatusCode, string(body))
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
func uploadAudio(t *testing.T, ctx context.Context, base, filename string, data []byte, displayName string) *persistence.AudioMetadata {
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

	var meta persistence.AudioMetadata
	if err := json.NewDecoder(resp.Body).Decode(&meta); err != nil {
		t.Fatalf("decoding metadata failed: %v", err)
	}

	return &meta
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
	filename := "test_tags.wav"

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

	var meta persistence.AudioMetadata
	if err := json.NewDecoder(resp.Body).Decode(&meta); err != nil {
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

	var metas []*persistence.AudioMetadata
	if err := json.NewDecoder(resp.Body).Decode(&metas); err != nil {
		t.Fatalf("decoding metadata failed: %v", err)
	}

	for _, m := range metas {
		found := false
		for _, t := range m.Tags {
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

	var tags []string
	if err := json.NewDecoder(resp.Body).Decode(&tags); err != nil {
		t.Fatalf("decoding tags failed: %v", err)
	}

	// Expect at least Fire Drill and Emergencies from earlier tests
	expected := []string{"Fire Drill", "Emergencies"}
	for _, e := range expected {
		found := false
		for _, t := range tags {
			if strings.EqualFold(t, e) {
				found = true
				break
			}
		}
		if !found {
			t.Errorf("expected tag %q in tag list, got %v", e, tags)
		}
	}
}
