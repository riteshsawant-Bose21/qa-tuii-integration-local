package fusioniot

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"os"
	"sync"
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"

	"fusion-services-core/logging"
	"fusion/internal/utils"
)

// Client is a shared MQTT client for AWS IoT Core that can be used by both
// the publisher and subscriber. This ensures only one connection per certificate.
type Client struct {
	config    *Config
	client    mqtt.Client
	logger    *logging.Logger
	stopCh    chan struct{}
	wg        sync.WaitGroup
	mu        sync.RWMutex
	connected bool

	// Callbacks for connection events
	onConnect    func()
	onDisconnect func(error)
}

// NewClient creates a new shared IoT client
func NewClient(config *Config) (*Client, error) {
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

	return &Client{
		config: config,
		logger: logging.GetLogger(),
		stopCh: make(chan struct{}),
	}, nil
}

// SetOnConnectCallback sets the callback to be called when the client connects/reconnects
func (c *Client) SetOnConnectCallback(cb func()) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.onConnect = cb
}

// SetOnDisconnectCallback sets the callback to be called when the client disconnects
func (c *Client) SetOnDisconnectCallback(cb func(error)) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.onDisconnect = cb
}

// Start begins the client with connection retry logic
func (c *Client) Start() error {
	if !c.config.Enabled {
		c.logger.Info("IoT client disabled")
		return nil
	}

	// Check if certificate files exist before attempting connection
	if !c.certificatesExist() {
		c.logger.Warn("IoT certificates not found, client will retry when available")
	}

	c.wg.Add(1)
	go c.connectionManager()

	c.logger.Info("IoT client started, will connect when certificates and network are available")
	return nil
}

// Stop gracefully stops the client
func (c *Client) Stop() {
	close(c.stopCh)
	c.wg.Wait()

	c.mu.Lock()
	defer c.mu.Unlock()

	if c.client != nil && c.client.IsConnected() {
		c.client.Disconnect(250)
	}
	c.logger.Info("IoT client stopped")
}

// connectionManager handles connection establishment and reconnection
func (c *Client) connectionManager() {
	defer c.wg.Done()

	ticker := time.NewTicker(DefaultReconnectCheckInterval)
	defer ticker.Stop()

	retryInterval := DefaultConnectRetryInterval

	// Try to connect immediately
	if err := c.attemptConnection(); err != nil {
		c.logger.Warn("Initial connection failed: %v, will retry", err)
	}

	for {
		select {
		case <-c.stopCh:
			return
		case <-ticker.C:
			c.mu.RLock()
			isConnected := c.connected && c.client != nil && c.client.IsConnected()
			c.mu.RUnlock()

			if !isConnected {
				if err := c.attemptConnection(); err != nil {
					c.logger.Warn("Connection attempt failed: %v, will retry in %v", err, retryInterval)
					retryInterval = retryInterval * 2
					if retryInterval > MaxConnectRetryInterval {
						retryInterval = MaxConnectRetryInterval
					}
				} else {
					retryInterval = DefaultConnectRetryInterval
				}
			}
		}
	}
}

// attemptConnection tries to establish a connection to AWS IoT Core
func (c *Client) attemptConnection() error {
	// Check if certificates exist
	if !c.certificatesExist() {
		return fmt.Errorf("certificates not available")
	}

	return c.connect()
}

// certificatesExist checks if the required certificate files exist
func (c *Client) certificatesExist() bool {
	files := []string{c.config.CAFile, c.config.CertFile, c.config.KeyFile}
	for _, file := range files {
		if _, err := os.Stat(file); os.IsNotExist(err) {
			return false
		}
	}
	return true
}

