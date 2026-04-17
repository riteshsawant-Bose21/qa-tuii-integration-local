package main

import (
	"bytes"
	"fmt"
	"net/http"
	"sync"
	"sync/atomic"
	"time"

	json "github.com/goccy/go-json"
	"github.com/gorilla/websocket"
)

// Writer sends patch updates to the fusion-server.
type Writer interface {
	Send(gain int) error
	Close() error
}

// NewWriter creates a Writer for the configured transport.
func NewWriter(cfg Config) (Writer, error) {
	switch cfg.WriterMode {
	case WriterModeWS:
		return newWSWriter(cfg.WriterHost)
	case WriterModeHTTP:
		return newHTTPWriter(cfg.WriterHost)
	default:
		return nil, fmt.Errorf("unknown writer mode: %s", cfg.WriterMode)
	}
}

// ---------------------------------------------------------------------------
// WebSocket writer
// ---------------------------------------------------------------------------

type wsWriter struct {
	conn *websocket.Conn
	mu   sync.Mutex
	seq  atomic.Int64
}

func newWSWriter(host string) (*wsWriter, error) {
	url := fmt.Sprintf("ws://%s/ws", host)
	conn, _, err := websocket.DefaultDialer.Dial(url, nil)
	if err != nil {
		return nil, fmt.Errorf("ws writer dial %s: %w", url, err)
	}

	w := &wsWriter{conn: conn}

	// Read and discard the welcome message
	conn.SetReadDeadline(time.Now().Add(10 * time.Second))
	_, _, err = conn.ReadMessage()
	if err != nil {
		conn.Close()
		return nil, fmt.Errorf("ws writer: failed to read welcome: %w", err)
	}
	conn.SetReadDeadline(time.Time{}) // clear deadline

	// Start a background goroutine to drain incoming messages (ping/pong, responses)
	go func() {
		for {
			if _, _, err := conn.ReadMessage(); err != nil {
				return
			}
		}
	}()

	return w, nil
}

func (w *wsWriter) Send(gain int) error {
	seq := w.seq.Add(1)
	msg := map[string]any{
		"id":      fmt.Sprintf("req-%d", seq),
		"version": 1,
		"type":    "patch_config",
		"data": map[string]any{
			"settings": map[string]any{
				"audio": map[string]any{
					"GAIN": map[string]any{
						"gain": gain,
					},
				},
			},
		},
	}

	w.mu.Lock()
	defer w.mu.Unlock()
	return w.conn.WriteJSON(msg)
}

func (w *wsWriter) Close() error {
	w.mu.Lock()
	defer w.mu.Unlock()
	return w.conn.Close()
}

// ---------------------------------------------------------------------------
// HTTP writer
// ---------------------------------------------------------------------------

type httpWriter struct {
	client  *http.Client
	baseURL string
}

func newHTTPWriter(host string) (*httpWriter, error) {
	return &httpWriter{
		client: &http.Client{
			Timeout: 10 * time.Second,
		},
		baseURL: fmt.Sprintf("http://%s", host),
	}, nil
}

func (w *httpWriter) Send(gain int) error {
	body := map[string]any{
		"settings": map[string]any{
			"audio": map[string]any{
				"GAIN": map[string]any{
					"gain": gain,
				},
			},
		},
	}

	data, err := json.Marshal(body)
	if err != nil {
		return fmt.Errorf("marshal patch body: %w", err)
	}

	req, err := http.NewRequest(http.MethodPatch, w.baseURL+"/value", bytes.NewReader(data))
	if err != nil {
		return fmt.Errorf("create patch request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := w.client.Do(req)
	if err != nil {
		return fmt.Errorf("http patch: %w", err)
	}
	resp.Body.Close()

	if resp.StatusCode >= 400 {
		return fmt.Errorf("http patch returned %d", resp.StatusCode)
	}
	return nil
}

func (w *httpWriter) Close() error {
	w.client.CloseIdleConnections()
	return nil
}
