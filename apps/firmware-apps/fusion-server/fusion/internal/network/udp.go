package network

import (
	"encoding/json"
	"fmt"
	"fusion/internal/api"
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

// UDPServer handles UDP communication
type UDPServer struct {
	addr         string
	conn         *net.UDPConn
	stateManager *config.StateManager
	stopChan     chan struct{}
	wg           sync.WaitGroup
}

// NewUDPServer creates a new UDP server
func NewUDPServer(addr string, stateManager *config.StateManager) (*UDPServer, error) {
	log.Printf("Starting UDP server on %s", addr)
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
}

func (s *UDPServer) listen() {
	defer s.wg.Done()
	buffer := make([]byte, 65535)

	log.Printf("UDP server started listening for messages")
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
					log.Printf("Error reading UDP: %v", err)
					continue
				}
			}

			log.Printf("Received %d bytes from %s", n, addr.String())
			log.Printf("Message content: %s", string(buffer[:n]))

			go s.handleMessage(buffer[:n], addr)
		}
	}
}

func (s *UDPServer) handleMessage(data []byte, addr *net.UDPAddr) {
	var msg Message
	if err := json.Unmarshal(data, &msg); err != nil {
		log.Printf("Failed to unmarshal message: %v", err)
		s.sendResponse(addr, Response{
			Status:  "error",
			Message: fmt.Sprintf("Invalid JSON: %v", err),
		})
		return
	}

	log.Printf("Processing message with action: %s", msg.Action)

	switch msg.Action {
	case "get":
		config := s.stateManager.GetFullState()
		log.Printf("Sending config: %+v", config)
		s.sendResponse(addr, Response{
			Status: "success",
			Data:   config,
		})

	case "set":
		if msg.Key == "" {
			log.Printf("Set action missing key")
			s.sendResponse(addr, Response{
				Status:  "error",
				Message: "Key is required for set action",
			})
			return
		}

		log.Printf("Setting key '%s' to value: %v", msg.Key, msg.Value)
		update := api.ConfigUpdate{
			Key:   msg.Key,
			Value: msg.Value,
		}

		if err := s.stateManager.ApplyUpdate(update); err != nil {
			log.Printf("Failed to apply update: %v", err)
			s.sendResponse(addr, Response{
				Status:  "error",
				Message: fmt.Sprintf("Failed to set value: %v", err),
			})
			return
		}

		log.Printf("Successfully set key '%s'", msg.Key)
		s.sendResponse(addr, Response{
			Status:  "success",
			Message: fmt.Sprintf("Successfully set %s", msg.Key),
		})

	case "update":
		var update api.ConfigUpdate
		if err := json.Unmarshal(msg.Data, &update); err != nil {
			log.Printf("Failed to unmarshal update data: %v", err)
			s.sendResponse(addr, Response{
				Status:  "error",
				Message: fmt.Sprintf("Invalid update data: %v", err),
			})
			return
		}

		log.Printf("Applying update: %+v", update)
		if err := s.stateManager.ApplyUpdate(update); err != nil {
			log.Printf("Failed to apply update: %v", err)
			s.sendResponse(addr, Response{
				Status:  "error",
				Message: fmt.Sprintf("Failed to apply update: %v", err),
			})
			return
		}

		log.Printf("Successfully applied update")
		s.sendResponse(addr, Response{
			Status:  "success",
			Message: "Update applied successfully",
		})

	default:
		log.Printf("Unknown action received: %s", msg.Action)
		s.sendResponse(addr, Response{
			Status:  "error",
			Message: fmt.Sprintf("Unknown action: %s", msg.Action),
		})
	}
}

func (s *UDPServer) sendResponse(addr *net.UDPAddr, response Response) {
	data, err := json.Marshal(response)
	if err != nil {
		log.Printf("Error marshaling response: %v", err)
		return
	}

	log.Printf("Sending response to %s: %s", addr.String(), string(data))
	if _, err := s.conn.WriteToUDP(data, addr); err != nil {
		log.Printf("Error sending response: %v", err)
	}
}

// SendUpdate sends an update via UDP
func (s *UDPServer) SendUpdate(addr string, update api.ConfigUpdate) error {
	udpAddr, err := net.ResolveUDPAddr("udp", addr)
	if err != nil {
		return fmt.Errorf("failed to resolve address: %v", err)
	}

	// First marshal the update to get the raw JSON
	updateJSON, err := json.Marshal(update)
	if err != nil {
		return fmt.Errorf("failed to marshal update: %v", err)
	}

	msg := Message{
		Action: "update",
		Data:   json.RawMessage(updateJSON),
	}

	data, err := json.Marshal(msg)
	if err != nil {
		return fmt.Errorf("failed to marshal message: %v", err)
	}

	log.Printf("Sending update to %s: %s", addr, string(data))
	_, err = s.conn.WriteToUDP(data, udpAddr)
	if err != nil {
		return fmt.Errorf("failed to send update: %v", err)
	}

	return nil
}
