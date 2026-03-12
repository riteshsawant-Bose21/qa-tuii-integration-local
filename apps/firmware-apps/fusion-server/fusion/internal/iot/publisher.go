package fusioniot

import (
	"fmt"
	"net"
	"net/http"
	"sync"
	"time"

	json "github.com/goccy/go-json"

	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/cluster"
	"fusion/internal/persistence"
)

const (
	// MQTT settings
	DefaultPort           = 8883
	DefaultPublishQoS     = 1
	DefaultKeepAlive      = 60 * time.Second
	DefaultConnectTimeout = 30 * time.Second
	DefaultPublishTimeout = 10 * time.Second

	// Publishing intervals
	DefaultMetricsInterval         = 10 * time.Second
	DefaultCommandResponseInterval = 30 * time.Second
)

// Publisher handles publishing metrics and command responses to AWS IoT Core
type Publisher struct {
	config      *api.IoTConfig
	client      *Client
	metrics     *cluster.MetricsCollector
	persistence *persistence.Persistence
	httpClient  *http.Client
	logger      *logging.Logger
	stopCh      chan struct{}
	wg          sync.WaitGroup
	mu          sync.RWMutex
	cluster     *cluster.Cluster
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
func NewPublisher(client *Client, metrics *cluster.MetricsCollector, cluster *cluster.Cluster, p *persistence.Persistence) (*Publisher, error) {
	if client == nil {
		return nil, fmt.Errorf("client cannot be nil")
	}

	config := client.GetConfig()
	if config.MetricsInterval == 0 {
		config.MetricsInterval = DefaultMetricsInterval
	}

	return &Publisher{
		config:      config,
		client:      client,
		metrics:     metrics,
		persistence: p,
		httpClient:  &http.Client{Timeout: api.HTTPTimeout},
		logger:      logging.GetLogger(),
		stopCh:      make(chan struct{}),
		cluster:     cluster,
	}, nil
}

// Start begins the IoT publisher metrics loop
func (p *Publisher) Start() error {
	if !p.config.Enabled {
		p.logger.Info("IoT publisher disabled")
		return nil
	}

	p.wg.Add(2)
	go p.metricsLoop()
	go p.commandResponseLoop()

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

// commandResponseLoop periodically checks for completed commands and sends MQTT responses.
// Only runs meaningful work on the primary node.
func (p *Publisher) commandResponseLoop() {
	defer p.wg.Done()

	ticker := time.NewTicker(DefaultCommandResponseInterval)
	defer ticker.Stop()

	for {
		select {
		case <-p.stopCh:
			return
		case <-ticker.C:
			if p.client.IsConnected() && p.cluster.IsLocalNodePrimary() {
				p.ProcessPendingCommands()
			}
		}
	}
}

// ProcessPendingCommands reads completed remote commands from the local persistence bucket,
// polls the private GetCommandStatus API on each target device, and sends an MQTT response
// once all devices report COMPLETED. Only runs on the primary node.
func (p *Publisher) ProcessPendingCommands() {
	if p.persistence == nil {
		return
	}

	cmds, err := p.persistence.GetCommandsByStatus(persistence.CommandStatusCompleted)
	if err != nil {
		p.logger.Error("ProcessPendingCommands: failed to get completed commands: %v", err)
		return
	}

	devices := p.cluster.GetAllDeviceInfos()

	for _, cmd := range cmds {
		if cmd.Source != persistence.CommandSourceRemoteCommand {
			continue
		}

		if !p.sendPerDeviceResponses(cmd, devices) {
			p.logger.Debug("Command %s: not all devices in terminal state yet, will retry", cmd.ID)
			continue
		}

		// All devices responded — remove from DB
		if err := p.persistence.DeleteCommand(cmd.ID); err != nil {
			p.logger.Error("Failed to delete command %s after response: %v", cmd.ID, err)
		}
	}
}

type deviceCommandResult struct {
	status string
	errMsg string
}

// sendPerDeviceResponses polls each target device for the command status. Once every device
// has reached a terminal state (COMPLETED or FAILED) it publishes one MQTT response per
// device with that device's individual status and returns true. Returns false if any device
// is still pending so the caller retries on the next tick.
func (p *Publisher) sendPerDeviceResponses(cmd persistence.Command, allDevices []persistence.DeviceInfo) bool {
	targets := allDevices
	if len(cmd.DeviceIDArray) > 0 {
		targets = make([]persistence.DeviceInfo, 0, len(cmd.DeviceIDArray))
		for _, dev := range allDevices {
			for _, id := range cmd.DeviceIDArray {
				if dev.Id == id {
					targets = append(targets, dev)
					break
				}
			}
		}
	}

	// First pass: collect terminal status for every device. Bail early if any is still pending.
	results := make([]deviceCommandResult, len(targets))
	for i, dev := range targets {
		status, errMsg := p.queryDeviceCommandStatus(cmd.ID, dev)
		if status == "" {
			return false
		}
		results[i] = deviceCommandResult{status: status, errMsg: errMsg}
	}

	// All devices are in a terminal state — send one response per device.
	for i, dev := range targets {
		p.SendCommandResponse(cmd.ID, cmd.CommandType, results[i].status, dev.Id, results[i].errMsg)
	}
	return true
}

// queryDeviceCommandStatus GETs /commands/{id} on the device's admin port and returns
// the terminal status ("COMPLETED" or "FAILED") and error message, or ("", "") if the
// device has not yet reached a terminal state or is unreachable.
func (p *Publisher) queryDeviceCommandStatus(commandID string, dev persistence.DeviceInfo) (string, string) {
	addr := net.JoinHostPort(dev.Address, api.AdminPort)
	url := fmt.Sprintf("%s%s/commands/%s", api.Protocol, addr, commandID)

	resp, err := p.httpClient.Get(url)
	if err != nil {
		p.logger.Debug("queryDeviceCommandStatus: GET %s failed: %v", url, err)
		return "", ""
	}
	defer resp.Body.Close()

	var result persistence.Command
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", ""
	}

	switch result.Status {
	case persistence.CommandStatusCompleted:
		return string(persistence.CommandStatusCompleted), ""
	case persistence.CommandStatusFailed:
		return string(persistence.CommandStatusFailed), result.ErrorMsg
	default:
		return "", ""
	}
}

// SendCommandResponse publishes a command response payload to the MQTT response topic.
func (p *Publisher) SendCommandResponse(commandID, commandType, status, deviceID, errorMsg string) {
	if !p.client.IsConnected() {
		p.logger.Warn("SendCommandResponse: client not connected, dropping response for %s", commandID)
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

	topic := p.getCommandResponseTopic()
	data, err := json.Marshal(response)
	if err != nil {
		p.logger.Error("SendCommandResponse: failed to marshal response: %v", err)
		return
	}

	if err := p.client.Publish(topic, byte(DefaultPublishQoS), false, data); err != nil {
		p.logger.Error("SendCommandResponse: failed to publish response for %s: %v", commandID, err)
		return
	}

	p.logger.Info("Sent command response for %s: status=%s", commandID, status)
}

// getCommandResponseTopic returns the MQTT topic for command responses.
func (p *Publisher) getCommandResponseTopic() string {
	return fmt.Sprintf("%s%s/command_response", p.config.TopicPrefix, p.config.ProjectID)
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
