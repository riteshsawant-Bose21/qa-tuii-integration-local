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
	"fusion/internal/utils"
)

type clientTarget struct {
	key  string
	addr *net.UDPAddr
}

const (
	maxConcurrent     = 32
	queueElementSize  = 2048
	ackRetryInterval  = 500 * time.Millisecond
	ackMaxAttempts    = 6
	clientStaleTTL    = 10 * time.Second
	maxUDPPayloadSize = 65507
)

type packet struct {
	data []byte
	addr *net.UDPAddr
}

type UDPServer struct {
	*Listener
	handler *handler.Handler

	clientsMu sync.RWMutex
	clients   map[string]*clientState

	// Workers
	queue      chan packet
	wg         sync.WaitGroup
	numWorkers int

	// Raw file descriptor for sendmmsg batching (Linux only, -1 if unavailable)
	rawFd int

	// ACK handling
	pendingMu            sync.Mutex
	pending              map[string]*pendingBroadcast
	lastBroadcastEpoch   atomic.Uint64
	lastBroadcastVersion atomic.Uint64
	lastBroadcastSentAt  atomic.Int64
	enqueuedPackets      atomic.Uint64
	droppedPackets       atomic.Uint64
	handledPackets       atomic.Uint64
	ackPackets           atomic.Uint64
	responsesSent        atomic.Uint64
	broadcastMessages    atomic.Uint64
	broadcastDatagrams   atomic.Uint64
	maxQueueDepth        atomic.Uint64
	maintenanceEnabled   atomic.Bool
	diagnosticsEnabled   bool

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

type UDPDebugStats struct {
	QueueDepth           int    `json:"queue_depth"`
	QueueCapacity        int    `json:"queue_capacity"`
	MaxQueueDepth        uint64 `json:"max_queue_depth"`
	RegisteredClients    int    `json:"registered_clients"`
	PendingBroadcasts    int    `json:"pending_broadcasts"`
	OldestPendingAgeMs   int64  `json:"oldest_pending_age_ms"`
	EnqueuedPackets      uint64 `json:"enqueued_packets"`
	DroppedPackets       uint64 `json:"dropped_packets"`
	HandledPackets       uint64 `json:"handled_packets"`
	AckPackets           uint64 `json:"ack_packets"`
	ResponsesSent        uint64 `json:"responses_sent"`
	BroadcastMessages    uint64 `json:"broadcast_messages"`
	BroadcastDatagrams   uint64 `json:"broadcast_datagrams"`
	LastBroadcastEpoch   uint64 `json:"last_broadcast_epoch"`
	LastBroadcastVersion uint64 `json:"last_broadcast_version"`
	LastBroadcastSentAt  int64  `json:"last_broadcast_sent_at_ns"`
	MaintenanceEnabled   bool   `json:"maintenance_enabled"`
}

func NewUDPServer(addr string, handler *handler.Handler, diagnosticsEnabled bool) (*UDPServer, error) {
	conn, err := ResolveListenUDP(addr)
	if err != nil {
		return nil, err
	}
	logging.GetLogger().Info("UDP listening on %s", addr)

	queueWorkers := runtime.NumCPU() * 2
	queueSize := queueWorkers * queueElementSize

	srv := &UDPServer{
		handler:            handler,
		queue:              make(chan packet, queueSize),
		numWorkers:         queueWorkers,
		clients:            make(map[string]*clientState),
		pending:            make(map[string]*pendingBroadcast),
		stopCh:             make(chan struct{}),
		diagnosticsEnabled: diagnosticsEnabled,
		rawFd:              -1,
	}

	srv.Listener = NewListener(
		conn,
		defaultBufferSize,
		time.Second,
		srv.enqueuePacket,
	)

	// Extract raw fd for sendmmsg batching (Linux only)
	if fd, err := extractUDPConnFd(conn); err == nil && fd >= 0 {
		srv.rawFd = fd
		logging.GetLogger().Info("UDP sendmmsg batching enabled (fd=%d)", fd)
	}

	for i := 0; i < srv.numWorkers; i++ {
		srv.wg.Add(1)
		go srv.workerLoop()
	}

	srv.Start()
	srv.maintenanceEnabled.Store(true)
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
		if s.diagnosticsEnabled {
			s.enqueuedPackets.Add(1)
			s.observeQueueDepth()
		}
	default:
		if s.diagnosticsEnabled {
			s.droppedPackets.Add(1)
		}
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
	if s.diagnosticsEnabled {
		s.handledPackets.Add(1)
	}
	now := time.Now().UnixNano()
	key := addr.String()

	s.clientsMu.RLock()
	state, ok := s.clients[key]
	s.clientsMu.RUnlock()

	if ok && state != nil {
		state.lastSeen.Store(now)
	} else {
		state = &clientState{addr: addr}
		state.lastSeen.Store(now)
		s.clientsMu.Lock()
		s.clients[key] = state
		s.clientsMu.Unlock()
	}

	var msg api.NotifyMessage
	if err := json.Unmarshal(data, &msg); err == nil && msg.Operation == api.NotifyOpAck {
		if s.diagnosticsEnabled {
			s.ackPackets.Add(1)
		}
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
		s.clientsMu.Lock()
		delete(s.clients, addr.String())
		s.clientsMu.Unlock()
		return
	}
	if s.diagnosticsEnabled {
		s.responsesSent.Add(1)
	}
}

func (s *UDPServer) BroadcastMessage(msg *api.NotifyMessage) error {
	logger := logging.GetLogger()

	if !msg.IsPublic() {
		logger.Warn("message not public")
		return nil
	}

	if msg.Operation == api.NotifyOpDeviceUpdate {
		if msg.ID == "" {
			msg.ID = ulid.Make().String()
		}
		data, err := utils.ToMap(msg.DeviceInfo)
		if err != nil {
			return fmt.Errorf("udp broadcast: failed to convert DeviceInfo to map: %w", err)
		}
		payload, err := s.buildJSONPayload(data, api.Version{}, msg.ID, msg.Operation)

		if err != nil {
			return err
		}

		s.broadcast(payload, msg.ID)
		return nil
	}

	if msg.Operation == api.NotifyOpTimeMachineActivate {
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

		s.broadcastOrRequirePull(payload, msg.ID, sm.GetVersion())

		return nil
	}

	if msg.Operation != api.NotifyOpConfigUpdate {
		logger.Debug("udp broadcast: ignoring unsupported operation=%s", msg.Operation)
		return nil
	}

	if msg.ConfigUpdate == nil {
		return fmt.Errorf("udp broadcast: config_update missing payload")
	}

	if msg.ID == "" {
		msg.ID = ulid.Make().String()
	}

	payload, err := s.buildJSONPayload(
		configObserverPayload(msg.ConfigUpdate),
		msg.ConfigUpdate.Version,
		msg.ID,
		msg.Operation,
		msg.ConfigUpdate.Clear,
	)
	if err != nil {
		return err
	}

	s.broadcastOrRequirePull(payload, msg.ID, msg.ConfigUpdate.Version)

	return nil
}

func configObserverPayload(update *api.ConfigUpdate) map[string]any {
	if update == nil {
		return nil
	}
	if len(update.ObserverData) > 0 {
		return update.ObserverData
	}
	return update.Data
}

func (s *UDPServer) Close() error {
	close(s.stopCh)
	close(s.queue)
	s.wg.Wait()
	return s.conn.Close()
}

// buildJSONPayload creates a JSON byte stream including authoritative Lamport version.
// It injects metadata keys directly into data to avoid an intermediate map copy.
// Callers must not reuse data after this call.
func (s *UDPServer) buildJSONPayload(data map[string]any, version api.Version, msgID string, op api.NotifyOp) ([]byte, error) {
	data[api.FusionVersion] = version.Counter
	data[api.FusionEpoch] = version.Epoch
	if s.diagnosticsEnabled {
		data[api.FusionSentAtNS] = time.Now().UnixNano()
	}
	if msgID != "" {
		data[api.FusionMessageID] = msgID
	}
	if op != "" {
		data[api.FusionOperation] = op
	}
	if len(clear) > 0 && clear[0] {
		payload[api.FusionClear] = true
	}

	b, err := json.Marshal(data)
	if err != nil {
		return nil, fmt.Errorf("marshal error: %w", err)
	}

	return b, nil
}

func (s *UDPServer) buildConfigPullRequiredPayload(version api.Version, msgID string) ([]byte, error) {
	payload := map[string]any{
		api.FusionVersion:   version.Counter,
		api.FusionEpoch:     version.Epoch,
		api.FusionOperation: api.NotifyOpConfigPullRequired,
	}
	if s.diagnosticsEnabled {
		payload[api.FusionSentAtNS] = time.Now().UnixNano()
	}
	if msgID != "" {
		payload[api.FusionMessageID] = msgID
	}
	json, err := json.Marshal(payload)
	if err != nil {
		return nil, fmt.Errorf("marshal config pull notification: %w", err)
	}
	return json, nil
}

func (s *UDPServer) broadcastOrRequirePull(payload []byte, msgID string, version api.Version) {
	s.lastBroadcastEpoch.Store(version.Epoch)
	s.lastBroadcastVersion.Store(version.Counter)

	if len(payload) <= maxUDPPayloadSize {
		s.broadcast(payload, msgID)
		return
	}

	pullRequiredPayload, err := s.buildConfigPullRequiredPayload(version, msgID)
	if err != nil {
		logging.GetLogger().Error("udp config pull notification build failed: %v", err)
		return
	}
	logging.GetLogger().Warn(
		"udp payload size %d exceeds max %d; broadcasting config_pull_required notification",
		len(payload),
		maxUDPPayloadSize,
	)
	s.broadcast(pullRequiredPayload, msgID)
}

func (s *UDPServer) broadcast(payload []byte, msgID string) {
	if msgID == "" {
		msgID = ulid.Make().String()
	}
	if s.diagnosticsEnabled {
		s.broadcastMessages.Add(1)
		s.lastBroadcastSentAt.Store(time.Now().UnixNano())
	}

	// Snapshot clients under read lock, then write outside the lock.
	s.clientsMu.RLock()
	targets := make([]clientTarget, 0, len(s.clients))
	for key, state := range s.clients {
		if state != nil && state.addr != nil {
			targets = append(targets, clientTarget{key: key, addr: state.addr})
		}
	}
	s.clientsMu.RUnlock()

	if len(targets) == 0 {
		return
	}

	awaiting := make(map[string]*net.UDPAddr, len(targets))
	var failed []string

	// Try batched sendmmsg on Linux when fd is available
	if s.rawFd >= 0 {
		failedIdxs := sendBatch(s.rawFd, payload, targets)
		failedSet := make(map[int]bool, len(failedIdxs))
		for _, idx := range failedIdxs {
			failedSet[idx] = true
		}
		for i, t := range targets {
			if failedSet[i] {
				failed = append(failed, t.key)
			} else {
				awaiting[t.key] = t.addr
				if s.diagnosticsEnabled {
					s.broadcastDatagrams.Add(1)
				}
			}
		}
	} else {
		// Fallback: individual sendto per client
		for _, t := range targets {
			if _, err := s.conn.WriteToUDP(payload, t.addr); err != nil {
				logging.GetLogger().Warn("udp broadcast to %s failed: %v", t.key, err)
				failed = append(failed, t.key)
				continue
			}
			awaiting[t.key] = t.addr
			if s.diagnosticsEnabled {
				s.broadcastDatagrams.Add(1)
			}
		}
	}

	// Remove failed clients
	if len(failed) > 0 {
		s.clientsMu.Lock()
		for _, key := range failed {
			delete(s.clients, key)
		}
		s.clientsMu.Unlock()
	}

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
			s.pruneClients()
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
	var expiredClients []string
	for id, pb := range s.pending {
		if pb.attempts >= ackMaxAttempts {
			for addrStr := range pb.awaiting {
				expiredClients = append(expiredClients, addrStr)
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
		maps.Copy(addrs, pb.awaiting)
		retries = append(retries, retryItem{id: id, payload: pb.payload, addrs: addrs})
	}
	s.pendingMu.Unlock()

	// Remove expired clients outside pending lock
	if len(expiredClients) > 0 {
		s.clientsMu.Lock()
		for _, addrStr := range expiredClients {
			delete(s.clients, addrStr)
		}
		s.clientsMu.Unlock()
	}

	var retryFailed []string
	for _, item := range retries {
		for addrStr, addr := range item.addrs {
			if _, err := s.conn.WriteToUDP(item.payload, addr); err != nil {
				logging.GetLogger().Warn("udp retry to %s failed: %v", addrStr, err)
				retryFailed = append(retryFailed, addrStr)
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

	if len(retryFailed) > 0 {
		s.clientsMu.Lock()
		for _, addrStr := range retryFailed {
			delete(s.clients, addrStr)
		}
		s.clientsMu.Unlock()
	}
}

func (s *UDPServer) pruneClients() {
	cutoff := time.Now().Add(-clientStaleTTL)

	s.clientsMu.Lock()
	var stale []string
	for key, state := range s.clients {
		if state == nil {
			delete(s.clients, key)
			continue
		}
		lastSeen := time.Unix(0, state.lastSeen.Load())
		if lastSeen.Before(cutoff) {
			logging.GetLogger().Warn("Removing stale UDP client: %s (last seen %s)", key, lastSeen.Format(time.RFC3339))
			delete(s.clients, key)
			stale = append(stale, key)
		}
	}
	s.clientsMu.Unlock()

	for _, key := range stale {
		s.removeClientFromPending(key)
	}
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

func (s *UDPServer) observeQueueDepth() {
	current := uint64(len(s.queue))
	for {
		existing := s.maxQueueDepth.Load()
		if current <= existing {
			return
		}
		if s.maxQueueDepth.CompareAndSwap(existing, current) {
			return
		}
	}
}

func (s *UDPServer) Stats() UDPDebugStats {
	s.clientsMu.RLock()
	numClients := len(s.clients)
	s.clientsMu.RUnlock()

	stats := UDPDebugStats{
		QueueDepth:           len(s.queue),
		QueueCapacity:        cap(s.queue),
		MaxQueueDepth:        s.maxQueueDepth.Load(),
		RegisteredClients:    numClients,
		EnqueuedPackets:      s.enqueuedPackets.Load(),
		DroppedPackets:       s.droppedPackets.Load(),
		HandledPackets:       s.handledPackets.Load(),
		AckPackets:           s.ackPackets.Load(),
		ResponsesSent:        s.responsesSent.Load(),
		BroadcastMessages:    s.broadcastMessages.Load(),
		BroadcastDatagrams:   s.broadcastDatagrams.Load(),
		LastBroadcastEpoch:   s.lastBroadcastEpoch.Load(),
		LastBroadcastVersion: s.lastBroadcastVersion.Load(),
		LastBroadcastSentAt:  s.lastBroadcastSentAt.Load(),
		MaintenanceEnabled:   s.maintenanceEnabled.Load(),
	}

	now := time.Now()
	s.pendingMu.Lock()
	stats.PendingBroadcasts = len(s.pending)
	if len(s.pending) > 0 {
		var oldest time.Time
		for _, pb := range s.pending {
			if oldest.IsZero() || pb.lastSent.Before(oldest) {
				oldest = pb.lastSent
			}
		}
		if !oldest.IsZero() {
			stats.OldestPendingAgeMs = now.Sub(oldest).Milliseconds()
		}
	}
	s.pendingMu.Unlock()

	return stats
}
