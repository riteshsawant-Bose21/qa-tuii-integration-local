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
	"github.com/oklog/ulid/v2"

	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/server"
	"fusion/internal/server/handler"
)

const (
	maxConcurrent    = 32
	queueElementSize = 2048
	ackRetryInterval = 500 * time.Millisecond
	ackMaxAttempts   = 6
	clientStaleTTL   = 10 * time.Second
)

type packet struct {
	data []byte
	addr *net.UDPAddr
}

type UDPServer struct {
	*Listener
	handler *handler.Handler

	clients sync.Map // string:*clientState

	// Workers
	queue      chan packet
	wg         sync.WaitGroup
	numWorkers int

	// ACK handling
	pendingMu            sync.Mutex
	pending              map[string]*pendingBroadcast
	lastBroadcastEpoch   atomic.Uint64
	lastBroadcastVersion atomic.Uint64

	stopCh chan struct{}
}

type clientState struct {
	addr     *net.UDPAddr
	lastSeen atomic.Int64
}

type pendingBroadcast struct {
	payload  []byte
	awaiting map[string]*net.UDPAddr
	attempts int
	lastSent time.Time
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
		pending:    make(map[string]*pendingBroadcast),
		stopCh:     make(chan struct{}),
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
	go srv.maintenanceLoop()
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
	now := time.Now().UnixNano()
	if val, ok := s.clients.Load(addr.String()); ok {
		if state, ok := val.(*clientState); ok && state != nil {
			state.lastSeen.Store(now)
		}
	} else {
		state := &clientState{addr: addr}
		state.lastSeen.Store(now)
		s.clients.Store(addr.String(), state)
	}

	var msg api.NotifyMessage
	if err := json.Unmarshal(data, &msg); err == nil && msg.Operation == api.NotifyOpAck {
		s.handleAck(msg.ID, addr)
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

	if msg.Operation == api.NotifyOpSnapActivate {
		if msg.ID == "" {
			msg.ID = ulid.Make().String()
		}

		// Load the snapshot data
		sm := s.handler.StateManager
		snapshotState := sm.GetFullState()
		snapshotFlat := snapshotState.Flatten()

		payload, err := s.buildJSONPayload(snapshotFlat, sm.GetVersion(), msg.ID, msg.Operation)
		if err != nil {
			return err
		}

		s.broadcast(payload, msg.ID)

		return nil
	}

	if msg.Operation != api.NotifyOpConfigUpdate {
		logger.Debug("udp broadcast: ignoring unsupported operation=%s", msg.Operation)
		return nil
	}

	if msg.ConfigUpdate == nil {
		return fmt.Errorf("udp broadcast: config_update missing payload")
	}

	// Normal config updates: apply Lamport version gating
	if msg.Operation == api.NotifyOpConfigUpdate &&
		msg.ConfigUpdate != nil {

		v := msg.ConfigUpdate.Version

		last := api.Version{
			Epoch:   s.lastBroadcastEpoch.Load(),
			Counter: s.lastBroadcastVersion.Load(),
		}

		if v.Less(last) {
			logger.Debug(
				"udp broadcast: skipping stale/duplicate config_update version=%v (last=%v)",
				v, last,
			)
			return nil
		}

		s.lastBroadcastEpoch.Store(v.Epoch)
		s.lastBroadcastVersion.Store(v.Counter)
	}

	if msg.ID == "" {
		msg.ID = ulid.Make().String()
	}

	payload, err := s.buildJSONPayload(msg.ConfigUpdate.Data, msg.ConfigUpdate.Version, msg.ID, msg.Operation)
	if err != nil {
		return err
	}

	s.broadcast(payload, msg.ID)

	return nil
}

func (s *UDPServer) Close() error {
	close(s.stopCh)
	close(s.queue)
	s.wg.Wait()
	return s.conn.Close()
}

// buildPayload creates a JSON byte stream including authoritative Lamport version
func (s *UDPServer) buildJSONPayload(data map[string]any, version api.Version, msgID string, op api.NotifyOp) ([]byte, error) {

	payload := make(map[string]any, len(data)+4)
	maps.Copy(payload, data)
	payload[api.FusionVersion] = version.Counter
	payload[api.FusionEpoch] = version.Epoch
	if msgID != "" {
		payload[api.FusionMessageID] = msgID
	}
	if op != "" {
		payload[api.FusionOperation] = op
	}

	json, err := json.Marshal(payload)
	if err != nil {
		return nil, fmt.Errorf("marshal error: %w", err)
	}

	return json, nil
}

func (s *UDPServer) broadcast(payload []byte, msgID string) {
	if msgID == "" {
		msgID = ulid.Make().String()
	}

	awaiting := make(map[string]*net.UDPAddr)

	s.clients.Range(func(k, v any) bool {
		state, ok := v.(*clientState)
		if !ok || state == nil || state.addr == nil {
			return true
		}

		if _, err := s.conn.WriteToUDP(payload, state.addr); err != nil {
			logging.GetLogger().Warn("udp broadcast to %s failed: %v", k, err)
			s.clients.Delete(k)
			return true
		}

		awaiting[k.(string)] = state.addr
		return true
	})

	if len(awaiting) == 0 {
		return
	}

	s.pendingMu.Lock()
	s.pending[msgID] = &pendingBroadcast{
		payload:  payload,
		awaiting: awaiting,
		attempts: 1,
		lastSent: time.Now(),
	}
	s.pendingMu.Unlock()
}

func (s *UDPServer) handleAck(msgID string, addr *net.UDPAddr) {
	if msgID == "" || addr == nil {
		return
	}
	s.pendingMu.Lock()
	if pb, ok := s.pending[msgID]; ok {
		delete(pb.awaiting, addr.String())
		if len(pb.awaiting) == 0 {
			delete(s.pending, msgID)
		}
	}
	s.pendingMu.Unlock()
}

func (s *UDPServer) maintenanceLoop() {
	retryTicker := time.NewTicker(ackRetryInterval)
	pruneTicker := time.NewTicker(time.Second)
	defer retryTicker.Stop()
	defer pruneTicker.Stop()

	for {
		select {
		case <-s.stopCh:
			return
		case <-retryTicker.C:
			s.retryPending()
		case <-pruneTicker.C:
			logging.GetLogger().Warn(
				"UDP client prunning disabled. Enabled it in PR-295",
			)
			// s.pruneClients()
		}
	}
}

func (s *UDPServer) retryPending() {
	now := time.Now()

	type retryItem struct {
		id      string
		payload []byte
		addrs   map[string]*net.UDPAddr
	}

	var retries []retryItem

	s.pendingMu.Lock()
	for id, pb := range s.pending {
		if pb.attempts >= ackMaxAttempts {
			for addrStr := range pb.awaiting {
				s.clients.Delete(addrStr)
			}
			delete(s.pending, id)
			continue
		}

		if now.Sub(pb.lastSent) < ackRetryInterval {
			continue
		}

		pb.attempts++
		pb.lastSent = now

		addrs := make(map[string]*net.UDPAddr, len(pb.awaiting))
		for k, v := range pb.awaiting {
			addrs[k] = v
		}
		retries = append(retries, retryItem{id: id, payload: pb.payload, addrs: addrs})
	}
	s.pendingMu.Unlock()

	for _, item := range retries {
		for addrStr, addr := range item.addrs {
			if _, err := s.conn.WriteToUDP(item.payload, addr); err != nil {
				logging.GetLogger().Warn("udp retry to %s failed: %v", addrStr, err)
				s.clients.Delete(addrStr)
				s.pendingMu.Lock()
				if pb, ok := s.pending[item.id]; ok {
					delete(pb.awaiting, addrStr)
					if len(pb.awaiting) == 0 {
						delete(s.pending, item.id)
					}
				}
				s.pendingMu.Unlock()
			}
		}
	}
}

func (s *UDPServer) pruneClients() {
	cutoff := time.Now().Add(-clientStaleTTL)
	s.clients.Range(func(k, v any) bool {
		state, ok := v.(*clientState)
		if !ok || state == nil {
			s.clients.Delete(k)
			return true
		}

		lastSeen := time.Unix(0, state.lastSeen.Load())
		if lastSeen.Before(cutoff) {
			logging.GetLogger().Warn("Removing stale UDP client: %s (last seen %s)", k, lastSeen.Format(time.RFC3339))
			s.clients.Delete(k)
			s.removeClientFromPending(k.(string))
		}

		return true
	})
}

func (s *UDPServer) removeClientFromPending(addrStr string) {
	s.pendingMu.Lock()
	for id, pb := range s.pending {
		delete(pb.awaiting, addrStr)
		if len(pb.awaiting) == 0 {
			delete(s.pending, id)
		}
	}
	s.pendingMu.Unlock()
}
