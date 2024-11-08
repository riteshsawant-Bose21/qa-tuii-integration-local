package cluster

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os/exec"
	"runtime"
	"sync"
	"time"

	"fusion/internal/api"
	"fusion/internal/network"

	"github.com/hashicorp/memberlist"
)

// StateManagerInterface defines the interface for state management
type StateManagerInterface interface {
	GetFullState() map[string]*api.StateEntry
}

// MetricsCollector handles system-wide metric collection
type MetricsCollector struct {
	list           *memberlist.Memberlist
	stateManager   StateManagerInterface
	mutex          sync.RWMutex
	metrics        SystemMetrics
	wsConnCount    int
	clusterInfo    ClusterInfo
	haproxyMetrics *network.HAProxyMetrics
}

// SystemMetrics represents the complete system state
type SystemMetrics struct {
	Timestamp time.Time `json:"timestamp"`

	// Cluster metrics
	Cluster    ClusterInfo `json:"cluster"`
	NodeHealth NodeHealth  `json:"node_health"`

	// State metrics
	ConfigKeys     int               `json:"config_keys"`
	ConfigVersion  int64             `json:"config_version"`
	LastUpdateTime time.Time         `json:"last_update_time"`
	ConfigState    map[string]string `json:"config_state"` // Summary of config state
	ValueTypes     map[string]int    `json:"value_types"`  // Count of different value types

	// Network metrics
	WebSocketClients int     `json:"websocket_clients"`
	HTTPRequestRate  float64 `json:"http_request_rate"`
	UDPMessageRate   float64 `json:"udp_message_rate"`

	// Process metrics
	CPUUsage    float64 `json:"cpu_usage"`
	MemoryUsage int64   `json:"memory_usage"`
	Goroutines  int     `json:"goroutines"`

	// HAProxy metrics
	HAProxyStatus string `json:"haproxy_status"`
	BackendNodes  int    `json:"backend_nodes"`

	// HAProxy metrics
	HAProxy struct {
		Status        string                   `json:"status"`
		TotalRequests int64                    `json:"total_requests"`
		CurrentConns  int                      `json:"current_conns"`
		BytesIn       int64                    `json:"bytes_in"`
		BytesOut      int64                    `json:"bytes_out"`
		FrontendStats map[string]network.Stats `json:"frontend_stats"`
		BackendStats  map[string]network.Stats `json:"backend_network.Stats"`
		ServerStats   map[string]network.Stats `json:"server_stats"`
	} `json:"haproxy"`
}

// NodeHealth represents health metrics for a single node
type NodeHealth struct {
	Status           string    `json:"status"`
	LastHeartbeat    time.Time `json:"last_heartbeat"`
	UptimeSeconds    int64     `json:"uptime_seconds"`
	StartTime        time.Time `json:"start_time"`
	HealthCheckCount int64     `json:"health_check_count"`
}

// NewMetricsCollector creates a new metrics collector
func NewMetricsCollector(list *memberlist.Memberlist, stateManager StateManagerInterface) *MetricsCollector {
	mc := &MetricsCollector{
		list:           list,
		stateManager:   stateManager,
		haproxyMetrics: network.NewHAProxyMetrics("/var/run/haproxy.sock"),
	}

	// Start periodic collection
	go mc.collect()

	// Start cluster monitoring
	go mc.monitorCluster()

	return mc
}

func (mc *MetricsCollector) collect() {
	ticker := time.NewTicker(15 * time.Second)
	for range ticker.C {
		mc.mutex.Lock()

		// Get process stats
		var mem runtime.MemStats
		runtime.ReadMemStats(&mem)

		// Get state and convert to summary
		state := mc.stateManager.GetFullState()
		stateSummary := make(map[string]string)
		valueTypes := make(map[string]int)

		for k, v := range state {
			// Convert complex values to type summaries
			if v != nil {
				valueType := fmt.Sprintf("%T", v.Value)
				stateSummary[k] = valueType
				valueTypes[valueType]++
			} else {
				stateSummary[k] = "nil"
				valueTypes["nil"]++
			}
		}

		mc.metrics = SystemMetrics{
			Timestamp:  time.Now(),
			Cluster:    mc.clusterInfo,
			NodeHealth: mc.metrics.NodeHealth,

			ConfigKeys:     len(state),
			ConfigVersion:  time.Now().UnixNano(), // Replace with actual version
			LastUpdateTime: time.Now(),
			ConfigState:    stateSummary,
			ValueTypes:     valueTypes,

			WebSocketClients: mc.wsConnCount,
			CPUUsage:         mc.getCPUUsage(),
			MemoryUsage:      int64(mem.Alloc),
			Goroutines:       runtime.NumGoroutine(),

			HAProxyStatus: mc.checkHAProxy(),
			BackendNodes:  len(mc.list.Members()),
		}

		// Get HAProxy stats
		haproxyStats := mc.haproxyMetrics.GetStats()
		mc.metrics.HAProxy.Status = haproxyStats.Status
		mc.metrics.HAProxy.TotalRequests = haproxyStats.TotalRequests
		mc.metrics.HAProxy.CurrentConns = haproxyStats.CurrentConns
		mc.metrics.HAProxy.BytesIn = haproxyStats.BytesIn
		mc.metrics.HAProxy.BytesOut = haproxyStats.BytesOut
		mc.metrics.HAProxy.FrontendStats = haproxyStats.FrontendStats
		mc.metrics.HAProxy.BackendStats = haproxyStats.BackendStats
		mc.metrics.HAProxy.ServerStats = haproxyStats.ServerStats

		mc.mutex.Unlock()
	}
}

