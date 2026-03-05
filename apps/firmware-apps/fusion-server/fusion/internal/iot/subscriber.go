package fusioniot

import (
	"fmt"
	"sync"
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
	json "github.com/goccy/go-json"

	"fusion-services-core/logging"
	"fusion/internal/cluster"
	"fusion/internal/persistence"
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
	config                   *Config
	client                   *Client
	cluster                  *cluster.Cluster
	persistence              *persistence.Persistence
	publisher                *Publisher
	logger                   *logging.Logger
	stopCh                   chan struct{}
	wg                       sync.WaitGroup
	mu                       sync.RWMutex
	commandHandlers          map[CommandType]CommandHandler
	subscribed               bool
	pendingCommandsProcessed bool
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
		shouldProcessPending := !s.pendingCommandsProcessed
		s.pendingCommandsProcessed = true
		s.mu.Unlock()

		s.logger.Info("IoT subscriber subscribed to command topic")

		// Process any pending commands from before reboot (only on first connection)
		if shouldProcessPending {
			time.Sleep(5 * time.Second)
			s.ProcessPendingCommands()
		}
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

	// Store the pending command before rebooting
	if s.persistence != nil {
		deviceInfo := s.cluster.GetInfo()
		pendingCmd := &persistence.PendingCommand{
			ID:          cmd.ID,
			CommandType: string(CommandReboot),
			Status:      persistence.PendingCommandStatusPending,
			Source:      persistence.RebootSourceRemoteCommand,
			ProjectID:   s.config.ProjectID,
			DeviceID:    deviceInfo.LocalNode,
			CreatedAt:   time.Now().UTC(),
		}
		if err := s.persistence.SavePendingCommand(pendingCmd); err != nil {
			s.logger.Error("Failed to save pending command before reboot: %v", err)
			// Continue with reboot even if we can't save the pending command
		} else {
			s.logger.Info("Saved pending command %s before reboot", cmd.ID)
		}
	}

	// Only the primary node should coordinate the cluster reboot
	// Each node receiving the command will reboot itself
	if s.cluster.IsLocalNodePrimary() {
		s.logger.Info("Primary node initiating cluster reboot sequence")
	}

	// Use the cluster's reboot functionality which handles OS-specific logic
	if err := s.cluster.TriggerReboot(); err != nil {
		s.logger.Error("Failed to trigger reboot: %v", err)
		// Mark command as failed if we couldn't reboot
		if s.persistence != nil {
			s.persistence.UpdatePendingCommandStatus(cmd.ID, persistence.PendingCommandStatusFailed, err.Error())
		}
		return err
	}

	return nil
}

// ProcessPendingCommands checks for pending commands after startup and sends responses.
// This should be called after the system has booted and IoT connection is established.
func (s *Subscriber) ProcessPendingCommands() {
	if s.persistence == nil {
		s.logger.Debug("Persistence not available, skipping pending command check")
		return
	}

	// Get all pending commands
	pendingCmds, err := s.persistence.GetPendingCommandsByStatus(persistence.PendingCommandStatusPending)
	if err != nil {
		s.logger.Error("Failed to get pending commands: %v", err)
		return
	}

	if len(pendingCmds) == 0 {
		s.logger.Debug("No pending commands to process")
		return
	}

	s.logger.Info("Found %d pending commands to process", len(pendingCmds))

	for _, cmd := range pendingCmds {
		// Check if this was a remote command that needs a response
		if cmd.Source == persistence.RebootSourceRemoteCommand {
			// Mark as completed
			if err := s.persistence.UpdatePendingCommandStatus(cmd.ID, persistence.PendingCommandStatusCompleted, ""); err != nil {
				s.logger.Error("Failed to update pending command status: %v", err)
				continue
			}

			// Send response
			s.sendCommandResponse(cmd.ID, cmd.CommandType, "COMPLETED", cmd.DeviceID, "")
		}
	}

	// Clean up completed commands
	if err := s.persistence.ClearCompletedCommands(); err != nil {
		s.logger.Error("Failed to clear completed commands: %v", err)
	}
}

// sendCommandResponse publishes a command response to the response topic.
func (s *Subscriber) sendCommandResponse(commandID, commandType, status, deviceID, errorMsg string) {
	if !s.client.IsConnected() {
		s.logger.Warn("Client not connected, cannot send command response for %s", commandID)
		return
	}

	response := CommandResponsePayload{
		CommandID:   commandID,
		CommandType: commandType,
		Status:      status,
		DeviceID:    deviceID,
		Timestamp:   time.Now().UTC().Format(time.RFC3339),
		ErrorMsg:    errorMsg,
	}

	// Publish to the command_response topic
	topic := s.getCommandResponseTopic()
	s.logger.Info("Sending command response to topic: %s", topic)

	data, err := json.Marshal(response)
	if err != nil {
		s.logger.Error("Failed to marshal command response: %v", err)
		return
	}

	if err := s.client.Publish(topic, byte(DefaultSubscribeQoS), false, data); err != nil {
		s.logger.Error("Failed to publish command response: %v", err)
		return
	}

	s.logger.Info("Successfully sent command response for command %s", commandID)
}

// getCommandResponseTopic returns the topic for command responses.
func (s *Subscriber) getCommandResponseTopic() string {
	return fmt.Sprintf("%s%s/command_response", s.config.TopicPrefix, s.config.ProjectID)
}

// IsConnected returns true if the subscriber is connected
func (s *Subscriber) IsConnected() bool {
	return s.client.IsConnected()
}

// GetRebootSource returns the source of the last reboot if it was triggered by a remote command.
// Returns the command ID if it was a remote command, empty string otherwise.
func (s *Subscriber) GetRebootSource() (persistence.RebootSource, string) {
	if s.persistence == nil {
		return persistence.RebootSourceLocal, ""
	}

	pendingCmds, err := s.persistence.GetPendingCommandsByStatus(persistence.PendingCommandStatusPending)
	if err != nil || len(pendingCmds) == 0 {
		return persistence.RebootSourceLocal, ""
	}

	// Return the first pending reboot command
	for _, cmd := range pendingCmds {
		if cmd.CommandType == string(CommandReboot) && cmd.Source == persistence.RebootSourceRemoteCommand {
			return persistence.RebootSourceRemoteCommand, cmd.ID
		}
	}

	return persistence.RebootSourceLocal, ""
}
