package server

import (
	"net"
	"sync"
	"sync/atomic"
	"time"

	model "fusion/internal/gen/proto/fusion"

	json "github.com/goccy/go-json"
	"github.com/gorilla/websocket"

	"fusion-services-core/logging"
)

// telemetryFilterRequest is the UDP message sent to the telemetry core.
type telemetryFilterRequest struct {
	MessageName string                    `json:"message_name"`
	PacketID    uint64                    `json:"packet_id"`
	Parameters  telemetryFilterParameters `json:"parameters"`
}

type telemetryFilterParameters struct {
	Value []string `json:"value"`
}

// udpConnPool maintains persistent UDP connections per address to avoid
// repeated socket creation/teardown.
type udpConnPool struct {
	mu    sync.Mutex
	conns map[string]net.Conn
}

func newUDPConnPool() *udpConnPool {
	return &udpConnPool{
		conns: make(map[string]net.Conn),
	}
}

const udpSendMaxRetries = 3

func (p *udpConnPool) send(addr string, data []byte) error {
	var lastErr error
	for attempt := 0; attempt < udpSendMaxRetries; attempt++ {
		conn, err := p.getOrDial(addr)
		if err != nil {
			lastErr = err
			continue
		}

		_ = conn.SetWriteDeadline(time.Now().Add(1 * time.Second))
		_, err = conn.Write(data)
		if err == nil {
			return nil
		}

		lastErr = err
		p.mu.Lock()
		delete(p.conns, addr)
		p.mu.Unlock()
		_ = conn.Close()
	}
	return lastErr
}

func (p *udpConnPool) getOrDial(addr string) (net.Conn, error) {
	p.mu.Lock()
	conn, ok := p.conns[addr]
	if ok && conn != nil {
		p.mu.Unlock()
		return conn, nil
	}

	newConn, err := net.Dial("udp", addr)
	if err != nil {
		p.mu.Unlock()
		return nil, err
	}
	p.conns[addr] = newConn
	p.mu.Unlock()
	return newConn, nil
}

// MeterFilterManager tracks a per-connection list of meter IDs and maintains a
// union master list. Whenever the master list changes it sends update_filter_req
// to the telemetry core via UDP so only the relevant meter IDs are forwarded.
type MeterFilterManager struct {
	mu          sync.RWMutex
	connFilters map[*websocket.Conn]map[string]bool
	masterList  map[string]bool
	packetID    atomic.Uint64

	pool *udpConnPool

	debounceMu      sync.Mutex
	debouncePending bool
	debounceTimer   *time.Timer
	pendingIDs      []string
	pendingAddrs    []string
}

const filterDebounceInterval = 50 * time.Millisecond

func NewMeterFilterManager() *MeterFilterManager {
	return &MeterFilterManager{
		connFilters: make(map[*websocket.Conn]map[string]bool),
		masterList:  make(map[string]bool),
		pool:        newUDPConnPool(),
	}
}

// SetFilter replaces the meter ID filter for conn with ids and recomputes the
// master list. Passing an empty slice stores an empty filter for the connection,
// which removes its contribution from the master list.
func (m *MeterFilterManager) SetFilter(conn *websocket.Conn, ids []string, deviceAddressArray []string) {
	m.mu.Lock()
	defer m.mu.Unlock()

	set := make(map[string]bool, len(ids))
	for _, id := range ids {
		set[id] = true
	}
	m.connFilters[conn] = set
	m.recomputeAndSend(deviceAddressArray)
}

func (m *MeterFilterManager) RemoveFilter(conn *websocket.Conn, deviceAddressArray []string) {
	m.mu.Lock()
	defer m.mu.Unlock()

	_, existed := m.connFilters[conn]
	delete(m.connFilters, conn)

	if existed || len(m.masterList) > 0 {
		m.recomputeAndSend(deviceAddressArray)
	}
}

