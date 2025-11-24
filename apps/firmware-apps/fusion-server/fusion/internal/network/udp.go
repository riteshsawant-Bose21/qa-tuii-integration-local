package network

import (
	"fmt"
	"maps"
	"math/rand"
	"net"
	"runtime"
	"sync"
	"sync/atomic"
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
	pending              sync.Map
	lastBroadcastVersion atomic.Int64
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

	// Copy to prevent concurrent buffer reuse corruption
	buf := make([]byte, len(data))
	copy(buf, data)

	select {
	case s.queue <- packet{buf, addr}:
	default:
		if rand.Intn(1000) == 0 {
			logging.GetLogger().Warn("UDP queue full. Dropping packet from %s", addr)
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
	logger := logging.GetLogger()

	if msg.Operation == api.NotifyOpConfigUpdate && msg.ConfigUpdate != nil {

		// msg.ConfigUpdate.Version.Counter MUST be the effective Lamport version
		// produced by ApplyUpdate. The caller ensures this via:
		//     cfg.Version = sm.GetVersion()

		// Effective Lamport timestamp
		v := msg.ConfigUpdate.Version.Counter
		last := s.lastBroadcastVersion.Load()

		// Skip if effectiveVersion <= lastBroadcastVersion
		if v <= last {
			logger.Debug(
				"UDP broadcast: skipping stale/duplicate config_update version=%d (last=%d)",
				v, last,
			)
			return nil
		}

		// Store the effective version as last broadcast
		s.lastBroadcastVersion.Store(v)
	}

	// Build payload including effective Lamport version
	payload := make(map[string]any, len(msg.ConfigUpdate.Data)+1)

	// Copy user data
	maps.Copy(payload, msg.ConfigUpdate.Data)

	// Add authoritative version key
	payload["_fusion_version"] = msg.ConfigUpdate.Version.Counter

	data, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("marshal update: %w", err)
	}

	// Send to all clients synchronously
	s.clients.Range(func(k, v any) bool {
		addr, ok := v.(*net.UDPAddr)
		if !ok || addr == nil {
			return true
		}

		if _, err := s.conn.WriteToUDP(data, addr); err != nil {
			logger.Warn("Broadcast to %s failed: %v", k, err)
			s.clients.Delete(k)
		}
		return true
	})

	return nil
}

func (s *UDPServer) Close() error {
	close(s.queue)
	s.wg.Wait()
	return s.conn.Close()
}
