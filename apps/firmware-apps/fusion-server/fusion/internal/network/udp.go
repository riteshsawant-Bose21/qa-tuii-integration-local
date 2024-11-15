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

// Message represents the incoming message structure
type Message struct {
	Action string          `json:"action"`
	Key    string          `json:"key,omitempty"`
	Value  interface{}     `json:"value,omitempty"`
	Data   json.RawMessage `json:"data,omitempty"`
}

// Response represents the server response structure
type Response struct {
	Status  string      `json:"status"`
	Message string      `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
}

type Broadcaster interface {
	BroadcastUpdate(update api.ConfigUpdate) error
}

var _ broadcast.Broadcaster = (*UDPServer)(nil) // This will fail if interface doesn't match

// UDPServer handles UDP communication
type UDPServer struct {
	addr         string
	conn         *net.UDPConn
	stateManager *config.StateManager
	stopChan     chan struct{}
	wg           sync.WaitGroup
	clients      map[string]*net.UDPAddr
	clientsMux   sync.RWMutex
}

func NewUDPServer(addr string, stateManager *config.StateManager) (*UDPServer, error) {
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
	}, nil
}

// Start begins listening for UDP messages
func (s *UDPServer) Start() {
	s.wg.Add(1)
	go s.listen()
}

// Stop halts the UDP server
func (s *UDPServer) Stop() {
	close(s.stopChan)
	s.conn.Close()
	s.wg.Wait()

	// Clear clients
	s.clientsMux.Lock()
	s.clients = make(map[string]*net.UDPAddr)
	s.clientsMux.Unlock()
}

// Listen method update to handle client disconnections
func (s *UDPServer) listen() {
	defer s.wg.Done()
	buffer := make([]byte, 65535)

	for {
		select {
		case <-s.stopChan:
			return
		default:
			// Set read deadline to handle potential blocking
			s.conn.SetReadDeadline(time.Now().Add(1 * time.Second))
			n, addr, err := s.conn.ReadFromUDP(buffer)

			if err != nil {
				if netErr, ok := err.(net.Error); ok && netErr.Timeout() {
					// This is just a timeout, continue listening
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
	if _, exists := s.clients[addr]; exists {
		delete(s.clients, addr)
	}
	s.clientsMux.Unlock()
}

// Broadcaster interface
func (s *UDPServer) BroadcastUpdate(update api.ConfigUpdate) error {
	return s.SendUpdate(s.addr, update)
}

// Close method for Broadcaster interface
func (s *UDPServer) Close() error {
	s.Stop()
	return nil
}

func (s *UDPServer) handleMessage(data []byte, addr *net.UDPAddr) {

	// Store client address when we receive a message
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
		if msg.Key == "" {
			log.Printf("[ERROR] Set action missing key")
			s.sendResponse(addr, Response{
				Status:  "error",
				Message: "Key is required for set action",
			})
			return
		}

		update := api.ConfigUpdate{
			Key:   msg.Key,
			Value: msg.Value,
		}

		if err := s.stateManager.ApplyUpdate(update); err != nil {
			log.Printf("[ERROR] Failed to apply update: %v", err)
			s.sendResponse(addr, Response{
				Status:  "error",
				Message: fmt.Sprintf("Failed to set value: %v", err),
			})
			return
		}

		s.sendResponse(addr, Response{
			Status:  "success",
			Message: fmt.Sprintf("Successfully set %s", msg.Key),
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

// SendUpdate sends an update via UDP
func (s *UDPServer) SendUpdate(listenAddr string, update api.ConfigUpdate) error {

	msg := Message{
		Action: "update",
		Key:    update.Key,
		Value:  update.Value,
	}

	data, err := json.Marshal(msg)
	if err != nil {
		return fmt.Errorf("failed to marshal message: %v", err)
	}

	// Send to all known clients
	s.clientsMux.RLock()
	deadClients := make([]string, 0)

	// Send to all registered clients
	for addrStr, clientAddr := range s.clients {
		log.Printf("Sending UDP update to %s: %s", addrStr, string(data))
		_, err = s.conn.WriteToUDP(data, clientAddr)
		if err != nil {
			log.Printf("Failed to send update to %s: %v", addrStr, err)
			deadClients = append(deadClients, addrStr)
		}
	}
	s.clientsMux.RUnlock()

	// Clean up dead clients outside the read lock
	for _, addr := range deadClients {
		s.removeClient(addr)
	}

	return nil
}
