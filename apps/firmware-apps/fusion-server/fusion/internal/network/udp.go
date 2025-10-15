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

type UDPServer struct {
	*Listener
	clients    map[string]*net.UDPAddr
	clientsMux sync.RWMutex
	handler    *handler.Handler

	// Messages waiting for acknowledgement
	pending    map[string]chan struct{} // messageID -> notify channel
	pendingMux sync.Mutex
}

func NewUDPServer(addr string, handler *handler.Handler) (*UDPServer, error) {
	conn, err := ResolveListenUDP(addr)
	if err != nil {
		return nil, err
	}
	logging.GetLogger().Info("UDP listening on %s", addr)

	srv := &UDPServer{
		clients: make(map[string]*net.UDPAddr),
		handler: handler,
	}

	srv.Listener = NewListener(
		conn,
		defaultBufferSize,
		time.Second,
		srv.packetHandler,
	)

	srv.Start()
	return srv, nil
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

	var dead []string
	s.clientsMux.RLock()
	for k, addr := range s.clients {
		_, err := s.conn.WriteToUDP(data, addr)
		if err != nil {
			logger.Error("broadcast to %s failed: %v", k, err)
			dead = append(dead, k)
		}
	}
	s.clientsMux.RUnlock()

	for _, k := range dead {
		s.clientsMux.Lock()
		delete(s.clients, k)
		s.clientsMux.Unlock()
	}
	return nil
}

func (s *UDPServer) packetHandler(data []byte, addr *net.UDPAddr) {

	// Add caller to client map
	s.clientsMux.Lock()
	s.clients[addr.String()] = addr
	s.clientsMux.Unlock()

	// Handle acknowledgements
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

	// Handle normal messages
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
		logging.GetLogger().Error("write error: %v", err)
		s.clientsMux.Lock()
		delete(s.clients, addr.String())
		s.clientsMux.Unlock()
	}
}
