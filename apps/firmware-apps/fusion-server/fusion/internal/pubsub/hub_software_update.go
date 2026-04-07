package pubsub

import (
	"bytes"
	"context"
	"encoding/binary"
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/api"
	"io"
	"net"
	"time"
)

// startSWUpdateProgressMonitoring begins monitoring the SWUpdate progress socket
func (h *Hub) startSWUpdateProgressMonitoring() {
	h.swUpdateMutex.Lock()
	defer h.swUpdateMutex.Unlock()

	if h.swUpdateActive {
		logging.GetLogger().Debug("SWUpdate progress monitoring already active")
		return
	}

	ctx, cancel := context.WithCancel(context.Background())
	h.swUpdateCancel = cancel
	h.swUpdateActive = true

	go h.monitorSWUpdateProgress(ctx)
}

// StopSWUpdateProgressMonitoring stops monitoring the SWUpdate progress socket
func (h *Hub) StopSWUpdateProgressMonitoring() {
	h.swUpdateMutex.Lock()
	defer h.swUpdateMutex.Unlock()

	if !h.swUpdateActive {
		return
	}

	if h.swUpdateCancel != nil {
		h.swUpdateCancel()
	}
	h.swUpdateActive = false
}

// monitorSWUpdateProgress runs in a goroutine to monitor the SWUpdate socket
func (h *Hub) monitorSWUpdateProgress(ctx context.Context) {
	logger := logging.GetLogger()
	logger.Info("[Hub] Starting SWUpdate progress monitoring")

	defer func() {
		h.swUpdateMutex.Lock()
		h.swUpdateActive = false
		h.swUpdateMutex.Unlock()
		logger.Info("[Hub] SWUpdate progress monitoring stopped")
	}()

	for {
		select {
		case <-ctx.Done():
			return
		default:
			if err := h.connectAndMonitorSocket(ctx); err != nil {
				logger.Error("SWUpdate progress monitoring error: %v", err)
				// Wait before retrying
				select {
				case <-ctx.Done():
					return
				case <-time.After(2 * time.Second):
					continue
				}
			}
		}
	}
}

// connectAndMonitorSocket connects to SWUpdate socket and processes messages
func (h *Hub) connectAndMonitorSocket(ctx context.Context) error {
	logger := logging.GetLogger()

	conn, err := net.Dial("unix", api.SWUpdateSocketPath)
	if err != nil {
		return fmt.Errorf("failed to connect to SWUpdate socket: %w", err)
	}
	defer conn.Close()

	// Read connection acknowledgment
	apiVer, err := h.readConnectAck(conn)
	if err != nil {
		return fmt.Errorf("connect ack error: %w", err)
	}

	msgSize := api.SWUpdateMsgSizeV200
	if apiVer >= api.SWUpdateProgressAPIV210 {
		msgSize = api.SWUpdateMsgSizeV210
	}

	logger.Info("Connected to SWUpdate progress socket (API 0x%08X, message size %d)", apiVer, msgSize)

	buf := make([]byte, msgSize)
	for {
		select {
		case <-ctx.Done():
			return nil
		default:
			// Set read timeout
			conn.SetReadDeadline(time.Now().Add(1 * time.Second))

			_, err := io.ReadFull(conn, buf)
			if err != nil {
				if netErr, ok := err.(net.Error); ok && netErr.Timeout() {
					continue // Continue on timeout to check context
				}
				return fmt.Errorf("read error: %w", err)
			}

			if err := h.processSWUpdateMessage(buf); err != nil {
				logger.Error("Error processing SWUpdate message: %v", err)
			}
		}
	}
}

// readConnectAck reads and validates the SWUpdate connection acknowledgment
func (h *Hub) readConnectAck(conn net.Conn) (uint32, error) {
	ack := make([]byte, api.SWUpdateConnectAckSize)
	if _, err := io.ReadFull(conn, ack); err != nil {
		return 0, fmt.Errorf("reading connect ack: %w", err)
	}

	apiVer := binary.LittleEndian.Uint32(ack[0:])
	magic := string(ack[4:7])

	if magic != api.SWUpdateExpectedAckMagic {
		return 0, fmt.Errorf("unexpected ack magic %q (expected %q)", magic, api.SWUpdateExpectedAckMagic)
	}

	return apiVer, nil
}

// processSWUpdateMessage parses a progress message and broadcasts it
func (h *Hub) processSWUpdateMessage(buf []byte) error {
	progress, err := h.parseProgressMessage(buf)
	if err != nil {
		return fmt.Errorf("failed to parse progress message: %w", err)
	}

	if h.transport == nil || h.transport.LocalNode() == nil {
		return fmt.Errorf("transport not configured")
	}

	progress.NodeName = h.transport.LocalNode().Name
	progress.Timestamp = time.Now().UTC()

	// Create and broadcast progress message
	message := api.NewNotifyMessage(api.NotifyOpSoftwareUpdateProgress, progress.NodeName, func(msg *api.NotifyMessage) {
		msg.SoftwareUpdateProgress = progress
	})

	// Broadcast to cluster nodes
	if err := h.BroadcastToNodes(message); err != nil {
		return err
	}

	// Stop monitoring once a terminal state is reached so the goroutine
	// does not keep retrying/logging after the update completes.
	if isSWUpdateTerminalStatus(progress.Status) {
		logging.GetLogger().Info("[Hub] SWUpdate reached terminal status %s; stopping progress monitoring", progress.Status)
		h.StopSWUpdateProgressMonitoring()
	}

	return nil
}

