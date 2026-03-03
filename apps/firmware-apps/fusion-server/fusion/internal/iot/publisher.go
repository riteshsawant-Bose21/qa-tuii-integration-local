package iot

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"os"
	"sync"
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
	json "github.com/goccy/go-json"

	"fusion-services-core/logging"
	"fusion/internal/cluster"
)

const (
	// Default paths for device identity certificates
	DefaultCAFile   = "/var/lib/device-identity/AmazonRootCA1.pem"
	DefaultCertFile = "/var/lib/device-identity/device.x509.cert"
	DefaultKeyFile  = "/var/lib/device-identity/device.key"

	// MQTT settings
	DefaultPort           = 8883
	DefaultPublishQoS     = 1
	DefaultKeepAlive      = 60 * time.Second
	DefaultConnectTimeout = 30 * time.Second
	DefaultPublishTimeout = 10 * time.Second

	// Publishing intervals
	DefaultMetricsInterval = 10 * time.Second
)

// Config holds the AWS IoT Core connection configuration
type Config struct {
	// Endpoint is the AWS IoT Core endpoint (e.g., "a1a77o9cigolk4-ats.iot.us-east-2.amazonaws.com")
	Endpoint string
	// Port is the MQTT port (default 8883 for TLS)
	Port int
	// ClientID is the unique identifier for this device
	ClientID string
	// CAFile is the path to the Amazon Root CA certificate
	CAFile string
	// CertFile is the path to the device certificate
	CertFile string
	// KeyFile is the path to the device private key
	KeyFile string
	// TopicPrefix is the prefix for MQTT topics (e.g., "logs/")
	TopicPrefix string
	// MetricsInterval is how often to publish metrics
	MetricsInterval time.Duration
	// Enabled determines if IoT publishing is active
	Enabled bool
}

// Publisher handles publishing metrics to AWS IoT Core
type Publisher struct {
	config  *Config
	client  mqtt.Client
	metrics *cluster.MetricsCollector
	logger  *logging.Logger
	stopCh  chan struct{}
	wg      sync.WaitGroup
	mu      sync.RWMutex
	cluster *cluster.Cluster
}

// MetricsPayload represents the structure of metrics sent to IoT
type MetricsPayload struct {
	Timestamp        string  `json:"timestamp"`
	DeviceID         string  `json:"device_id"`
	Status           string  `json:"status"`
	CPUUsage         float64 `json:"cpu_usage"`
	MemoryUsage      int64   `json:"memory_usage"`
	Goroutines       int     `json:"goroutines"`
	WebSocketClients int     `json:"websocket_clients"`
	ClusterMembers   int     `json:"cluster_members"`
	ClusterHealth    float64 `json:"cluster_health"`
	HAProxyStatus    string  `json:"haproxy_status"`
	UptimeSeconds    int64   `json:"uptime_seconds"`
}

// NewPublisher creates a new IoT publisher
func NewPublisher(config *Config, metrics *cluster.MetricsCollector, cluster *cluster.Cluster) (*Publisher, error) {
	if config == nil {
		return nil, fmt.Errorf("config cannot be nil")
	}

	// Set defaults
	if config.Port == 0 {
		config.Port = DefaultPort
	}
	if config.CAFile == "" {
		config.CAFile = DefaultCAFile
	}
	if config.CertFile == "" {
		config.CertFile = DefaultCertFile
	}
	if config.KeyFile == "" {
		config.KeyFile = DefaultKeyFile
	}
	if config.MetricsInterval == 0 {
		config.MetricsInterval = DefaultMetricsInterval
	}

	return &Publisher{
		config:  config,
		metrics: metrics,
		logger:  logging.GetLogger(),
		stopCh:  make(chan struct{}),
		cluster: cluster,
	}, nil
}

// Start begins the IoT publisher
func (p *Publisher) Start() error {
	if !p.config.Enabled {
		p.logger.Info("IoT publisher disabled")
		return nil
	}

	if err := p.connect(); err != nil {
		return fmt.Errorf("failed to connect to IoT: %w", err)
	}

	p.wg.Add(1)
	go p.publishLoop()

	p.logger.Info("IoT publisher started, publishing to %s every %v", p.config.Endpoint, p.config.MetricsInterval)
	return nil
}

// Stop gracefully stops the publisher
func (p *Publisher) Stop() {
	close(p.stopCh)
	p.wg.Wait()

	p.mu.Lock()
	defer p.mu.Unlock()

	if p.client != nil && p.client.IsConnected() {
		p.client.Disconnect(250)
	}
	p.logger.Info("IoT publisher stopped")
}

// connect establishes the MQTT connection to AWS IoT Core
func (p *Publisher) connect() error {
	tlsConfig, err := p.newTLSConfig()
	if err != nil {
		return fmt.Errorf("failed to create TLS config: %w", err)
	}

	broker := fmt.Sprintf("ssl://%s:%d", p.config.Endpoint, p.config.Port)

	opts := mqtt.NewClientOptions()
	opts.AddBroker(broker)
	opts.SetClientID(p.config.ClientID)
	opts.SetTLSConfig(tlsConfig)
	opts.SetKeepAlive(30 * time.Second)   // Reduced from 60s for more reliable keepalive
	opts.SetPingTimeout(10 * time.Second) // Timeout for ping responses
	opts.SetConnectTimeout(DefaultConnectTimeout)
	opts.SetAutoReconnect(true)
	opts.SetMaxReconnectInterval(30 * time.Second)
	opts.SetConnectRetry(true) // Retry initial connection
	opts.SetCleanSession(true)

	opts.SetConnectionLostHandler(func(client mqtt.Client, err error) {
		p.logger.Warn("IoT connection lost: %v", err)
	})

	opts.SetOnConnectHandler(func(client mqtt.Client) {
		p.logger.Info("Connected to AWS IoT Core")
	})

	opts.SetReconnectingHandler(func(client mqtt.Client, opts *mqtt.ClientOptions) {
		p.logger.Info("Reconnecting to AWS IoT Core...")
	})

	p.mu.Lock()
	p.client = mqtt.NewClient(opts)
	p.mu.Unlock()

	token := p.client.Connect()
	if !token.WaitTimeout(DefaultConnectTimeout) {
		return fmt.Errorf("connection timeout")
	}
	if token.Error() != nil {
		return token.Error()
	}

	return nil
}

