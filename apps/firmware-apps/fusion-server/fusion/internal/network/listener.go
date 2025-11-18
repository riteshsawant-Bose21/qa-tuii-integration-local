package network

import (
	"errors"
	"net"
	"sync"
	"sync/atomic"
	"time"

	"fusion/internal/logging"
)

const defaultBufferSize = 65535

type PacketHandler func(data []byte, addr *net.UDPAddr)

type Listener struct {
	conn       *net.UDPConn
	stopChan   chan struct{}
	wg         sync.WaitGroup
	BufferSize int
	Timeout    time.Duration
	Handler    PacketHandler

	started atomic.Bool
}

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

// IsClosed checks for any "connection closed" condition.
func isConnClosed(err error) bool {
	return errors.Is(err, net.ErrClosed) ||
		err.Error() == "use of closed network connection"
}

func (l *Listener) Start() {
	// Prevent accidental double-starts
	if !l.started.CompareAndSwap(false, true) {
		logging.GetLogger().Error("listener already started")
		return
	}

	if l.Handler == nil {
		panic("Listener.Handler must not be nil")
	}

	l.wg.Add(1)
	go func() {
		defer l.wg.Done()

		buf := make([]byte, l.BufferSize)
		logger := logging.GetLogger()

		for {
			select {
			case <-l.stopChan:
				return
			default:
			}

			// Apply deadline only if configured
			if l.Timeout > 0 {
				_ = l.conn.SetReadDeadline(time.Now().Add(l.Timeout))
			}

			n, addr, err := l.conn.ReadFromUDP(buf)
			if err != nil {
				if ne, ok := err.(net.Error); ok && ne.Timeout() {
					continue
				}
				if isConnClosed(err) {
					return
				}

				logger.Error("UDP read error (from %v): %v", addr, err)
				continue
			}

			// Panic-safe handler
			func() {
				defer func() {
					if r := recover(); r != nil {
						logger.Error("panic in UDP handler: %v", r)
					}
				}()
				l.Handler(buf[:n], addr)
			}()
		}
	}()
}

func (l *Listener) Stop() {
	if l.started.CompareAndSwap(true, false) {
		close(l.stopChan)
		_ = l.conn.Close()
		l.wg.Wait()
	}
}
