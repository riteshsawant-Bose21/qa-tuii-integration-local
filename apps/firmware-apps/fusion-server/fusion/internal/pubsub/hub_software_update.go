package pubsub

import (
	"bytes"
	"context"
	"encoding/binary"
	"errors"
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/api"
	"io"
	"net"
	"os"
	"os/exec"
	"time"
)

// errSWUpdateGracefulStop is returned by connectAndMonitorSocket when the socket closes after a SUCCESS event.
var errSWUpdateGracefulStop = errors.New("swupdate socket closed after SUCCESS")

// StartSWUpdateProgressMonitoring begins monitoring the SWUpdate progress socket.
func (h *Hub) StartSWUpdateProgressMonitoring() {
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
				if errors.Is(err, os.ErrNotExist) {
					logger.Debug("[Hub] SWUpdate socket not yet available, retrying in 2s")
				} else if errors.Is(err, errSWUpdateGracefulStop) {
					logger.Info("[Hub] SWUpdate socket closed after SUCCESS (device rebooting), stopping monitor")
					return
				} else {
					logger.Error("SWUpdate progress monitoring error: %v", err)
				}
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

	// seenSuccess is set when SUCCESS is received.
	// If the socket closes after this without DONE, we assume it's a graceful shutdown due to device reboot and stop monitoring.
	seenSuccess := false

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
				if seenSuccess {
					// Socket closed after SUCCESS — device is about to reboot.
					// DONE may not have been emitted; stop gracefully.
					return errSWUpdateGracefulStop
				}
				return fmt.Errorf("read error: %w", err)
			}

			progress, processErr := h.processAndReturnProgress(buf)
			if processErr != nil {
				logger.Error("Error processing SWUpdate message: %v", processErr)
				continue
			}
			if progress != nil && progress.Status == api.SWUpdateStatusSuccess {
				seenSuccess = true
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

// processSWUpdateMessage parses a progress message, gossips it, and returns the
// parsed progress so callers can inspect status (e.g. to track SUCCESS).
// It calls StopSWUpdateProgressMonitoring on DONE or FAILURE.
func (h *Hub) processAndReturnProgress(buf []byte) (*api.SoftwareUpdateProgress, error) {
	return h.processSWUpdateMessageInternal(buf)
}

func (h *Hub) processSWUpdateMessageInternal(buf []byte) (*api.SoftwareUpdateProgress, error) {
	progress, err := h.parseProgressMessage(buf)
	if err != nil {
		return nil, fmt.Errorf("failed to parse progress message: %w", err)
	}

	if h.transport == nil || h.transport.LocalNode() == nil {
		return nil, fmt.Errorf("transport not configured")
	}

	progress.NodeName = h.transport.LocalNode().Name
	progress.Timestamp = time.Now().UTC()

	// Create and broadcast progress message
	message := api.NewNotifyMessage(api.NotifyOpSoftwareUpdateProgress, progress.NodeName, func(msg *api.NotifyMessage) {
		msg.SoftwareUpdateProgress = progress
	})

	// Broadcast to cluster nodes
	if err := h.BroadcastToNodes(message); err != nil {
		return progress, err
	}

	// Stop monitoring only on DONE (COMPLETED) or FAILURE.
	if isSWUpdateTerminalStatus(progress.Status) {
		logging.GetLogger().Info("[Hub] SWUpdate reached terminal status %s; stopping progress monitoring", progress.Status)
		h.StopSWUpdateProgressMonitoring()
	}

	return progress, nil
}

// isSWUpdateTerminalStatus returns true if the status is DONE or FAILURE, indicating monitoring should stop (not on SUCCESS).
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

// startFollowerOrchestration orchestrates SWUpdate: resets state, gossips start_update to followers, waits for all to finish, then updates primary.
func (h *Hub) startFollowerOrchestration() {
	logger := logging.GetLogger()
	// Ensure any previous SWUpdate monitoring is stopped before starting a new orchestration.
	h.StopSWUpdateProgressMonitoring()
	// Clear progress map to avoid stale entries affecting orchestration checks.
	h.resetSWUpdateProgress()
	logger.Info("[SWUpdate] Primary orchestration started — waiting for all followers to complete before self-update")
	go h.waitForFollowersThenUpdateSelf()
}

// resetSWUpdateProgress clears per-node progress accumulated from previous runs.
func (h *Hub) resetSWUpdateProgress() {
	h.swUpdateMutex.Lock()
	h.swUpdateProgress = make(map[string]*api.SoftwareUpdateProgress)
	h.swUpdateMutex.Unlock()
}

// waitForFollowersThenUpdateSelf waits for all followers to complete SWUpdate before starting the primary's self-update.
func (h *Hub) waitForFollowersThenUpdateSelf() {
	logger := logging.GetLogger()

	followers := h.getFollowerNames()
	if len(followers) == 0 {
		logger.Info("[SWUpdate] No followers in cluster — starting primary self-update immediately")
		h.startSelfUpdate()
		return
	}

	logger.Info("[SWUpdate] Waiting for %d follower(s) to complete update before starting primary: %v",
		len(followers), followers)

	timeout := time.NewTimer(30 * time.Minute)
	defer timeout.Stop()
	tick := time.NewTicker(5 * time.Second)
	defer tick.Stop()

	for {
		select {
		case <-timeout.C:
			logger.Error("[SWUpdate] Timed out waiting for followers — aborting primary self-update")
			return
		case <-tick.C:
			if h.anyFollowerFailed(followers) {
				logger.Error("[SWUpdate] A follower reported FAILURE — aborting primary self-update")
				return
			}
			if h.allFollowersDone(followers) {
				logger.Info("[SWUpdate] All followers reached DONE — starting primary self-update")
				h.startSelfUpdate()
				return
			}
			logger.Info("[SWUpdate] Still waiting for followers (pending: %v)", h.pendingFollowers(followers))
		}
	}
}

// getFollowerNames returns names of all cluster members except the local node.
func (h *Hub) getFollowerNames() []string {
	if h.transport == nil || h.transport.LocalNode() == nil {
		return nil
	}
	localName := h.transport.LocalNode().Name
	var followers []string
	for _, m := range h.transport.MemberListMembers() {
		if m.Name != localName {
			followers = append(followers, m.Name)
		}
	}
	return followers
}

// isFollowerUpdateComplete returns true if the follower has STATUS SUCCESS/DONE or is no longer in the memberlist (rebooted after update).
func (h *Hub) isFollowerUpdateComplete(name string) bool {
	// Check gossip-reported status first
	if p, ok := h.swUpdateProgress[name]; ok {
		if p.Status == api.SWUpdateStatusSuccess || p.Status == api.SWUpdateStatusDone {
			return true
		}
	}
	// Node left the memberlist → it rebooted after a successful update
	if h.transport != nil {
		for _, m := range h.transport.MemberListMembers() {
			if m.Name == name {
				return false
			}
		}
		return true
	}
	return false
}

// allFollowersDone reports whether every follower has completed (SUCCESS/DONE or left cluster).
func (h *Hub) allFollowersDone(followers []string) bool {
	h.swUpdateMutex.RLock()
	defer h.swUpdateMutex.RUnlock()
	for _, name := range followers {
		if !h.isFollowerUpdateComplete(name) {
			return false
		}
	}
	return true
}

// anyFollowerFailed returns true if any follower has SWUpdateStatusFailure; node disappearance is not treated as failure.
func (h *Hub) anyFollowerFailed(followers []string) bool {
	h.swUpdateMutex.RLock()
	defer h.swUpdateMutex.RUnlock()
	for _, name := range followers {
		if p, ok := h.swUpdateProgress[name]; ok && p.Status == api.SWUpdateStatusFailure {
			return true
		}
	}
	return false
}

// pendingFollowers returns names of followers not yet considered complete.
func (h *Hub) pendingFollowers(followers []string) []string {
	h.swUpdateMutex.RLock()
	defer h.swUpdateMutex.RUnlock()
	var pending []string
	for _, name := range followers {
		if !h.isFollowerUpdateComplete(name) {
			pending = append(pending, name)
		}
	}
	return pending
}

// startSelfUpdate triggers swupdate-ota-install.service on the primary and
// starts monitoring the local /tmp/swupdateprog progress socket.
func (h *Hub) startSelfUpdate() {
	logger := logging.GetLogger()

	// Clear any previously-failed state so systemctl start doesn't refuse to run.
	if out, err := exec.Command("systemctl", "reset-failed", "swupdate-ota-install.service").CombinedOutput(); err != nil {
		logger.Debug("[SWUpdate] reset-failed on primary (ignored): %v — %s", err, string(out))
	}

	cmd := exec.Command("systemctl", "start", "--no-block", "swupdate-ota-install.service")
	out, err := cmd.CombinedOutput()
	if err != nil {
		logger.Error("[SWUpdate] Failed to start swupdate-ota-install.service on primary: %v — %s", err, string(out))
		h.GossipSWUpdateFailure(h.transport.LocalNode().Name,
			fmt.Sprintf("failed to start swupdate-ota-install.service: %v — %s", err, string(out)))
		return
	}
	logger.Info("[SWUpdate] Queued swupdate-ota-install.service on primary")
	h.StartSWUpdateProgressMonitoring()
}

// GossipSWUpdateFailure broadcasts a FAILURE progress message for a node when swupdate cannot be started, so orchestration and WebSocket clients are notified.
func (h *Hub) GossipSWUpdateFailure(nodeName, reason string) {
	logger := logging.GetLogger()
	logger.Error("[SWUpdate] Gossiping FAILURE for node %s: %s", nodeName, reason)

	progress := &api.SoftwareUpdateProgress{
		NodeName:  nodeName,
		Status:    api.SWUpdateStatusFailure,
		Info:      reason,
		Timestamp: time.Now().UTC(),
	}

	msg := api.NewNotifyMessage(api.NotifyOpSoftwareUpdateProgress, nodeName, func(m *api.NotifyMessage) {
		m.SoftwareUpdateProgress = progress
	})

	if err := h.BroadcastToNodes(msg); err != nil {
		logger.Error("[SWUpdate] Failed to gossip FAILURE for node %s: %v", nodeName, err)
	}
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