// FilterMeterDataForConn returns a copy of msg with parameters.value filtered to
// only the samples whose block_name is in conn's registered filter.
// If the connection has no filter registered, nil is returned.
func (m *MeterFilterManager) FilterMeterDataForConn(conn *websocket.Conn, msg *model.MeterDataMessage) *model.MeterDataMessage {
	m.mu.RLock()
	filter := m.connFilters[conn]
	m.mu.RUnlock()

	if filter == nil {
		return nil
	}

	filtered := make([]*model.MeterData, 0, min(len(msg.Parameters.Value), len(filter)))
	for _, sample := range msg.Parameters.Value {
		if filter[sample.BlockName] {
			filtered = append(filtered, sample)
		}
	}

	if len(filtered) == 0 {
		return nil
	}

	result := *msg
	params := msg.Parameters
	params.Value = filtered
	result.Parameters = params
	return &result
}

// ResetAndClear drops all per-connection filters, resets the master list to
// empty, and immediately sends {"value":[]} to every telemetry core address.
func (m *MeterFilterManager) ResetAndClear(deviceAddressArray []string) {
	m.mu.Lock()
	m.connFilters = make(map[*websocket.Conn]map[string]bool)
	m.masterList = make(map[string]bool)
	packetID := m.packetID.Add(1)
	m.mu.Unlock()

	m.debounceMu.Lock()
	m.debouncePending = false
	if m.debounceTimer != nil {
		m.debounceTimer.Stop()
		m.debounceTimer = nil
	}
	m.pendingIDs = nil
	m.pendingAddrs = nil
	m.debounceMu.Unlock()

	m.sendFilterRequest(nil, packetID, deviceAddressArray)
	logging.GetLogger().Debug("MeterFilterManager: reset all filters and sent empty filter to telemetry cores")
}

func (m *MeterFilterManager) recomputeAndSend(deviceAddressArray []string) {
	newMaster := make(map[string]bool)
	for _, filter := range m.connFilters {
		for id := range filter {
			newMaster[id] = true
		}
	}

	if len(newMaster) > 0 && mapsEqual(m.masterList, newMaster) {
		return
	}
	m.masterList = newMaster

	ids := make([]string, 0, len(newMaster))
	for id := range newMaster {
		ids = append(ids, id)
	}
	m.enqueueFilterUpdate(ids, deviceAddressArray)
}

func (m *MeterFilterManager) enqueueFilterUpdate(ids []string, addrs []string) {
	m.debounceMu.Lock()
	m.debouncePending = true
	m.pendingIDs = ids
	m.pendingAddrs = addrs
	if m.debounceTimer == nil {
		m.debounceTimer = time.AfterFunc(filterDebounceInterval, m.flushFilterUpdate)
	}
	m.debounceMu.Unlock()
}

func (m *MeterFilterManager) flushFilterUpdate() {
	m.debounceMu.Lock()
	pending := m.debouncePending
	m.debouncePending = false
	ids := m.pendingIDs
	addrs := m.pendingAddrs
	m.pendingIDs = nil
	m.pendingAddrs = nil
	m.debounceMu.Unlock()

	if !pending {
		m.debounceMu.Lock()
		m.debounceTimer = nil
		m.debounceMu.Unlock()
		return
	}

	packetID := m.packetID.Add(1)
	m.sendFilterRequest(ids, packetID, addrs)

	m.debounceMu.Lock()
	defer m.debounceMu.Unlock()
	if m.debouncePending {
		m.debounceTimer = time.AfterFunc(filterDebounceInterval, m.flushFilterUpdate)
		return
	}
	m.debounceTimer = nil
}

func mapsEqual(a, b map[string]bool) bool {
	if len(a) != len(b) {
		return false
	}
	for id := range a {
		if !b[id] {
			return false
		}
	}
	return true
}

func (m *MeterFilterManager) sendFilterRequest(ids []string, packetID uint64, deviceAddressArray []string) {
	logger := logging.GetLogger()

	if ids == nil {
		ids = []string{}
	}

	req := telemetryFilterRequest{
		MessageName: "update_filter_req",
		PacketID:    packetID,
		Parameters:  telemetryFilterParameters{Value: ids},
	}

	data, err := json.Marshal(req)
	if err != nil {
		logger.Error("MeterFilterManager: failed to marshal filter request: %v", err)
		return
	}

	for _, addr := range deviceAddressArray {
		if err := m.pool.send(addr, data); err != nil {
			logger.Error("MeterFilterManager: failed to send filter request to %s: %v", addr, err)
		}
	}
}
