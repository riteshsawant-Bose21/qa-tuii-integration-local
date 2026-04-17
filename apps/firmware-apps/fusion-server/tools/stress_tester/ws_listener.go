package main

import (
	"fmt"
	"sync"
	"time"

	json "github.com/goccy/go-json"
	"github.com/gorilla/websocket"
)

// WSListener connects to a fusion-server WebSocket, subscribes to config
// updates, and records every observed gain value.
type WSListener struct {
	name string
	host string
	conn *websocket.Conn

	mu           sync.Mutex
	observations []observation
	seen         map[int]int // gain → count
	maxGain      int
	outOfOrder   int
	duplicates   int
	ready        chan struct{}
	stopped      chan struct{}
}

// NewWSListener connects and subscribes. It is ready once the config
// subscribe response has been received.
func NewWSListener(name, host string) (*WSListener, error) {
	url := fmt.Sprintf("ws://%s/ws", host)
	conn, _, err := websocket.DefaultDialer.Dial(url, nil)
	if err != nil {
		return nil, fmt.Errorf("ws listener %s dial %s: %w", name, url, err)
	}

	l := &WSListener{
		name:    name,
		host:    host,
		conn:    conn,
		seen:    make(map[int]int),
		ready:   make(chan struct{}),
		stopped: make(chan struct{}),
	}

	go l.loop()
	return l, nil
}

func (l *WSListener) loop() {
	defer close(l.stopped)

	// 1. Read and discard welcome message.
	l.conn.SetReadDeadline(time.Now().Add(10 * time.Second))
	_, _, err := l.conn.ReadMessage()
	if err != nil {
		return
	}

	// 2. Subscribe to config updates.
	subMsg := map[string]any{
		"id":      "sub-config",
		"version": 1,
		"type":    "config",
	}
	if err := l.conn.WriteJSON(subMsg); err != nil {
		return
	}

	// 3. Read the subscribe response (type "config").
	l.conn.SetReadDeadline(time.Now().Add(10 * time.Second))
	_, _, err = l.conn.ReadMessage()
	if err != nil {
		return
	}
	l.conn.SetReadDeadline(time.Time{}) // clear
	close(l.ready)

	// 4. Read loop: process config_update pushes.
	for {
		_, raw, err := l.conn.ReadMessage()
		if err != nil {
			return
		}
		recvAt := time.Now()

		var msg struct {
			Type string `json:"type"`
			Data any    `json:"data"`
		}
		// Use json.Number to get precise int values
		dec := json.NewDecoder(bytesReader(raw))
		dec.UseNumber()
		if err := dec.Decode(&msg); err != nil {
			continue
		}

		if msg.Type != "config_update" {
			continue
		}

		gain, ok := extractGainFromWSData(msg.Data)
		if !ok {
			continue
		}

		l.mu.Lock()
		l.seen[gain]++
		if l.seen[gain] > 1 {
			l.duplicates++
		}
		if gain < l.maxGain {
			l.outOfOrder++
		}
		if gain > l.maxGain {
			l.maxGain = gain
		}
		l.observations = append(l.observations, observation{Gain: gain, ReceivedAt: recvAt})
		l.mu.Unlock()
	}
}

// Ready returns a channel that closes when the listener is subscribed and ready.
func (l *WSListener) Ready() <-chan struct{} { return l.ready }

// Stopped returns a channel that closes when the read loop exits.
func (l *WSListener) Stopped() <-chan struct{} { return l.stopped }

// Snapshot returns a copy of observations and stats. Safe to call concurrently.
func (l *WSListener) Snapshot() ([]observation, map[int]int, int, int) {
	l.mu.Lock()
	defer l.mu.Unlock()
	obs := make([]observation, len(l.observations))
	copy(obs, l.observations)
	seen := make(map[int]int, len(l.seen))
	for k, v := range l.seen {
		seen[k] = v
	}
	return obs, seen, l.outOfOrder, l.duplicates
}

// Close shuts down the listener.
func (l *WSListener) Close() error {
	return l.conn.Close()
}

// Name returns the listener name.
func (l *WSListener) Name() string { return l.name }

// Address returns the target host.
func (l *WSListener) Address() string { return l.host }

// bytesReader wraps a byte slice as an io.Reader for the JSON decoder.
func bytesReader(b []byte) *bytesReaderImpl { return &bytesReaderImpl{b: b} }

type bytesReaderImpl struct{ b []byte }

func (r *bytesReaderImpl) Read(p []byte) (int, error) {
	if len(r.b) == 0 {
		return 0, fmt.Errorf("EOF")
	}
	n := copy(p, r.b)
	r.b = r.b[n:]
	return n, nil
}