// newTLSConfig creates the TLS configuration for AWS IoT Core
func (p *Publisher) newTLSConfig() (*tls.Config, error) {
	// Load CA certificate
	caCert, err := os.ReadFile(p.config.CAFile)
	if err != nil {
		return nil, fmt.Errorf("failed to read CA file %s: %w", p.config.CAFile, err)
	}

	caCertPool := x509.NewCertPool()
	if !caCertPool.AppendCertsFromPEM(caCert) {
		return nil, fmt.Errorf("failed to parse CA certificate")
	}

	// Load client certificate and key
	cert, err := tls.LoadX509KeyPair(p.config.CertFile, p.config.KeyFile)
	if err != nil {
		return nil, fmt.Errorf("failed to load client certificate: %w", err)
	}

	return &tls.Config{
		RootCAs:      caCertPool,
		Certificates: []tls.Certificate{cert},
		MinVersion:   tls.VersionTLS12,
	}, nil
}

// publishLoop periodically publishes metrics
func (p *Publisher) publishLoop() {
	defer p.wg.Done()

	ticker := time.NewTicker(p.config.MetricsInterval)
	defer ticker.Stop()

	// Publish immediately on start
	p.publishMetrics()

	for {
		select {
		case <-p.stopCh:
			return
		case <-ticker.C:
			p.publishMetrics()
		}
	}
}

// publishMetrics collects and publishes current metrics
func (p *Publisher) publishMetrics() {
	p.mu.RLock()
	client := p.client
	p.mu.RUnlock()

	if client == nil || !client.IsConnected() {
		p.logger.Warn("IoT client not connected, skipping publish")
		return
	}

	payload := p.buildMetricsPayload()

	data, err := json.Marshal(payload)
	if err != nil {
		p.logger.Error("Failed to marshal metrics: %v", err)
		return
	}

	topic := p.getMetricsTopic()
	if !p.cluster.IsLocalNodePrimary() {
		return // Only primary node should publish metrics
	}
	token := client.Publish(topic, byte(DefaultPublishQoS), false, data)
	if !token.WaitTimeout(DefaultPublishTimeout) {
		p.logger.Error("Publish timeout for topic %s", topic)
		return
	}

	if token.Error() != nil {
		p.logger.Error("Failed to publish metrics: %v", token.Error())
		return
	}

	p.logger.Debug("Published metrics to %s", topic)
}

// buildMetricsPayload creates the metrics payload from the collector
func (p *Publisher) buildMetricsPayload() MetricsPayload {
	status := "ok"

	// Get metrics from the collector if available
	if p.metrics != nil {
		sysMetrics := p.metrics.GetSystemMetrics()
		clusterInfo := p.metrics.GetClusterInfo()

		// Determine status based on health
		if sysMetrics.NodeHealth.Status != "ALIVE" || clusterInfo.ClusterHealth < 50 {
			status = "degraded"
		}

		return MetricsPayload{
			Timestamp:        time.Now().UTC().Format(time.RFC3339),
			DeviceID:         p.config.ClientID,
			Status:           status,
			CPUUsage:         sysMetrics.CPUUsage,
			MemoryUsage:      sysMetrics.MemoryUsage,
			Goroutines:       sysMetrics.Goroutines,
			WebSocketClients: sysMetrics.WebSocketClients,
			ClusterMembers:   clusterInfo.MemberCount,
			ClusterHealth:    clusterInfo.ClusterHealth,
			HAProxyStatus:    sysMetrics.HAProxyStatus,
			UptimeSeconds:    sysMetrics.NodeHealth.UptimeSeconds,
		}
	}

	// Fallback if metrics collector is not available
	return MetricsPayload{
		Timestamp: time.Now().UTC().Format(time.RFC3339),
		DeviceID:  p.config.ClientID,
		Status:    status,
	}
}

// getMetricsTopic returns the topic for system metrics
func (p *Publisher) getMetricsTopic() string {
	return fmt.Sprintf("%s%s/system", p.config.TopicPrefix, p.config.ClientID)
}

// Publish sends a custom message to a specific topic
func (p *Publisher) Publish(topic string, payload interface{}) error {
	p.mu.RLock()
	client := p.client
	p.mu.RUnlock()

	if client == nil || !client.IsConnected() {
		return fmt.Errorf("client not connected")
	}

	data, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %w", err)
	}

	fullTopic := fmt.Sprintf("%s%s/%s", p.config.TopicPrefix, p.config.ClientID, topic)
	token := client.Publish(fullTopic, byte(DefaultPublishQoS), false, data)

	if !token.WaitTimeout(DefaultPublishTimeout) {
		return fmt.Errorf("publish timeout")
	}

	return token.Error()
}

// IsConnected returns true if the client is connected
func (p *Publisher) IsConnected() bool {
	p.mu.RLock()
	defer p.mu.RUnlock()

	return p.client != nil && p.client.IsConnected()
}