// connect establishes the MQTT connection to AWS IoT Core
func (c *Client) connect() error {
	tlsConfig, err := c.newTLSConfig()
	if err != nil {
		return fmt.Errorf("failed to create TLS config: %w", err)
	}

	broker := fmt.Sprintf("ssl://%s:%d", c.config.Endpoint, c.config.Port)

	opts := mqtt.NewClientOptions()
	opts.AddBroker(broker)
	opts.SetClientID(c.config.ClientID)
	opts.SetTLSConfig(tlsConfig)
	opts.SetKeepAlive(30 * time.Second)
	opts.SetPingTimeout(10 * time.Second)
	opts.SetConnectTimeout(DefaultConnectTimeout)
	opts.SetAutoReconnect(true)
	opts.SetMaxReconnectInterval(30 * time.Second)
	opts.SetConnectRetry(true)
	opts.SetCleanSession(true)

	opts.SetConnectionLostHandler(func(client mqtt.Client, err error) {
		c.logger.Warn("IoT connection lost: %v", err)
		c.mu.Lock()
		c.connected = false
		onDisconnect := c.onDisconnect
		c.mu.Unlock()

		if onDisconnect != nil {
			onDisconnect(err)
		}
	})

	opts.SetOnConnectHandler(func(client mqtt.Client) {
		c.logger.Info("IoT client connected to AWS IoT Core")
		c.mu.Lock()
		c.connected = true
		onConnect := c.onConnect
		c.mu.Unlock()

		if onConnect != nil {
			onConnect()
		}
	})

	opts.SetReconnectingHandler(func(client mqtt.Client, opts *mqtt.ClientOptions) {
		c.logger.Info("IoT client reconnecting to AWS IoT Core...")
	})

	c.mu.Lock()
	c.client = mqtt.NewClient(opts)
	c.mu.Unlock()

	token := c.client.Connect()
	if !token.WaitTimeout(DefaultConnectTimeout) {
		return fmt.Errorf("connection timeout")
	}
	if token.Error() != nil {
		return token.Error()
	}

	return nil
}

// newTLSConfig creates the TLS configuration for AWS IoT Core
func (c *Client) newTLSConfig() (*tls.Config, error) {
	// Load CA certificate
	caCert, err := os.ReadFile(c.config.CAFile)
	if err != nil {
		return nil, fmt.Errorf("failed to read CA file %s: %w", c.config.CAFile, err)
	}

	caCertPool := x509.NewCertPool()
	if !caCertPool.AppendCertsFromPEM(caCert) {
		return nil, fmt.Errorf("failed to parse CA certificate")
	}

	// Load client certificate and key
	cert, err := tls.LoadX509KeyPair(c.config.CertFile, c.config.KeyFile)
	if err != nil {
		return nil, fmt.Errorf("failed to load client certificate: %w", err)
	}

	return &tls.Config{
		RootCAs:      caCertPool,
		Certificates: []tls.Certificate{cert},
		MinVersion:   tls.VersionTLS12,
	}, nil
}

// IsConnected returns true if the client is connected
func (c *Client) IsConnected() bool {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return c.connected && c.client != nil && c.client.IsConnected()
}

// Publish sends a message to a topic
func (c *Client) Publish(topic string, qos byte, retained bool, payload []byte) error {
	c.mu.RLock()
	client := c.client
	c.mu.RUnlock()

	if client == nil || !client.IsConnected() {
		return fmt.Errorf("client not connected")
	}

	token := client.Publish(topic, qos, retained, payload)
	if !token.WaitTimeout(DefaultPublishTimeout) {
		return fmt.Errorf("publish timeout")
	}

	return token.Error()
}

// Subscribe subscribes to a topic with a message handler
func (c *Client) Subscribe(topic string, qos byte, handler mqtt.MessageHandler) error {
	c.mu.RLock()
	client := c.client
	c.mu.RUnlock()

	if client == nil || !client.IsConnected() {
		return fmt.Errorf("client not connected")
	}

	token := client.Subscribe(topic, qos, handler)
	if !token.WaitTimeout(DefaultPublishTimeout) {
		return fmt.Errorf("subscribe timeout")
	}

	return token.Error()
}

// GetConfig returns the client configuration
func (c *Client) GetConfig() *Config {
	return c.config
}
