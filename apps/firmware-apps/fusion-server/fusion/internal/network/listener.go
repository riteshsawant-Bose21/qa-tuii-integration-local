package network

import (
	"net"
	"sync"
	"time"

	"fusion/internal/logging"
)

const (
	defaultBufferSize = 65535
)

type PacketHandler func(data []byte, addr *net.UDPAddr)

type Listener struct {
	conn       *net.UDPConn
	stopChan   chan struct{}
	wg         sync.WaitGroup
	BufferSize int
	Timeout    time.Duration
	Handler    PacketHandler
}

// NewListener creates a Listener configured with your buffer, timeout, and handler.
func NewListener(
	conn *net.UDPConn,
	bufferSize int,
	timeout time.Duration,
	handler PacketHandler,
) *Listener {
	return &Listener{
		conn:       conn,
		stopChan:   make(chan struct{}),
		BufferSize: bufferSize,
		Timeout:    timeout,
		Handler:    handler,
	}
}

// Start uses the stored BufferSize, Timeout and Handler.
func (l *Listener) Start() {
	l.wg.Add(1)
	go func() {
		defer l.wg.Done()
		buf := make([]byte, l.BufferSize)
		for {
			select {
			case <-l.stopChan:
				return
			default:
				l.conn.SetReadDeadline(time.Now().Add(l.Timeout))
				n, addr, err := l.conn.ReadFromUDP(buf)
				if err != nil {
					if ne, ok := err.(net.Error); ok && ne.Timeout() {
						continue
					}
					logging.GetLogger().Error("read error from %v: %v", addr, err)
					continue
				}
				go l.Handler(buf[:n], addr)
			}
		}
	}()
}

// Stop cleanly shuts down the listener.
func (l *Listener) Stop() {
	close(l.stopChan)
	l.conn.Close()
	l.wg.Wait()
}
