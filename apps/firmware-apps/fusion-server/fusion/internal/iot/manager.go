package fusioniot

import (
	"fusion-services-core/logging"
	"fusion/internal/cluster"
	"fusion/internal/persistence"
)

// Manager consolidates IoT client, publisher, and subscriber into a single manager.
type Manager struct {
	config     *Config
	client     *Client
	publisher  *Publisher
	subscriber *Subscriber
	logger     *logging.Logger
}

// NewManager creates a new IoT manager with all components.
// Returns nil if IoT is disabled or not properly configured.
func NewManager(config *Config, metrics *cluster.MetricsCollector, clusterInstance *cluster.Cluster, persistence *persistence.Persistence) *Manager {
	logger := logging.GetLogger()

	if config == nil || !config.Enabled {
		logger.Info("IoT disabled")
		return nil
	}

	if config.Endpoint == "" {
		logger.Warn("IoT endpoint not configured, disabling IoT")
		return nil
	}

	// Create the shared client
	client, err := NewClient(config)
	if err != nil {
		logger.Error("Failed to create IoT client: %v", err)
		return nil
	}
	logger.Info("IoT client initialized for endpoint: %s", config.Endpoint)

	// Create publisher
	publisher, err := NewPublisher(client, metrics, clusterInstance)
	if err != nil {
		logger.Error("Failed to create IoT publisher: %v", err)
		return nil
	}
	logger.Info("IoT publisher initialized")

	// Create subscriber (if project ID is configured)
	var subscriber *Subscriber
	if config.ProjectID != "" {
		subscriber, err = NewSubscriber(client, clusterInstance, persistence)
		if err != nil {
			logger.Error("Failed to create IoT subscriber: %v", err)
			// Continue without subscriber - publishing can still work
		} else {
			// Wire up publisher to subscriber for command responses
			subscriber.SetPublisher(publisher)
			logger.Info("IoT subscriber initialized for project: %s", config.ProjectID)
		}
	} else {
		logger.Warn("Project ID not configured, IoT subscriber will not be able to subscribe to commands")
	}

	return &Manager{
		config:     config,
		client:     client,
		publisher:  publisher,
		subscriber: subscriber,
		logger:     logger,
	}
}

// Start starts all IoT components (client, publisher, subscriber).
func (m *Manager) Start() error {
	if m == nil {
		return nil
	}

	// Start the shared client first
	if err := m.client.Start(); err != nil {
		return err
	}

	// Start publisher
	if m.publisher != nil {
		if err := m.publisher.Start(); err != nil {
			m.logger.Error("Failed to start IoT publisher: %v", err)
		}
	}

	// Start subscriber
	if m.subscriber != nil {
		if err := m.subscriber.Start(); err != nil {
			m.logger.Error("Failed to start IoT subscriber: %v", err)
		}
	}

	m.logger.Info("IoT manager started")
	return nil
}

// Stop gracefully stops all IoT components in the correct order.
func (m *Manager) Stop() {
	if m == nil {
		return
	}

	// Stop subscriber first
	if m.subscriber != nil {
		m.subscriber.Stop()
	}

	// Stop publisher
	if m.publisher != nil {
		m.publisher.Stop()
	}

	// Stop the shared client last
	if m.client != nil {
		m.client.Stop()
	}

	m.logger.Info("IoT manager stopped")
}

// Client returns the underlying IoT client.
func (m *Manager) Client() *Client {
	if m == nil {
		return nil
	}
	return m.client
}

// Publisher returns the IoT publisher.
func (m *Manager) Publisher() *Publisher {
	if m == nil {
		return nil
	}
	return m.publisher
}

// Subscriber returns the IoT subscriber.
func (m *Manager) Subscriber() *Subscriber {
	if m == nil {
		return nil
	}
	return m.subscriber
}

// IsConnected returns true if the IoT client is connected.
func (m *Manager) IsConnected() bool {
	if m == nil || m.client == nil {
		return false
	}
	return m.client.IsConnected()
}

// IsEnabled returns true if IoT is enabled.
func (m *Manager) IsEnabled() bool {
	return m != nil && m.config != nil && m.config.Enabled
}
