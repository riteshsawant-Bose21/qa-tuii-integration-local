package network

import (
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/broadcast"
	"fusion/internal/config"
	"log"
	"net"
	"sync"
	"time"
)

type Message struct {
	Action string          `json:"action"`
	Update json.RawMessage `json:"update,omitempty"`
	Data   json.RawMessage `json:"data,omitempty"`
}

type Response struct {
	Status  string      `json:"status"`
	Message string      `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
}

type Broadcaster interface {
	BroadcastUpdate(map[string]interface{}) error
}

var _ broadcast.Broadcaster = (*UDPServer)(nil)

type UDPServer struct {
	addr         string
	conn         *net.UDPConn
	stateManager *config.StateManager
	stopChan     chan struct{}
	wg           sync.WaitGroup
	clients      map[string]*net.UDPAddr
	clientsMux   sync.RWMutex
	verbose      bool
}

func NewUDPServer(addr string, stateManager *config.StateManager, verbose bool) (*UDPServer, error) {
	udpAddr, err := net.ResolveUDPAddr("udp", addr)
	if err != nil {
		return nil, fmt.Errorf("failed to resolve address: %v", err)
	}

	conn, err := net.ListenUDP("udp", udpAddr)
	if err != nil {
		return nil, fmt.Errorf("failed to listen: %v", err)
	}

	log.Printf("UDP server listening on %s", addr)
	return &UDPServer{
		addr:         addr,
		conn:         conn,
		stateManager: stateManager,
		stopChan:     make(chan struct{}),
		clients:      make(map[string]*net.UDPAddr),
		verbose:      verbose,
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
					log.Printf("[ERROR] Error reading UDP from %v: %v", addr, err)
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

func (s *UDPServer) BroadcastUpdate(update map[string]interface{}) error {
	return s.SendUpdate(s.addr, update)
}

func (s *UDPServer) Close() error {
	s.Stop()
	return nil
}

func (s *UDPServer) handleMessage(data []byte, addr *net.UDPAddr) {
	s.clientsMux.Lock()
	s.clients[addr.String()] = addr
	s.clientsMux.Unlock()

	var msg Message
	if err := json.Unmarshal(data, &msg); err != nil {
		log.Printf("[ERROR] Failed to unmarshal message: %v", err)
		s.sendResponse(addr, Response{
			Status:  "error",
			Message: fmt.Sprintf("Invalid JSON: %v", err),
		})
		return
	}

	switch msg.Action {
	case "get":
		config := s.stateManager.GetFullState()
		s.sendResponse(addr, Response{
			Status: "success",
			Data:   config,
		})

	case "set":
		var update map[string]interface{}
		if err := json.Unmarshal(msg.Update, &update); err != nil {
			s.sendResponse(addr, Response{
				Status:  "error",
				Message: fmt.Sprintf("Invalid update data: %v", err),
			})
			return
		}

		if len(update) != 1 {
			s.sendResponse(addr, Response{
				Status:  "error",
				Message: "Update must contain exactly one key-value pair",
			})
			return
		}

		// Get key for response message
		var key string
		for k := range update {
			key = k
			break
		}

		configUpdate := api.ConfigUpdate{
			Update: update,
		}

		if err := s.stateManager.ApplyUpdate(configUpdate); err != nil {
			log.Printf("[ERROR] Failed to apply update: %v", err)
			s.sendResponse(addr, Response{
				Status:  "error",
				Message: fmt.Sprintf("Failed to set value: %v", err),
			})
			return
		}

		s.sendResponse(addr, Response{
			Status:  "success",
			Message: fmt.Sprintf("Successfully set %s", key),
		})

	case "update":
		var update api.ConfigUpdate
		if err := json.Unmarshal(msg.Data, &update); err != nil {
			log.Printf("[ERROR] Failed to unmarshal update data: %v", err)
			s.sendResponse(addr, Response{
				Status:  "error",
				Message: fmt.Sprintf("Invalid update data: %v", err),
			})
			return
		}

		if err := s.stateManager.ApplyUpdate(update); err != nil {
			log.Printf("[ERROR] Failed to apply update: %v", err)
			s.sendResponse(addr, Response{
				Status:  "error",
				Message: fmt.Sprintf("Failed to apply update: %v", err),
			})
			return
		}

		s.sendResponse(addr, Response{
			Status:  "success",
			Message: "Update applied successfully",
		})

	default:
		log.Printf("[ERROR] Unknown action received: %s", msg.Action)
		s.sendResponse(addr, Response{
			Status:  "error",
			Message: fmt.Sprintf("Unknown action: %s", msg.Action),
		})
	}
}

func (s *UDPServer) sendResponse(addr *net.UDPAddr, response Response) {
	data, err := json.Marshal(response)
	if err != nil {
		log.Printf("[ERROR] Error marshaling response: %v", err)
		return
	}

	if _, err := s.conn.WriteToUDP(data, addr); err != nil {
		log.Printf("[ERROR] Error sending response: %v", err)
		s.removeClient(addr.String())
	}
}

func (s *UDPServer) SendUpdate(listenAddr string, update map[string]interface{}) error {
	msg := Message{
		Action: "update",
		Update: json.RawMessage([]byte{}),
	}

	// Marshal the update map into raw JSON
	updateBytes, err := json.Marshal(update)
	if err != nil {
		return fmt.Errorf("failed to marshal update: %v", err)
	}
	msg.Update = updateBytes

	data, err := json.Marshal(msg)
	if err != nil {
		return fmt.Errorf("failed to marshal message: %v", err)
	}

	s.clientsMux.RLock()
	deadClients := make([]string, 0)

	for addrStr, clientAddr := range s.clients {
		if s.verbose {
			log.Printf("[UDP] Sending update to %s: %s", addrStr, string(data))
		}
		_, err = s.conn.WriteToUDP(data, clientAddr)
		if err != nil {
			log.Printf("[ERROR] Failed to send update to %s: %v", addrStr, err)
			deadClients = append(deadClients, addrStr)
		}
	}
	s.clientsMux.RUnlock()

	for _, addr := range deadClients {
		s.removeClient(addr)
	}

	return nil
}