// isSWUpdateTerminalStatus reports whether the given status marks the end of an update.
// SUCCESS is intentionally not terminal here so that monitoring continues until
// swupdate emits DONE (COMPLETED), giving clients visibility of the full sequence.
// Monitoring stops on DONE (normal completion) or FAILURE (error path).
func isSWUpdateTerminalStatus(s api.SWUpdateStatus) bool {
	switch s {
	case api.SWUpdateStatusDone, api.SWUpdateStatusFailure:
		return true
	}
	return false
}

// parseProgressMessage parses raw SWUpdate progress data
func (h *Hub) parseProgressMessage(buf []byte) (*api.SoftwareUpdateProgress, error) {
	le := binary.LittleEndian

	infoLen := le.Uint32(buf[api.SWUpdateOffInfoLen:])
	if infoLen >= 2048 {
		infoLen = 2047
	}

	progress := &api.SoftwareUpdateProgress{
		APIVersion: le.Uint32(buf[api.SWUpdateOffAPIVersion:]),
		Status:     api.SWUpdateStatus(le.Uint32(buf[api.SWUpdateOffStatus:])),
		DwlPercent: le.Uint32(buf[api.SWUpdateOffDwlPercent:]),
		DwlBytes:   le.Uint64(buf[api.SWUpdateOffDwlBytes:]),
		NSteps:     le.Uint32(buf[api.SWUpdateOffNSteps:]),
		CurStep:    le.Uint32(buf[api.SWUpdateOffCurStep:]),
		CurPercent: le.Uint32(buf[api.SWUpdateOffCurPercent:]),
		CurImage:   h.cstring(buf[api.SWUpdateOffCurImage : api.SWUpdateOffCurImage+256]),
		HndName:    h.cstring(buf[api.SWUpdateOffHndName : api.SWUpdateOffHndName+64]),
		Source:     int32(le.Uint32(buf[api.SWUpdateOffSource:])),
	}

	if infoLen > 0 {
		progress.Info = h.cstring(buf[api.SWUpdateOffInfo : api.SWUpdateOffInfo+int(infoLen)])
	}

	if len(buf) >= api.SWUpdateMsgSizeV210 {
		// Read as little-endian uint64, format as 16-char lowercase hex to match SWUpdate convention
		// (avoids JSON float64 precision loss and byte-order ambiguity)
		if len(buf[api.SWUpdateOffSerialNumber:]) >= 8 {
			serialVal := le.Uint64(buf[api.SWUpdateOffSerialNumber : api.SWUpdateOffSerialNumber+8])
			progress.SerialNumber = fmt.Sprintf("%016x", serialVal)
		}
	}

	return progress, nil
}

// cstring converts null-terminated C byte slice to Go string
func (h *Hub) cstring(b []byte) string {
	if i := bytes.IndexByte(b, 0); i >= 0 {
		return string(b[:i])
	}
	return string(b)
}

// updateSWProgress stores the latest progress for a node.
// WebSocket delivery happens via BroadcastToObservers in BroadcastToNodes, which
// carries the real per-node gossip message directly to the VIP node's WebSocket clients.
func (h *Hub) updateSWProgress(progress *api.SoftwareUpdateProgress) {
	h.swUpdateMutex.Lock()
	h.swUpdateProgress[progress.NodeName] = progress
	h.swUpdateMutex.Unlock()
}

// getAggregatedProgress returns aggregated progress from all nodes
func (h *Hub) getAggregatedProgress() map[string]*api.SoftwareUpdateProgress {
	h.swUpdateMutex.RLock()
	defer h.swUpdateMutex.RUnlock()

	result := make(map[string]*api.SoftwareUpdateProgress)
	for nodeName, progress := range h.swUpdateProgress {
		result[nodeName] = progress
	}

	return result
}

// GetAggregatedSWProgress returns current aggregated progress from all nodes (for WebSocket handlers)
func (h *Hub) GetAggregatedSWProgress() map[string]*api.SoftwareUpdateProgress {
	return h.getAggregatedProgress()
}

// IsSWProgressActive returns whether SWUpdate progress monitoring is currently active
func (h *Hub) IsSWProgressActive() bool {
	h.swUpdateMutex.RLock()
	defer h.swUpdateMutex.RUnlock()
	return h.swUpdateActive
}

// GetSingleNodeProgress returns formatted progress for a single node
func (h *Hub) GetSingleNodeProgress(nodeName string) *api.SoftwareUpdateProgressResponse {
	h.swUpdateMutex.RLock()
	progress := h.swUpdateProgress[nodeName]
	h.swUpdateMutex.RUnlock()

	if progress == nil {
		return nil
	}

	resp := api.SoftwareUpdateProgressResponse{
		UpdateState:  progress.Status.String(),
		Step:         fmt.Sprintf("%d/%d", progress.CurStep, progress.NSteps),
		CurrentTask:  progress.CurImage,
		Progress:     fmt.Sprintf("%d", progress.CurPercent),
		Node:         progress.NodeName,
		Handler:      progress.HndName,
		Timestamp:    progress.Timestamp.Format(time.RFC3339),
		SerialNumber: progress.SerialNumber,
	}
	return &resp
}
