package fusioniot

import (
	"bytes"
	"fmt"
	"net/http"
	"sync"
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
	json "github.com/goccy/go-json"

	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/cluster"
	"fusion/internal/persistence"
	"fusion/internal/routes"
)

const (
	// Subscriber settings
	DefaultSubscribeQoS           = 1
	DefaultReconnectCheckInterval = 30 * time.Second
	DefaultConnectRetryInterval   = 10 * time.Second
	MaxConnectRetryInterval       = 5 * time.Minute
)

// CommandType represents the type of command that can be sent
type CommandType string

const (
	CommandReboot  CommandType = "REBOOT"
	CommandStandby CommandType = "STANDBY"
)

// CommandRequest represents the command payload from cloud backend
type CommandRequest struct {
	Command   CommandType `json:"command"`
	DeviceIDs []string    `json:"device_ids"`
}

// DeviceCommand represents the full command message structure from cloud backend
type DeviceCommand struct {
	Command CommandRequest `json:"command"`
	ID      string         `json:"id"`
}

// CommandHandler is a function that handles received commands
type CommandHandler func(cmd DeviceCommand) error

// CommandResponsePayload represents the response sent after command completion.
type CommandResponsePayload struct {
	CommandID   string `json:"command_id"`
	CommandType string `json:"command_type"`
	Status      string `json:"status"`
	DeviceID    string `json:"device_id"`
	Timestamp   string `json:"timestamp"`
	ErrorMsg    string `json:"error_msg,omitempty"`
}

// Subscriber handles subscribing to commands from AWS IoT Core
type Subscriber struct {
	config          *api.IoTConfig
	client          *Client
	cluster         *cluster.Cluster
	persistence     *persistence.Persistence
	publisher       *Publisher
	logger          *logging.Logger
	stopCh          chan struct{}
	wg              sync.WaitGroup
	mu              sync.RWMutex
	commandHandlers map[CommandType]CommandHandler
	subscribed      bool
}

// NewSubscriber creates a new IoT subscriber that uses a shared client
func NewSubscriber(client *Client, cluster *cluster.Cluster, persistence *persistence.Persistence) (*Subscriber, error) {
	if client == nil {
		return nil, fmt.Errorf("client cannot be nil")
	}

	config := client.GetConfig()

	s := &Subscriber{
		config:          config,
		client:          client,
		cluster:         cluster,
		persistence:     persistence,
		logger:          logging.GetLogger(),
		stopCh:          make(chan struct{}),
		commandHandlers: make(map[CommandType]CommandHandler),
	}

	// Register default command handlers
	s.RegisterHandler(CommandReboot, s.handleReboot)

	// Set up callback to subscribe when client connects
	client.SetOnConnectCallback(s.onConnect)

	return s, nil
}

// onConnect is called when the shared client connects/reconnects
func (s *Subscriber) onConnect() {
	s.logger.Info("IoT client connected, subscribing to command topic")
	// Run subscribe asynchronously to avoid blocking the MQTT client's OnConnect handler
	// Blocking here would prevent the client from processing the SUBACK response
	go func() {
		// Wait for connection to stabilize before subscribing
		// The MQTT session needs time to be fully ready after the TCP/TLS handshake
		time.Sleep(500 * time.Millisecond)

		if err := s.subscribe(); err != nil {
			s.logger.Error("Failed to subscribe to command topic: %v", err)
			return
		}

		s.mu.Lock()
		s.subscribed = true
		s.mu.Unlock()

		s.logger.Info("IoT subscriber subscribed to command topic")
	}()
}

// SetPublisher sets the publisher reference for sending command responses.
// This is called after both publisher and subscriber are initialized.
func (s *Subscriber) SetPublisher(publisher *Publisher) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.publisher = publisher
}

// RegisterHandler registers a handler for a specific command type
func (s *Subscriber) RegisterHandler(cmdType CommandType, handler CommandHandler) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.commandHandlers[cmdType] = handler
}

// Start begins the IoT subscriber
func (s *Subscriber) Start() error {
	if !s.config.Enabled {
		s.logger.Info("IoT subscriber disabled")
		return nil
	}

	if s.config.ProjectID == "" {
		s.logger.Warn("Project ID not configured, IoT subscriber cannot start")
		return fmt.Errorf("project ID is required for IoT subscriber")
	}

	// If already connected, subscribe immediately
	if s.client.IsConnected() {
		s.onConnect()
	}

	s.logger.Info("IoT subscriber started")
	return nil
}

// Stop gracefully stops the subscriber
func (s *Subscriber) Stop() {
	close(s.stopCh)
	s.wg.Wait()
	s.logger.Info("IoT subscriber stopped")
}

