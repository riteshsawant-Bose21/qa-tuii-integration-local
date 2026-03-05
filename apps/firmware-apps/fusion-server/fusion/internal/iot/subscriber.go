package fusioniot

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"os"
	"os/exec"
	"sync"
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
	json "github.com/goccy/go-json"

	"fusion-services-core/logging"
	"fusion/internal/cluster"
	"fusion/internal/utils"
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

// Subscriber handles subscribing to commands from AWS IoT Core
type Subscriber struct {
	config          *Config
	client          mqtt.Client
	cluster         *cluster.Cluster
	logger          *logging.Logger
	stopCh          chan struct{}
	wg              sync.WaitGroup
	mu              sync.RWMutex
	commandHandlers map[CommandType]CommandHandler
	connected       bool
	retryInterval   time.Duration
}

// NewSubscriber creates a new IoT subscriber
func NewSubscriber(config *Config, cluster *cluster.Cluster) (*Subscriber, error) {
	if config == nil {
		return nil, fmt.Errorf("config cannot be nil")
	}

	// Set defaults
	if config.Port == 0 {
		config.Port = DefaultPort
	}
	if config.CAFile == "" {
		config.CAFile = fmt.Sprintf("%s%s", utils.DefaultIdentityFilePath, utils.DefaultCAFileName)
	}
	if config.CertFile == "" {
		config.CertFile = fmt.Sprintf("%s%s", utils.DefaultIdentityFilePath, utils.DefaultCertFileName)
	}
	if config.KeyFile == "" {
		config.KeyFile = fmt.Sprintf("%s%s", utils.DefaultIdentityFilePath, utils.DefaultKeyFileName)
	}

	s := &Subscriber{
		config:          config,
		cluster:         cluster,
		logger:          logging.GetLogger(),
		stopCh:          make(chan struct{}),
		commandHandlers: make(map[CommandType]CommandHandler),
		retryInterval:   DefaultConnectRetryInterval,
	}

	// Register default command handlers
	s.RegisterHandler(CommandReboot, s.handleReboot)
	s.RegisterHandler(CommandStandby, s.handleStandby)

	return s, nil
}

// RegisterHandler registers a handler for a specific command type
func (s *Subscriber) RegisterHandler(cmdType CommandType, handler CommandHandler) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.commandHandlers[cmdType] = handler
}

// Start begins the IoT subscriber with connection retry logic
func (s *Subscriber) Start() error {
	if !s.config.Enabled {
		s.logger.Info("IoT subscriber disabled")
		return nil
	}

	if s.config.ProjectID == "" {
		s.logger.Warn("Project ID not configured, IoT subscriber cannot start")
		return fmt.Errorf("project ID is required for IoT subscriber")
	}

	// Check if certificate files exist before attempting connection
	if !s.certificatesExist() {
		s.logger.Warn("IoT certificates not found, subscriber will retry when available")
	}

	s.wg.Add(1)
	go s.connectionManager()

	s.logger.Info("IoT subscriber started, will connect when certificates and network are available")
	return nil
}

// Stop gracefully stops the subscriber
func (s *Subscriber) Stop() {
	close(s.stopCh)
	s.wg.Wait()

	s.mu.Lock()
	defer s.mu.Unlock()

	if s.client != nil && s.client.IsConnected() {
		s.client.Disconnect(250)
	}
	s.logger.Info("IoT subscriber stopped")
}

// connectionManager handles connection establishment and reconnection
func (s *Subscriber) connectionManager() {
	defer s.wg.Done()

	ticker := time.NewTicker(DefaultReconnectCheckInterval)
	defer ticker.Stop()

	// Try to connect immediately
	s.attemptConnection()

	for {
		select {
		case <-s.stopCh:
			return
		case <-ticker.C:
			s.mu.RLock()
			isConnected := s.connected && s.client != nil && s.client.IsConnected()
			s.mu.RUnlock()

			if !isConnected {
				s.attemptConnection()
			}
		}
	}
}

// attemptConnection tries to establish a connection to AWS IoT Core
func (s *Subscriber) attemptConnection() {
	// Check if certificates exist
	if !s.certificatesExist() {
		s.logger.Debug("Certificates not available, skipping connection attempt")
		return
	}

	// Check if we have network connectivity by attempting to connect
	if err := s.connect(); err != nil {
		s.logger.Warn("Failed to connect to IoT: %v, will retry in %v", err, s.retryInterval)

		// Exponential backoff
		s.retryInterval = s.retryInterval * 2
		if s.retryInterval > MaxConnectRetryInterval {
			s.retryInterval = MaxConnectRetryInterval
		}
		return
	}

	// Reset retry interval on successful connection
	s.retryInterval = DefaultConnectRetryInterval

	// Subscribe to command topic
	if err := s.subscribe(); err != nil {
		s.logger.Error("Failed to subscribe to command topic: %v", err)
		s.disconnect()
		return
	}

	s.mu.Lock()
	s.connected = true
	s.mu.Unlock()

	s.logger.Info("IoT subscriber connected and subscribed to command topic")
}

// certificatesExist checks if the required certificate files exist
func (s *Subscriber) certificatesExist() bool {
	files := []string{s.config.CAFile, s.config.CertFile, s.config.KeyFile}
	for _, file := range files {
		if _, err := os.Stat(file); os.IsNotExist(err) {
			return false
		}
	}
	return true
}

