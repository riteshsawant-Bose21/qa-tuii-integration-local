package network

import (
	"encoding/json"
	"fmt"
	"log"
	"net"
	"sync"

	"fusion/internal/api"
	"fusion/internal/config"
)

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
	udpAddr, err := net.ResolveUDPAddr("udp", addr)
	if err != nil {
		return nil, fmt.Errorf("failed to resolve address: %v", err)
	}

	conn, err := net.ListenUDP("udp", udpAddr)
	if err != nil {
		return nil, fmt.Errorf("failed to listen: %v", err)
	}

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
	for {
		select {
		case <-s.stopChan:
			return
		default:
			n, addr, err := s.conn.ReadFromUDP(buffer)
			if err != nil {
				select {
				case <-s.stopChan:
					return
				default:
					log.Printf("Error reading UDP: %v", err)
					continue
				}
			}

			go s.handleMessage(buffer[:n], addr)
		}
	}
}

func (s *UDPServer) handleMessage(data []byte, addr *net.UDPAddr) {
	var update api.ConfigUpdate
	if err := json.Unmarshal(data, &update); err != nil {
		log.Printf("Error unmarshaling UDP message: %v", err)
		return
	}

	if err := s.stateManager.ApplyUpdate(update); err != nil {
		log.Printf("Error applying UDP update: %v", err)
		return
	}

	// Send acknowledgment
	ack := []byte("ACK")
	if _, err := s.conn.WriteToUDP(ack, addr); err != nil {
		log.Printf("Error sending UDP acknowledgment: %v", err)
	}
}

// SendUpdate sends an update via UDP
func (s *UDPServer) SendUpdate(addr string, update api.ConfigUpdate) error {
	udpAddr, err := net.ResolveUDPAddr("udp", addr)
	if err != nil {
		return fmt.Errorf("failed to resolve address: %v", err)
	}

	data, err := json.Marshal(update)
	if err != nil {
		return fmt.Errorf("failed to marshal update: %v", err)
	}

	_, err = s.conn.WriteToUDP(data, udpAddr)
	if err != nil {
		return fmt.Errorf("failed to send update: %v", err)
	}

	return nil
}
