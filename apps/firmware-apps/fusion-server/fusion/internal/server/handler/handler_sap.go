package handler

import (
	"encoding/binary"
	"fmt"
	"net"
	"regexp"
	"strings"
	"time"

	"fusion/internal/logging"

	sdp "github.com/pion/sdp/v3"
)

// VARTEC is a 6-bit bitfield in SAP (RFC 2974).
type VARTEC uint8

const (
	compressionMask VARTEC = 1 << 0 // C: Compression bit (bit 0)
	authMask        VARTEC = 1 << 1 // A: Authentication bit (bit 1)
	reservedMask    VARTEC = 1 << 2 // R: Reserved bit (bit 2)
	deleteMask      VARTEC = 1 << 4 // T (sometimes called D): Deletion bit (bit 4)
	versionMask     VARTEC = 0xE0   // V: Version bits (bits 5–7)

	minPacketLength = 8
	sessionInterval = 30 * time.Second
	sessionTimeout  = 10
	sessionsKey     = "sessions"
	smoothingFactor = 0.5
)

// SAPMessage represents a decoded SAP announcement.
type SAPMessage struct {
	VARTEC        VARTEC
	MsgIdHash     uint16
	Origin        uint32
	StringPayload string
}

// SAPSession holds session details for REST/memberlist.
type SAPSession struct {
	ID          string                  `json:"id"`
	OriginIP    string                  `json:"origin"`
	Timestamp   time.Time               `json:"timestamp"`
	Interval    time.Duration           `json:"-"`
	Description *sdp.SessionDescription `json:"description"`
	Deletion    bool                    `json:"-"`
	Version     int                     `json:"-"`
}

// HandleSAPMessage decodes a raw SAP packet, updates the session store, and parses SDP.
func (h *Handler) HandleSAPMessage(data []byte) error {
	if len(data) < minPacketLength {
		return fmt.Errorf("SAP message too short: %d bytes", len(data))
	}

	msg := &SAPMessage{
		VARTEC:        VARTEC(data[0]),
		MsgIdHash:     binary.BigEndian.Uint16(data[2:4]),
		Origin:        binary.BigEndian.Uint32(data[4:8]),
		StringPayload: string(data[8:]),
	}

	logger := logging.GetLogger()
	logger.Debug("Received SAP announcement %d from %08x", msg.MsgIdHash, msg.Origin)

	// Compute human-readable origin IP
	ipBytes := make([]byte, 4)
	binary.BigEndian.PutUint32(ipBytes, msg.Origin)
	originIP := net.IP(ipBytes).String()

	// Determine delete flag and version
	isDelete := msg.VARTEC&deleteMask != 0
	version := int((msg.VARTEC & versionMask) >> 5)

	sessionKey := fmt.Sprintf("%s:%d", originIP, msg.MsgIdHash)
	if isDelete {
		logger.Debug("Deleting network session %s.", sessionKey)
		delete(h.sessions, sessionKey)
		return nil
	}

	// New or updated session
	logger.Debug("Adding/updating network session %s.", sessionKey)
	session := &SAPSession{
		ID:        sessionKey,
		OriginIP:  originIP,
		Timestamp: time.Now(),
		Deletion:  false,
		Version:   version,
	}

	// Normalize SDP line endings: Pion requires CRLF per RFC 4566
	raw := msg.StringPayload

	// First line of the SDP payload is the MIME type
	// dropping everything before the first "v=" line
	pos := strings.Index(raw, "v=")
	if pos < 0 {
		logger.Warn("No v= line found in incoming SDP – full payload was: %q", raw)
		return nil
	}

	// Normalize SDP line endings: Pion requires CRLF per RFC 4566
	raw = raw[pos:]
	re := regexp.MustCompile(`\r\n|\r|\n`)
	raw = re.ReplaceAllString(raw, "\r\n")

	// Ensure trailing CRLF
	if !strings.HasSuffix(raw, "\r\n") {
		raw += "\r\n"
	}

	// Parse SDP into pion's SessionDescription
	var sessionDesc sdp.SessionDescription
	if err := sessionDesc.Unmarshal([]byte(raw)); err != nil {
		logger.Warn("Failed to parse SDP for session %s: %v", sessionKey, err)
	} else {
		session.Description = &sessionDesc
	}

	h.sessions[sessionKey] = session

	if h.StateManager.GetNode() == h.Memberlist.LocalNode().Name {
		// Update the configuration state only on the primary node.
		// All nodes are going to receive the SAP multicast messages.
		// We only need the primary to set the state. It will naturally
		// propogate across all nodes.
		state := h.StateManager.GetStateMap()
		state[sessionsKey] = h.sessions
		if err := h.handleConfigUpdate(state); err != nil {
			return fmt.Errorf("failed to handle update SAP session data: %w", err)
		}
	}

	return nil
}

// HandleListSessions returns the current session map.
func (h *Handler) HandleListSessions() map[string]*SAPSession {
	return h.sessions
}

// HandleGetSession returns the session based on session identifier.
func (h *Handler) HandleGetSession(id string) *SAPSession {
	return h.sessions[id]
}

// StartSAPSessionPruner runs a go routine to remove expires sessions.
func (h *Handler) StartSAPSessionPruner() {
	ticker := time.NewTicker(5 * time.Minute)
	go func() {
		for range ticker.C {
			h.pruneExpiredSAPSessions()
		}
	}()
}

// pruneExpiredSAPSessions removes sessions that have timed out.
func (h *Handler) pruneExpiredSAPSessions() {

	logger := logging.GetLogger()

	now := time.Now()
	changed := false

	for key, session := range h.sessions {
		interval := session.Interval
		if interval < time.Second {
			interval = sessionInterval
		}

		timeout := max(interval*sessionTimeout, time.Hour)

		if now.Sub(session.Timestamp) > timeout {
			logger.Info("Expiring stale SAP session %s after %v inactivity", key, now.Sub(session.Timestamp))
			delete(h.sessions, key)
			changed = true
		}
	}

	if changed && h.StateManager.GetNode() == h.Memberlist.LocalNode().Name {
		state := h.StateManager.GetStateMap()
		state[sessionsKey] = h.sessions
		if err := h.handleConfigUpdate(state); err != nil {
			logger.Error("Failed to update state after SAP cleanup: %v", err)
		}
	}
}
