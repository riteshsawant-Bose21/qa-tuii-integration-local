package stresstester

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
	reconnects   int
	ready        chan struct{}
	stopped      chan struct{}
	closeCh      chan struct{}
}

const listenerMaxReconnect = 10
const listenerReconnectDelay = 500 * time.Millisecond

// NewWSListener connects and subscribes. It is ready once the config
// subscribe response has been received.
func NewWSListener(name, host string) (*WSListener, error) {
	l := &WSListener{
		name:    name,
		host:    host,
		seen:    make(map[int]int),
		ready:   make(chan struct{}),
		stopped: make(chan struct{}),
		closeCh: make(chan struct{}),
	}

	conn, err := l.dialAndSubscribe()
	if err != nil {
		return nil, err
	}
	l.conn = conn
	close(l.ready)

	go l.loop()
	return l, nil
}

func (l *WSListener) dialAndSubscribe() (*websocket.Conn, error) {
	url := fmt.Sprintf("ws://%s/ws", l.host)
	conn, _, err := websocket.DefaultDialer.Dial(url, nil)
	if err != nil {
		return nil, fmt.Errorf("ws listener %s dial %s: %w", l.name, url, err)
	}

	// 1. Read and discard welcome message.
	conn.SetReadDeadline(time.Now().Add(10 * time.Second))
	_, _, err = conn.ReadMessage()
	if err != nil {
		conn.Close()
		return nil, fmt.Errorf("ws listener %s welcome: %w", l.name, err)
	}

	// 2. Subscribe to config updates.
	subMsg := map[string]any{
		"id":      "sub-config",
		"version": 1,
		"type":    "config",
	}
	if err := conn.WriteJSON(subMsg); err != nil {
		conn.Close()
		return nil, fmt.Errorf("ws listener %s subscribe: %w", l.name, err)
	}

	// 3. Read the subscribe response.
	conn.SetReadDeadline(time.Now().Add(10 * time.Second))
	_, _, err = conn.ReadMessage()
	if err != nil {
		conn.Close()
		return nil, fmt.Errorf("ws listener %s subscribe resp: %w", l.name, err)
	}
	conn.SetReadDeadline(time.Time{})
	return conn, nil
}

func (l *WSListener) reconnect() bool {
	for attempt := 1; attempt <= listenerMaxReconnect; attempt++ {
		select {
		case <-l.closeCh:
			return false
		default:
		}
		time.Sleep(listenerReconnectDelay * time.Duration(attempt))
		conn, err := l.dialAndSubscribe()
		if err != nil {
			fmt.Printf("  [%s] reconnect attempt %d/%d failed: %v\n", l.name, attempt, listenerMaxReconnect, err)
			continue
		}
		l.mu.Lock()
		l.conn = conn
		l.reconnects++
		l.mu.Unlock()
		fmt.Printf("  [%s] reconnected on attempt %d\n", l.name, attempt)
		return true
	}
	return false
}

func (l *WSListener) loop() {
	defer close(l.stopped)

	for {
		_, raw, err := l.conn.ReadMessage()
		if err != nil {
			// Check if we were intentionally closed
			select {
			case <-l.closeCh:
				return
			default:
			}
			fmt.Printf("  [%s] connection lost: %v — reconnecting...\n", l.name, err)
			if !l.reconnect() {
				return
			}
			continue
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
func (l *WSListener) Snapshot() ([]observation, map[int]int, int, int, int) {
	l.mu.Lock()
	defer l.mu.Unlock()
	obs := make([]observation, len(l.observations))
	copy(obs, l.observations)
	seen := make(map[int]int, len(l.seen))
	for k, v := range l.seen {
		seen[k] = v
	}
	return obs, seen, l.outOfOrder, l.duplicates, l.reconnects
}

// Close shuts down the listener.
func (l *WSListener) Close() error {
	select {
	case <-l.closeCh:
	default:
		close(l.closeCh)
	}
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