// subscribe subscribes to the command topic with retry logic
func (s *Subscriber) subscribe() error {
	topic := s.getCommandTopic()
	s.logger.Info("Subscribing to command topic: %s", topic)

	maxRetries := 5
	retryDelay := 500 * time.Millisecond

	var lastErr error
	for i := 0; i < maxRetries; i++ {
		// Check if we should stop
		select {
		case <-s.stopCh:
			return fmt.Errorf("subscriber stopped")
		default:
		}

		// Check connection before attempting subscribe
		if !s.client.IsConnected() {
			s.logger.Warn("Client disconnected, aborting subscribe attempt")
			return fmt.Errorf("client not connected")
		}

		lastErr = s.client.Subscribe(topic, byte(DefaultSubscribeQoS), s.handleMessage)
		if lastErr == nil {
			return nil
		}

		s.logger.Warn("Subscribe attempt %d/%d failed: %v, retrying in %v", i+1, maxRetries, lastErr, retryDelay)

		select {
		case <-s.stopCh:
			return fmt.Errorf("subscriber stopped")
		case <-time.After(retryDelay):
		}

		retryDelay *= 2 // exponential backoff
		if retryDelay > 10*time.Second {
			retryDelay = 10 * time.Second
		}
	}

	return fmt.Errorf("failed to subscribe after %d attempts: %w", maxRetries, lastErr)
}

// getCommandTopic returns the command topic for this project
func (s *Subscriber) getCommandTopic() string {
	return fmt.Sprintf("%s%s/command", s.config.TopicPrefix, s.config.ProjectID)
}

// handleMessage processes incoming MQTT messages
func (s *Subscriber) handleMessage(client mqtt.Client, msg mqtt.Message) {
	s.logger.Info("Received command message on topic: %s", msg.Topic())

	var cmd DeviceCommand
	if err := json.Unmarshal(msg.Payload(), &cmd); err != nil {
		s.logger.Error("Failed to unmarshal command message: %v", err)
		return
	}

	s.logger.Info("Processing command: %s (ID: %s)", cmd.Command.Command, cmd.ID)

	// Check if this command is targeted at specific devices
	if len(cmd.Command.DeviceIDs) > 0 {
		// Get local device ID and check if we're a target
		deviceInfo := s.cluster.GetInfo()
		isTarget := false
		for _, targetID := range cmd.Command.DeviceIDs {
			if targetID == deviceInfo.LocalNode {
				isTarget = true
				break
			}
		}
		if !isTarget {
			s.logger.Debug("Command not targeted at this device, ignoring")
			return
		}
	}

	// Find and execute the handler
	s.mu.RLock()
	handler, exists := s.commandHandlers[cmd.Command.Command]
	s.mu.RUnlock()

	if !exists {
		s.logger.Warn("No handler registered for command type: %s", cmd.Command.Command)
		return
	}

	if err := handler(cmd); err != nil {
		s.logger.Error("Failed to execute command %s: %v", cmd.Command.Command, err)
		return
	}

	s.logger.Info("Successfully executed command: %s", cmd.Command.Command)
}

// handleReboot handles the REBOOT command
func (s *Subscriber) handleReboot(cmd DeviceCommand) error {
	s.logger.Info("Executing system reboot (command ID: %s)", cmd.ID)

	// Build the command payload — RebootSystem will persist it on each node
	persistCmd := persistence.Command{
		ID:            cmd.ID,
		CommandType:   string(CommandReboot),
		Source:        persistence.CommandSourceRemoteCommand,
		DeviceIDArray: cmd.Command.DeviceIDs,
	}

	body, err := json.Marshal(persistCmd)
	if err != nil {
		s.logger.Error("Failed to marshal reboot command: %v", err)
		s.failRebootCommand(cmd, err.Error())
		return err
	}

	// Call the reboot API endpoint, which persists the command and fans out to all cluster nodes
	rebootURL := fmt.Sprintf("%slocalhost:%s%s", api.Protocol, api.HTTPPort, routes.ClusterRebootEndpoint)
	s.logger.Info("Calling reboot API: %s", rebootURL)

	resp, err := http.Post(rebootURL, api.JsonMIMEType, bytes.NewReader(body))
	if err != nil {
		s.logger.Error("Failed to call reboot API: %v", err)
		s.failRebootCommand(cmd, err.Error())
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusNoContent {
		errMsg := fmt.Sprintf("reboot API returned unexpected status: %d", resp.StatusCode)
		s.logger.Error(errMsg)
		s.failRebootCommand(cmd, errMsg)
		return fmt.Errorf("%s", errMsg)
	}

	return nil
}

// failRebootCommand sends a FAILED response over MQTT via the publisher.
func (s *Subscriber) failRebootCommand(cmd DeviceCommand, errMsg string) {
	deviceInfo := s.cluster.GetInfo()
	s.mu.RLock()
	publisher := s.publisher
	s.mu.RUnlock()
	if publisher != nil {
		publisher.SendCommandResponse(cmd.ID, string(CommandReboot), "FAILED", deviceInfo.LocalNode, errMsg)
	}
}

// IsConnected returns true if the subscriber is connected.
func (s *Subscriber) IsConnected() bool {
	return s.client.IsConnected()
}
