package network

import (
	"encoding/json"
	"fmt"
	"net"
	"sync"
	"time"

	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/server"
	"fusion/internal/server/handler"
)

const (
	queueSize    = 1024
	queueWorkers = 4
)

type packet struct {
	data []byte
	addr *net.UDPAddr
}

type UDPServer struct {
	*Listener
	handler *handler.Handler

	clients sync.Map // string:*net.UDPAddr

	// Workers
	queue      chan packet
	wg         sync.WaitGroup
	numWorkers int

	// ACK handling
	pending    map[string]chan struct{}
	pendingMux sync.Mutex

	bufPool sync.Pool
}

func NewUDPServer(addr string, handler *handler.Handler) (*UDPServer, error) {
	conn, err := ResolveListenUDP(addr)
	if err != nil {
		return nil, err
	}
	logging.GetLogger().Info("UDP listening on %s", addr)

	srv := &UDPServer{
		handler:    handler,
		queue:      make(chan packet, queueSize),
		numWorkers: queueWorkers,
		clients:    sync.Map{},
		pending:    make(map[string]chan struct{}),
		bufPool:    sync.Pool{New: func() any { return make([]byte, defaultBufferSize) }},
	}

	srv.Listener = NewListener(
		conn,
		defaultBufferSize,
		time.Second,
		srv.enqueuePacket,
	)

	for i := 0; i < srv.numWorkers; i++ {
		srv.wg.Add(1)
		go srv.workerLoop()
	}

	srv.Start()
	return srv, nil
}

// enqueuePacket is called from the I/O goroutine. Keep it very fast.
func (s *UDPServer) enqueuePacket(data []byte, addr *net.UDPAddr) {
	select {
	case s.queue <- packet{append([]byte(nil), data...), addr}:
	default:
		// Drop packet if queue full
		logging.GetLogger().Warn("UDP queue full; dropping packet from %s", addr)
	}
}

// workerLoop runs concurrently to process packets
func (s *UDPServer) workerLoop() {
	defer s.wg.Done()
	for pkt := range s.queue {
		s.handlePacket(pkt.data, pkt.addr)
	}
}

func (s *UDPServer) handlePacket(data []byte, addr *net.UDPAddr) {
	s.clients.Store(addr.String(), addr)

	var msg api.NotifyMessage
	if err := json.Unmarshal(data, &msg); err == nil && msg.Operation == api.NotifyOpAck {
		s.pendingMux.Lock()
		if ch, ok := s.pending[msg.ID]; ok {
			close(ch)
			delete(s.pending, msg.ID)
		}
		s.pendingMux.Unlock()
		return
	}

	resp, err := s.handler.HandleUDPMessage(data)
	if err != nil {
		s.sendResponse(addr, server.UDPResponse{
			Status:  "error",
			Message: err.Error(),
		})
		return
	}
	s.sendResponse(addr, resp)
}

func (s *UDPServer) sendResponse(addr *net.UDPAddr, v any) {
	b, err := json.Marshal(v)
	if err != nil {
		logging.GetLogger().Error("marshal error: %v", err)
		return
	}
	if _, err := s.conn.WriteToUDP(b, addr); err != nil {
		logging.GetLogger().Error("write error to %s: %v", addr, err)
		s.clients.Delete(addr.String())
	}
}

func (s *UDPServer) BroadcastMessage(msg *api.NotifyMessage) error {
	if !msg.IsPublic() {
		return nil
	}

	data, err := json.Marshal(msg.ConfigUpdate.Data)
	if err != nil {
		return fmt.Errorf("marshal update: %w", err)
	}

	var dead []string
	logger := logging.GetLogger()

	s.clients.Range(func(k, v any) bool {
		addr := v.(*net.UDPAddr)
		go func(k string, addr *net.UDPAddr) {
			if _, err := s.conn.WriteToUDP(data, addr); err != nil {
				logger.Warn("broadcast to %s failed: %v", k, err)
				s.clients.Delete(k)
			}
		}(k.(string), addr)
		return true
	})

	for _, k := range dead {
		s.clients.Delete(k)
	}

	return nil
}

func (s *UDPServer) Close() error {
	close(s.queue)
	s.wg.Wait()
	return s.conn.Close()
}
