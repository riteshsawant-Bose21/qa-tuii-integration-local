package fusioniot

import (
	"fmt"
	"sync"
	"time"

	json "github.com/goccy/go-json"

	"fusion-services-core/logging"
	"fusion/internal/cluster"
)

const (
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
	// TopicPrefix is the prefix for MQTT topics (e.g., "cluster/")
	TopicPrefix string
	// ProjectID is the project ID for command subscription topic
	ProjectID string
	// MetricsInterval is how often to publish metrics
	MetricsInterval time.Duration
	// Enabled determines if IoT publishing is active
	Enabled bool
}

// Publisher handles publishing metrics to AWS IoT Core
type Publisher struct {
	config  *Config
	client  *Client
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

// NewPublisher creates a new IoT publisher that uses a shared client
func NewPublisher(client *Client, metrics *cluster.MetricsCollector, cluster *cluster.Cluster) (*Publisher, error) {
	if client == nil {
		return nil, fmt.Errorf("client cannot be nil")
	}

	config := client.GetConfig()
	if config.MetricsInterval == 0 {
		config.MetricsInterval = DefaultMetricsInterval
	}

	return &Publisher{
		config:  config,
		client:  client,
		metrics: metrics,
		logger:  logging.GetLogger(),
		stopCh:  make(chan struct{}),
		cluster: cluster,
	}, nil
}

// Start begins the IoT publisher metrics loop
func (p *Publisher) Start() error {
	if !p.config.Enabled {
		p.logger.Info("IoT publisher disabled")
		return nil
	}

	p.wg.Add(1)
	go p.metricsLoop()

	p.logger.Info("IoT publisher started")
	return nil
}

// metricsLoop periodically publishes metrics
func (p *Publisher) metricsLoop() {
	defer p.wg.Done()

	metricsTicker := time.NewTicker(p.config.MetricsInterval)
	defer metricsTicker.Stop()

	for {
		select {
		case <-p.stopCh:
			return
		case <-metricsTicker.C:
			p.publishMetrics()
		}
	}
}

// Stop gracefully stops the publisher
func (p *Publisher) Stop() {
	close(p.stopCh)
	p.wg.Wait()
	p.logger.Info("IoT publisher stopped")
}

// publishMetrics collects and publishes current metrics
func (p *Publisher) publishMetrics() {
	if !p.client.IsConnected() {
		return
	}

	// Only primary node should publish metrics
	if !p.cluster.IsLocalNodePrimary() {
		return
	}

	payload := p.buildMetricsPayload()

	data, err := json.Marshal(payload)
	if err != nil {
		p.logger.Error("Failed to marshal metrics: %v", err)
		return
	}

	topic := p.getMetricsTopic()
	if err := p.client.Publish(topic, byte(DefaultPublishQoS), false, data); err != nil {
		p.logger.Error("Failed to publish metrics: %v", err)
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
	if !p.client.IsConnected() {
		return fmt.Errorf("client not connected")
	}

	data, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %w", err)
	}

	fullTopic := fmt.Sprintf("%s%s/%s", p.config.TopicPrefix, p.config.ClientID, topic)
	return p.client.Publish(fullTopic, byte(DefaultPublishQoS), false, data)
}

// IsConnected returns true if the client is connected
func (p *Publisher) IsConnected() bool {
	return p.client.IsConnected()
}
