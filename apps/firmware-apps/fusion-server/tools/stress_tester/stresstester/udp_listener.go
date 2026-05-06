package stresstester

import (
	"fmt"
	"net"
	"sync"
	"time"

	json "github.com/goccy/go-json"
)

const udpReadBufSize = 64 * 1024

// UDPListener binds a local UDP socket, registers with the fusion-server
// by sending a GET handshake, then captures all config_update broadcasts.
type UDPListener struct {
	name       string
	conn       *net.UDPConn
	serverAddr *net.UDPAddr

	mu           sync.Mutex
	observations []observation
	seen         map[int]int // gain → count
	maxGain      int
	outOfOrder   int
	duplicates   int
	ready        chan struct{}
	stopped      chan struct{}
	stopOnce     sync.Once
	err          error // set if handshake fails
}

// NewUDPListener creates, binds, registers, and starts a UDP listener.
func NewUDPListener(name, bindIP, serverHost string) (*UDPListener, error) {
	serverAddr, err := net.ResolveUDPAddr("udp4", serverHost)
	if err != nil {
		return nil, fmt.Errorf("udp listener %s resolve server %s: %w", name, serverHost, err)
	}

	// Bind on an ephemeral port on the specified local IP.
	localAddr, err := net.ResolveUDPAddr("udp4", net.JoinHostPort(bindIP, "0"))
	if err != nil {
		return nil, fmt.Errorf("udp listener %s resolve bind %s: %w", name, bindIP, err)
	}

	conn, err := net.ListenUDP("udp4", localAddr)
	if err != nil {
		return nil, fmt.Errorf("udp listener %s listen: %w", name, err)
	}

	l := &UDPListener{
		name:       name,
		conn:       conn,
		serverAddr: serverAddr,
		seen:       make(map[int]int),
		ready:      make(chan struct{}),
		stopped:    make(chan struct{}),
	}

	go l.loop()
	return l, nil
}

func (l *UDPListener) loop() {
	defer close(l.stopped)

	buf := make([]byte, udpReadBufSize)
	handshake, _ := json.Marshal(map[string]any{"action": "get"})

	// 1. Send GET handshake with retries — the server may not respond
	//    immediately when many listeners register at once.
	registered := false
	for attempt := 0; attempt < 3; attempt++ {
		if _, err := l.conn.WriteToUDP(handshake, l.serverAddr); err != nil {
			l.err = fmt.Errorf("handshake write: %w", err)
			return
		}
		l.conn.SetReadDeadline(time.Now().Add(5 * time.Second))
		n, _, err := l.conn.ReadFromUDP(buf)
		if err != nil {
			if ne, ok := err.(net.Error); ok && ne.Timeout() {
				fmt.Printf("  [%s] handshake attempt %d timed out, retrying...\n", l.name, attempt+1)
				continue // retry
			}
			l.err = fmt.Errorf("handshake read: %w", err)
			return // real error
		}
		_ = n
		registered = true
		break
	}
	if !registered {
		l.err = fmt.Errorf("handshake failed after 3 attempts (no response from %s)", l.serverAddr)
		return
	}
	l.conn.SetReadDeadline(time.Time{})
	close(l.ready)

	// 3. Read loop.
	for {
		l.conn.SetReadDeadline(time.Now().Add(30 * time.Second))
		n, _, err := l.conn.ReadFromUDP(buf)
		if err != nil {
			if ne, ok := err.(net.Error); ok && ne.Timeout() {
				// Silent timeout — keep going, server may not have sent yet.
				continue
			}
			return // real error or connection closed
		}
		recvAt := time.Now()

		var msg map[string]any
		if err := json.Unmarshal(buf[:n], &msg); err != nil {
			continue
		}

		// ACK if _fusion_msg_id is present.
		if msgID, ok := msg["_fusion_msg_id"].(string); ok && msgID != "" {
			ack, _ := json.Marshal(map[string]any{
				"operation": "ack",
				"id":        msgID,
			})
			l.conn.WriteToUDP(ack, l.serverAddr)
		}

		// Filter to config_update only.
		if op, _ := msg["_fusion_op"].(string); op != "config_update" {
			continue
		}

		gain, ok := extractGain(msg)
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

// Ready returns a channel that closes when the listener has registered.
func (l *UDPListener) Ready() <-chan struct{} { return l.ready }

// Stopped returns a channel that closes when the read loop exits.
func (l *UDPListener) Stopped() <-chan struct{} { return l.stopped }

// Snapshot returns a copy of observations and stats.
func (l *UDPListener) Snapshot() ([]observation, map[int]int, int, int) {
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
func (l *UDPListener) Close() error {
	return l.conn.Close()
}

// Name returns the listener name.
func (l *UDPListener) Name() string { return l.name }

// Err returns the error that caused the listener to fail, if any.
func (l *UDPListener) Err() error { return l.err }

// Address returns the local bound address string.
func (l *UDPListener) Address() string { return l.conn.LocalAddr().String() }
