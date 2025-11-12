package controllers

import (
	"bufio"
	"fusion/internal/logging"
	"net"
	"sync"
)

// WallControllerTCPServer handles TCP connections specifically for wall controllers
type WallControllerTCPServer struct {
	listener    net.Listener
	manager     *ControllerManager
	clients     map[string]net.Conn
	clientsLock sync.RWMutex
	addr        string
	running     bool
	runningLock sync.RWMutex
	stopChan    chan struct{}
	wg          sync.WaitGroup
}

// NewWallControllerTCPServer creates a new TCP server for wall controllers
func NewWallControllerTCPServer(addr string, manager *ControllerManager) *WallControllerTCPServer {
	return &WallControllerTCPServer{
		manager:  manager,
		clients:  make(map[string]net.Conn),
		addr:     addr,
		stopChan: make(chan struct{}),
	}
}

// Start begins listening for TCP connections
func (s *WallControllerTCPServer) Start() error {
	s.runningLock.Lock()
	defer s.runningLock.Unlock()

	if s.running {
		logger := logging.GetLogger()
		logger.Info("🔄 Wall Controller TCP server already running on %s", s.addr)
		return nil
	}

	listener, err := net.Listen("tcp", s.addr)
	if err != nil {
		logger := logging.GetLogger()
		logger.Error("❌ Failed to start Wall Controller TCP server on %s: %v", s.addr, err)
		return err
	}

	s.listener = listener
	s.running = true

	logger := logging.GetLogger()
	logger.Info("🚀 Wall Controller TCP server listening on %s", s.addr)
	logger.Info("🎯 Ready to accept wall controller connections...")

	go s.acceptConnections()

	return nil
}

// acceptConnections handles incoming TCP connections
func (s *WallControllerTCPServer) acceptConnections() {
	for {
		s.runningLock.RLock()
		running := s.running
		s.runningLock.RUnlock()

		if !running {
			break
		}

		conn, err := s.listener.Accept()
		if err != nil {
			logger := logging.GetLogger()
			if s.running {
				logger.Error("Error accepting TCP connection: %v", err)
			}
			continue
		}

		s.wg.Add(1)
		go s.handleConnection(conn)
	}
}

// handleConnection manages individual TCP connections
func (s *WallControllerTCPServer) handleConnection(conn net.Conn) {
	defer s.wg.Done()

	connectionID := conn.RemoteAddr().String()
	logger := logging.GetLogger()
	logger.Info("Wall Controller TCP client connected: %s", connectionID)

	s.clientsLock.Lock()
	s.clients[connectionID] = conn
	s.clientsLock.Unlock()

	// Notify manager of new connection
	s.manager.OnControllerConnected(connectionID, conn)

	// Read messages line by line
	scanner := bufio.NewScanner(conn)
	for scanner.Scan() {
		message := scanner.Text()
		if len(message) > 0 {
			s.manager.OnControllerMessage(connectionID, []byte(message))
		}
	}

	// Handle disconnect
	s.manager.OnControllerDisconnected(connectionID)

	s.clientsLock.Lock()
	delete(s.clients, connectionID)
	s.clientsLock.Unlock()

	conn.Close()
	logger.Info("Wall Controller TCP client disconnected: %s", connectionID)
}

// Stop gracefully shuts down the TCP server
func (s *WallControllerTCPServer) Stop() {
	s.runningLock.Lock()
	defer s.runningLock.Unlock()

	if !s.running {
		return
	}

	s.running = false

	if s.listener != nil {
		s.listener.Close()
	}

	// Close all client connections
	s.clientsLock.Lock()
	for _, conn := range s.clients {
		conn.Close()
	}
	s.clientsLock.Unlock()

	// Wait for all connection handlers to finish
	s.wg.Wait()

	logger := logging.GetLogger()
	logger.Info("Wall Controller TCP server stopped")
}
