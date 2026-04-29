package server

import (
	"net"
	"sync"
	"sync/atomic"
	"time"

	json "github.com/goccy/go-json"
	"github.com/gorilla/websocket"

	"fusion-services-core/logging"
	"fusion/internal/api"
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

// MeterFilterManager tracks a per-connection list of meter IDs and maintains a
// union master list. Whenever the master list changes it sends update_filter_req
// to the telemetry core via UDP so only the relevant meter IDs are forwarded.
//
// Concurrency: all public methods are safe to call from multiple goroutines.
type MeterFilterManager struct {
	mu          sync.RWMutex
	connFilters map[*websocket.Conn]map[string]bool // conn → set of requested IDs
	masterList  map[string]bool                     // union across all connections
	packetID    atomic.Uint64
}

// NewMeterFilterManager creates a manager that will send filter updates to
// the telemetry core on each cluster device via UDP.
func NewMeterFilterManager() *MeterFilterManager {
	return &MeterFilterManager{
		connFilters: make(map[*websocket.Conn]map[string]bool),
		masterList:  make(map[string]bool),
	}
}

// SetFilter replaces the meter ID filter for conn with ids and recomputes the
// master list. Passing an empty slice clears the connection's filter.
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

// RemoveFilter removes the filter for conn and recomputes the master list.
// If conn has no filter registered it still recomputes, because the telemetry
// core must be notified if the master list becomes empty (e.g. after a fusion
// server restart where masterList is {} but the telemetry core has stale state).
func (m *MeterFilterManager) RemoveFilter(conn *websocket.Conn, deviceAddressArray []string) {
	m.mu.Lock()
	defer m.mu.Unlock()

	_, existed := m.connFilters[conn]
	delete(m.connFilters, conn) // no-op if conn was not in the map

	// Only recompute if removing this connection could actually change what the
	// telemetry core needs to know: either the conn had a filter, or the current
	// master is non-empty and might now need to shrink.
	if existed || len(m.masterList) > 0 {
		m.recomputeAndSend(deviceAddressArray)
	}
}

// FilterMeterDataForConn returns a copy of msg with parameters.value filtered to
// only the samples whose block_name is in conn's registered filter.
// If the connection has no filter registered, nil is returned (no data until a filter is set).
// Returns nil if the filter is set but matches no samples.
func (m *MeterFilterManager) FilterMeterDataForConn(conn *websocket.Conn, msg *api.MeterDataMessage) *api.MeterDataMessage {
	m.mu.RLock()
	filter := m.connFilters[conn]
	m.mu.RUnlock()

	if filter == nil {
		return nil
	}

	filtered := make([]api.MeterDataSample, 0, min(len(msg.Parameters.Value), len(filter)))
	for _, sample := range msg.Parameters.Value {
		if filter[sample.BlockName] {
			filtered = append(filtered, sample)
		}
	}

	if len(filtered) == 0 {
		return nil
	}

	// Shallow-copy the message, replacing only the value slice.
	result := *msg
	params := msg.Parameters
	params.Value = filtered
	result.Parameters = params
	return &result
}

// ResetAndClear drops all per-connection filters, resets the master list to
// empty, and immediately sends {"value":[]} to every telemetry core address.
// Call this on VIP gain / fusion-server start to ensure the telemetry core
// has a clean slate before any WebSocket client sets a new filter.
func (m *MeterFilterManager) ResetAndClear(deviceAddressArray []string) {
	m.mu.Lock()
	m.connFilters = make(map[*websocket.Conn]map[string]bool)
	m.masterList = make(map[string]bool)
	packetID := m.packetID.Add(1)
	m.mu.Unlock()

	go m.sendFilterRequest(nil, packetID, deviceAddressArray)
	logging.GetLogger().Info("MeterFilterManager: reset all filters and sent empty filter to telemetry cores")
}

// recomputeAndSend rebuilds the master list and dispatches update_filter_req
// to the telemetry core asynchronously whenever the list changes.
// When the new master is empty we always send, even if the previous master was
// also empty — this clears stale state on the telemetry core after a restart
// or VIP failover.
// Must be called with m.mu held (write lock).
func (m *MeterFilterManager) recomputeAndSend(deviceAddressArray []string) {
	newMaster := make(map[string]bool)
	for _, filter := range m.connFilters {
		for id := range filter {
			newMaster[id] = true
		}
	}

	// Skip only when the non-empty master hasn't changed. When the master
	// is empty we always send so the telemetry core clears its filter.
	if len(newMaster) > 0 && mapsEqual(m.masterList, newMaster) {
		return
	}
	m.masterList = newMaster

	ids := make([]string, 0, len(newMaster))
	for id := range newMaster {
		ids = append(ids, id)
	}
	packetID := m.packetID.Add(1)
	go m.sendFilterRequest(ids, packetID, deviceAddressArray)
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

	// Ensure an empty (not nil) slice so the JSON encodes as [] not null.
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
		conn, err := net.Dial("udp", addr)
		if err != nil {
			logger.Error("MeterFilterManager: failed to connect to telemetry core at %s: %v", addr, err)
			continue
		}
		conn.SetWriteDeadline(time.Now().Add(1 * time.Second))
		if _, err := conn.Write(data); err != nil {
			logger.Error("MeterFilterManager: failed to send filter request to %s: %v", addr, err)
		}
		conn.Close()
	}

}