// connect establishes the MQTT connection to AWS IoT Core
func (s *Subscriber) connect() error {
	tlsConfig, err := s.newTLSConfig()
	if err != nil {
		return fmt.Errorf("failed to create TLS config: %w", err)
	}

	broker := fmt.Sprintf("ssl://%s:%d", s.config.Endpoint, s.config.Port)

	opts := mqtt.NewClientOptions()
	opts.AddBroker(broker)
	opts.SetClientID(fmt.Sprintf("%s-sub", s.config.ClientID))
	opts.SetTLSConfig(tlsConfig)
	opts.SetKeepAlive(30 * time.Second)
	opts.SetPingTimeout(10 * time.Second)
	opts.SetConnectTimeout(DefaultConnectTimeout)
	opts.SetAutoReconnect(true)
	opts.SetMaxReconnectInterval(30 * time.Second)
	opts.SetConnectRetry(true)
	opts.SetCleanSession(true)

	opts.SetConnectionLostHandler(func(client mqtt.Client, err error) {
		s.logger.Warn("IoT subscriber connection lost: %v", err)
		s.mu.Lock()
		s.connected = false
		s.mu.Unlock()
	})

	opts.SetOnConnectHandler(func(client mqtt.Client) {
		s.logger.Info("IoT subscriber connected to AWS IoT Core")
		// Resubscribe on reconnect
		if err := s.subscribe(); err != nil {
			s.logger.Error("Failed to resubscribe after reconnect: %v", err)
		}
	})

	opts.SetReconnectingHandler(func(client mqtt.Client, opts *mqtt.ClientOptions) {
		s.logger.Info("IoT subscriber reconnecting to AWS IoT Core...")
	})

	s.mu.Lock()
	s.client = mqtt.NewClient(opts)
	s.mu.Unlock()

	token := s.client.Connect()
	if !token.WaitTimeout(DefaultConnectTimeout) {
		return fmt.Errorf("connection timeout")
	}
	if token.Error() != nil {
		return token.Error()
	}

	return nil
}

// disconnect cleanly disconnects from the broker
func (s *Subscriber) disconnect() {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.client != nil && s.client.IsConnected() {
		s.client.Disconnect(250)
	}
	s.connected = false
}

// newTLSConfig creates the TLS configuration for AWS IoT Core
func (s *Subscriber) newTLSConfig() (*tls.Config, error) {
	// Load CA certificate
	caCert, err := os.ReadFile(s.config.CAFile)
	if err != nil {
		return nil, fmt.Errorf("failed to read CA file %s: %w", s.config.CAFile, err)
	}

	caCertPool := x509.NewCertPool()
	if !caCertPool.AppendCertsFromPEM(caCert) {
		return nil, fmt.Errorf("failed to parse CA certificate")
	}

	// Load client certificate and key
	cert, err := tls.LoadX509KeyPair(s.config.CertFile, s.config.KeyFile)
	if err != nil {
		return nil, fmt.Errorf("failed to load client certificate: %w", err)
	}

	return &tls.Config{
		RootCAs:      caCertPool,
		Certificates: []tls.Certificate{cert},
		MinVersion:   tls.VersionTLS12,
	}, nil
}

// subscribe subscribes to the command topic
func (s *Subscriber) subscribe() error {
	s.mu.RLock()
	client := s.client
	s.mu.RUnlock()

	if client == nil || !client.IsConnected() {
		return fmt.Errorf("client not connected")
	}

	topic := s.getCommandTopic()
	s.logger.Info("Subscribing to command topic: %s", topic)

	token := client.Subscribe(topic, byte(DefaultSubscribeQoS), s.handleMessage)
	if !token.WaitTimeout(DefaultPublishTimeout) {
		return fmt.Errorf("subscribe timeout")
	}

	return token.Error()
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

	// Only the primary node should coordinate the cluster reboot
	// Each node receiving the command will reboot itself
	if s.cluster.IsLocalNodePrimary() {
		s.logger.Info("Primary node initiating cluster reboot sequence")
	}

	// Execute system reboot after a short delay to allow for cleanup
	go func() {
		time.Sleep(2 * time.Second)

		s.logger.Info("Initiating system reboot...")

		// Use systemctl to reboot the system
		cmd := exec.Command("systemctl", "reboot")
		if err := cmd.Run(); err != nil {
			s.logger.Error("Failed to execute systemctl reboot: %v", err)

			// Fallback to shutdown command
			cmd = exec.Command("shutdown", "-r", "now")
			if err := cmd.Run(); err != nil {
				s.logger.Error("Failed to execute shutdown -r: %v", err)

				// Last resort: direct reboot syscall
				cmd = exec.Command("reboot")
				if err := cmd.Run(); err != nil {
					s.logger.Error("All reboot methods failed: %v", err)
				}
			}
		}
	}()

	return nil
}

// handleStandby handles the STANDBY command
func (s *Subscriber) handleStandby(cmd DeviceCommand) error {
	s.logger.Info("Executing standby mode (command ID: %s)", cmd.ID)

	// TODO: Implement standby logic based on your system requirements
	// This might involve:
	// - Suspending non-essential services
	// - Reducing power consumption
	// - Entering a low-power state

	s.logger.Warn("Standby command received but not yet implemented")
	return nil
}

// IsConnected returns true if the subscriber is connected
func (s *Subscriber) IsConnected() bool {
	s.mu.RLock()
	defer s.mu.RUnlock()

	return s.connected && s.client != nil && s.client.IsConnected()
}
