package network

import (
	"fmt"
	"math/rand"
	"net"
	"runtime"
	"sync"
	"time"

	json "github.com/goccy/go-json"

	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/server"
	"fusion/internal/server/handler"
)

const (
	maxConcurrent    = 32
	queueElementSize = 2048
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
	pending sync.Map
}

func NewUDPServer(addr string, handler *handler.Handler) (*UDPServer, error) {
	conn, err := ResolveListenUDP(addr)
	if err != nil {
		return nil, err
	}
	logging.GetLogger().Info("UDP listening on %s", addr)

	queueWorkers := runtime.NumCPU() * 2
	queueSize := queueWorkers * queueElementSize

	srv := &UDPServer{
		handler:    handler,
		queue:      make(chan packet, queueSize),
		numWorkers: queueWorkers,
		clients:    sync.Map{},
		pending:    sync.Map{},
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
	case s.queue <- packet{data, addr}:
	default:
		// Drop packet if queue full

		// Log ~0.1% of drops
		if rand.Intn(1000) == 0 {
			logging.GetLogger().Warn("UDP queue full; dropping packet from %s", addr)
		}

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
		if chVal, ok := s.pending.Load(msg.ID); ok {
			ch := chVal.(chan struct{})
			close(ch)
			s.pending.Delete(msg.ID)
		}
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

	logger := logging.GetLogger()

	// Limit the number of concurrent writes
	sem := make(chan struct{}, maxConcurrent)
	var wg sync.WaitGroup

	s.clients.Range(func(k, v any) bool {
		addr, ok := v.(*net.UDPAddr)
		if !ok || addr == nil {
			return true
		}

		wg.Add(1)

		// Acquire a slot
		sem <- struct{}{}
		go func(k string, addr *net.UDPAddr) {
			defer wg.Done()
			defer func() {
				// Release the slot
				<-sem
			}()

			if _, err := s.conn.WriteToUDP(data, addr); err != nil {
				logger.Warn("broadcast to %s failed: %v", k, err)
				s.clients.Delete(k)
			}
		}(k.(string), addr)
		return true
	})

	wg.Wait()
	return nil
}

func (s *UDPServer) Close() error {
	close(s.queue)
	s.wg.Wait()
	return s.conn.Close()
}
