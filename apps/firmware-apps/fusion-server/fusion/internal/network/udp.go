package network

import (
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/server"
	"fusion/internal/server/handler"
	"net"
	"sync"
	"time"
)

type UDPServer struct {
	addr       string
	conn       *net.UDPConn
	handler    *handler.Handler
	stopChan   chan struct{}
	wg         sync.WaitGroup
	clients    map[string]*net.UDPAddr
	clientsMux sync.RWMutex
}

func NewUDPServer(addr string, handler *handler.Handler) (*UDPServer, error) {
	udpAddr, err := net.ResolveUDPAddr("udp", addr)
	if err != nil {
		return nil, fmt.Errorf("failed to resolve address: %v", err)
	}

	conn, err := net.ListenUDP("udp", udpAddr)
	if err != nil {
		return nil, fmt.Errorf("failed to listen: %v", err)
	}

	logging.GetLogger().Info("UDP server listening on %s", addr)

	return &UDPServer{
		addr:     addr,
		conn:     conn,
		handler:  handler,
		stopChan: make(chan struct{}),
		clients:  make(map[string]*net.UDPAddr),
	}, nil
}

func (s *UDPServer) Start() {
	s.wg.Add(1)
	go s.listen()
}

func (s *UDPServer) Stop() {
	close(s.stopChan)
	s.conn.Close()
	s.wg.Wait()

	s.clientsMux.Lock()
	s.clients = make(map[string]*net.UDPAddr)
	s.clientsMux.Unlock()
}

func (s *UDPServer) listen() {
	defer s.wg.Done()
	buffer := make([]byte, 65535)

	for {
		select {
		case <-s.stopChan:
			return
		default:
			s.conn.SetReadDeadline(time.Now().Add(1 * time.Second))
			n, addr, err := s.conn.ReadFromUDP(buffer)

			if err != nil {
				if netErr, ok := err.(net.Error); ok && netErr.Timeout() {
					continue
				}

				select {
				case <-s.stopChan:
					return
				default:
					logging.GetLogger().Error("Error reading UDP from %v: %v", addr, err)
					if addr != nil {
						s.removeClient(addr.String())
					}
					continue
				}
			}

			go s.handleMessage(buffer[:n], addr)
		}
	}
}

func (s *UDPServer) removeClient(addr string) {
	s.clientsMux.Lock()
	delete(s.clients, addr)
	s.clientsMux.Unlock()
}

func (s *UDPServer) handleMessage(data []byte, addr *net.UDPAddr) {
	s.clientsMux.Lock()
	s.clients[addr.String()] = addr
	s.clientsMux.Unlock()

	response, err := s.handler.HandleUDPMessage(data)
	if err != nil {
		s.sendResponse(addr, server.UDPResponse{
			Status:  "error",
			Message: err.Error(),
		})
		return
	}

	s.sendResponse(addr, response)
}

func (s *UDPServer) sendResponse(addr *net.UDPAddr, response any) {
	data, err := json.Marshal(response)
	if err != nil {
		logging.GetLogger().Error("Error marshaling response: %v", err)
		return
	}

	if _, err := s.conn.WriteToUDP(data, addr); err != nil {
		logging.GetLogger().Error("Error sending response: %v", err)
		s.removeClient(addr.String())
	}
}

func (s *UDPServer) BroadcastUpdate(message *api.NotifyMessage) error {

	if message.Operation == api.NotifyOpConfigUpdate {
		data, err := json.Marshal(message.ConfigUpdate.Data)
		if err != nil {
			return fmt.Errorf("failed to marshal update: %v", err)
		}

		s.clientsMux.RLock()
		deadClients := make([]string, 0)

		for addrStr, clientAddr := range s.clients {
			logging.GetLogger().Debug("Sending update to %s: %s", addrStr, string(data))
			_, err = s.conn.WriteToUDP(data, clientAddr)
			if err != nil {
				logging.GetLogger().Error("Failed to send update to %s: %v", addrStr, err)
				deadClients = append(deadClients, addrStr)
			}
		}
		s.clientsMux.RUnlock()

		for _, addr := range deadClients {
			s.removeClient(addr)
		}
	}

	return nil
}

func (s *UDPServer) Close() error {
	s.Stop()
	return nil
}
