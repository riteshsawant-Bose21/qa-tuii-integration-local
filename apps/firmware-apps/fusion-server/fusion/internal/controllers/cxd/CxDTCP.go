package cxd

import (
	"bufio"
	"fmt"
	"fusion/internal/logging"
	"net"
	"strings"
	"sync"
)

// TCPController handles parameter control via TCP
type TCPController struct {
	nodeName      string
	deviceID      string
	port          int
	conn          net.Conn
	listener      net.Listener
	mutex         sync.Mutex
	subscriptions map[string]func(string)
	done          chan struct{}
}

// NewTCPController creates a new TCP controller for a device
func NewTCPController(nodeName string, deviceID string, port int) (*TCPController, error) {
	logger := logging.GetLogger(nodeName)
	logger.Debug("NewTCPController: Starting TCP listener for device %s on port %d", deviceID, port)

	addr := fmt.Sprintf(":%d", port)
	logger.Debug("Attempting to listen on address: %s", addr)

	listener, err := net.Listen("tcp", addr)
	if err != nil {
		logger.Error("Failed to create listener: %v", err)
		return nil, fmt.Errorf("failed to start TCP listener: %w", err)
	}
	logger.Debug("TCP listener created successfully")

	controller := &TCPController{
		nodeName:      nodeName,
		deviceID:      deviceID,
		port:          port,
		listener:      listener,
		subscriptions: make(map[string]func(string)),
		done:          make(chan struct{}),
	}

	logger.Debug("Starting accept loop for device %s", deviceID)
	go controller.acceptLoop()

	return controller, nil
}

// IsConnected returns true if there's an active connection
func (c *TCPController) IsConnected() bool {
	c.mutex.Lock()
	defer c.mutex.Unlock()
	return c.conn != nil
}

// Close stops the TCP controller
func (c *TCPController) Close() error {
	close(c.done)
	c.mutex.Lock()
	defer c.mutex.Unlock()

	if c.conn != nil {
		c.conn.Close()
	}
	return c.listener.Close()
}

// Send sends a parameter update to the device
func (c *TCPController) Send(param, index, value string) error {
	c.mutex.Lock()
	defer c.mutex.Unlock()

	if c.conn == nil {
		return &DeviceError{
			Code:    ErrNotConnected,
			Message: "no active connection",
		}
	}

	msg := fmt.Sprintf("GA\"%s\">%s=%s\r", param, index, value)
	_, err := c.conn.Write([]byte(msg))
	return err
}

// SetNetworkParameters sends network configuration
func (c *TCPController) SetNetworkParameters(ip net.IP) error {
	c.mutex.Lock()
	defer c.mutex.Unlock()

	if c.conn == nil {
		return &DeviceError{
			Code:    ErrNotConnected,
			Message: "no active connection",
		}
	}

	msg := fmt.Sprintf("IP %d.%d.%d.%d\r", ip[0], ip[1], ip[2], ip[3])
	_, err := c.conn.Write([]byte(msg))
	return err
}

// Subscribe registers for parameter updates
func (c *TCPController) Subscribe(param string, callback func(string)) error {
	c.mutex.Lock()
	defer c.mutex.Unlock()

	if c.conn == nil {
		return &DeviceError{
			Code:    ErrNotConnected,
			Message: "no active connection",
		}
	}

	msg := fmt.Sprintf("SUB %s\r", param)
	if _, err := c.conn.Write([]byte(msg)); err != nil {
		return err
	}

	c.subscriptions[param] = callback
	return nil
}

func (c *TCPController) acceptLoop() {
	logger := logging.GetLogger(c.nodeName)
	logger.Debug("AcceptLoop started for device %s on port %d", c.deviceID, c.port)

	for {
		select {
		case <-c.done:
			logger.Debug("AcceptLoop received done signal, exiting")
			return
		default:
			logger.Debug("Waiting for connection on port %d", c.port)
			conn, err := c.listener.Accept()
			if err != nil {
				logger.Error("Failed to accept connection: %v", err)
				continue
			}

			c.mutex.Lock()
			if c.conn != nil {
				logger.Debug("Closing existing connection")
				c.conn.Close()
			}
			c.conn = conn
			c.mutex.Unlock()

			logger.Debug("Client '%s' connected from %s", c.deviceID, conn.RemoteAddr())
			go c.handleConnection(conn)
		}
	}
}

func (c *TCPController) handleCommand(cmd string) error {
	switch {
	case strings.HasPrefix(cmd, "GA "):
		return c.handleGetParam(strings.TrimPrefix(cmd, "GA "))

	case strings.HasPrefix(cmd, "SUB "):
		return c.handleSubscribe(strings.TrimPrefix(cmd, "SUB "))

	case strings.HasPrefix(cmd, "SA "):
		return c.handleSetParam(strings.TrimPrefix(cmd, "SA "))

	default:
		logger := logging.GetLogger(c.nodeName)
		logger.Info("Unknown command received: %s", cmd)
		return nil
	}
}

func (c *TCPController) handleGetParam(param string) error {
	param = strings.Trim(param, "\"")
	parts := strings.Split(param, ">")
	if len(parts) != 2 {
		return fmt.Errorf("invalid parameter format: %s", param)
	}

	paramName, index := parts[0], parts[1]

	c.mutex.Lock()
	callback, exists := c.subscriptions[paramName]
	c.mutex.Unlock()

	if exists {
		callback(index)
	}

	return nil
}

func (c *TCPController) handleSetParam(param string) error {
	param = strings.Trim(param, "\"")
	parts := strings.Split(param, "=")
	if len(parts) != 2 {
		return fmt.Errorf("invalid set parameter format: %s", param)
	}

	paramParts := strings.Split(parts[0], ">")
	if len(paramParts) != 2 {
		return fmt.Errorf("invalid parameter format: %s", parts[0])
	}

	paramName, _ := paramParts[0], paramParts[1]
	value := parts[1]

	c.mutex.Lock()
	callback, exists := c.subscriptions[paramName]
	c.mutex.Unlock()

	if exists {
		callback(value)
	}

	return nil
}

func (c *TCPController) handleSubscribe(cmd string) error {
	cmd = strings.TrimSpace(cmd)

	c.mutex.Lock()
	defer c.mutex.Unlock()

	if c.conn == nil {
		return fmt.Errorf("no active connection")
	}

	response := fmt.Sprintf("SUB %s,yes\r", cmd)
	_, err := c.conn.Write([]byte(response))
	return err
}

func (c *TCPController) handleConnection(conn net.Conn) {
	logger := logging.GetLogger(c.nodeName)
	defer func() {
		conn.Close()
		c.mutex.Lock()
		if c.conn == conn {
			c.conn = nil
		}
		c.mutex.Unlock()
		logger.Info("Client '%s' disconnected", c.deviceID)
	}()

	scanner := bufio.NewScanner(conn)
	scanner.Split(func(data []byte, atEOF bool) (advance int, token []byte, err error) {
		if atEOF && len(data) == 0 {
			return 0, nil, nil
		}

		if i := strings.Index(string(data), "\n"); i >= 0 {
			return i + 1, data[0:i], nil
		}
		if atEOF {
			return len(data), data, nil
		}
		return 0, nil, nil
	})

	for scanner.Scan() {
		cmd := scanner.Text()
		logger.Debug("Processing command: %s", cmd)
		if err := c.handleCommand(cmd); err != nil {
			logger.Error("Error handling command '%s': %v", cmd, err)
			return
		}
	}

	if err := scanner.Err(); err != nil {
		logger.Error("Scanner error for device '%s': %v", c.deviceID, err)
	}
}