// HandleMetrics handles the /metrics endpoint
func (mc *MetricsCollector) HandleMetrics(w http.ResponseWriter, r *http.Request) {
	mc.mutex.RLock()
	defer mc.mutex.RUnlock()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(mc.metrics)
}

// HandleClusterStatus handles the /cluster/status endpoint
func (mc *MetricsCollector) HandleClusterStatus(w http.ResponseWriter, r *http.Request) {
	mc.mutex.RLock()
	defer mc.mutex.RUnlock()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(mc.clusterInfo)
}

// HandleHealthCheck handles the /health endpoint
func (mc *MetricsCollector) HandleHealthCheck(w http.ResponseWriter, r *http.Request) {
	mc.mutex.RLock()
	health := mc.metrics.NodeHealth
	clusterHealth := mc.clusterInfo.ClusterHealth
	mc.mutex.RUnlock()

	status := "healthy"
	if clusterHealth < 50 || health.Status != "ALIVE" {
		status = "unhealthy"
		w.WriteHeader(http.StatusServiceUnavailable)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":         status,
		"node_health":    health,
		"cluster_health": clusterHealth,
	})
}

// UpdateWSCount updates the WebSocket client count
func (mc *MetricsCollector) UpdateWSCount(delta int) {
	mc.mutex.Lock()
	defer mc.mutex.Unlock()
	mc.wsConnCount += delta
}

func (mc *MetricsCollector) monitorCluster() {
	ticker := time.NewTicker(5 * time.Second)
	startTime := time.Now()
	var healthCheckCount int64

	for range ticker.C {
		mc.mutex.Lock()

		members := mc.list.Members()
		clusterMembers := make([]ClusterMember, len(members))
		aliveCount := 0
		suspectCount := 0
		deadCount := 0

		for i, member := range members {
			clusterMembers[i] = ClusterMember{
				Name:    member.Name,
				Address: member.Addr.String(),
				Port:    member.Port,
				State:   getStateString(member.State),
			}

			switch member.State {
			case memberlist.StateAlive:
				aliveCount++
			case memberlist.StateSuspect:
				suspectCount++
			case memberlist.StateDead:
				deadCount++
			}
		}

		healthCheckCount++

		mc.clusterInfo = ClusterInfo{
			MemberCount:    len(members),
			AliveCount:     aliveCount,
			LocalNode:      mc.list.LocalNode().Name,
			Members:        clusterMembers,
			LastUpdateTime: time.Now().UTC(),
			SuspectNodes:   suspectCount,
			DeadNodes:      deadCount,
			ClusterHealth:  float64(aliveCount) / float64(len(members)) * 100,
			AvgPingLatency: mc.calculateAvgPingLatency(),
		}

		mc.metrics.NodeHealth = NodeHealth{
			Status:           getStateString(memberlist.StateAlive),
			LastHeartbeat:    time.Now(),
			UptimeSeconds:    int64(time.Since(startTime).Seconds()),
			StartTime:        startTime,
			HealthCheckCount: healthCheckCount,
		}

		mc.mutex.Unlock()
	}
}

func (mc *MetricsCollector) calculateAvgPingLatency() float64 {
	return 0.0 // Implement actual ping measurement
}

func (mc *MetricsCollector) checkHAProxy() string {
	cmd := exec.Command("systemctl", "status", "haproxy")
	if err := cmd.Run(); err != nil {
		return "stopped"
	}
	return "running"
}

func (mc *MetricsCollector) getCPUUsage() float64 {
	var cpu float64
	cmd := exec.Command("ps", "-p", fmt.Sprintf("%d", mc.getPID()), "-o", "%cpu")
	output, err := cmd.Output()
	if err == nil {
		fmt.Sscanf(string(output), "%f", &cpu)
	}
	return cpu
}

func (mc *MetricsCollector) getPID() int {
	return 0 // Implement actual PID retrieval
}
