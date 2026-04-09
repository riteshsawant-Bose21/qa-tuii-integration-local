package cluster

import (
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"runtime"
	"strings"
	"sync"
	"time"

	json "github.com/goccy/go-json"

	"fusion/internal/api"
	"fusion/internal/network"
	"fusion/internal/persistence"

	"github.com/hashicorp/memberlist"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

const (
	collectInterval   = 15 * time.Second
	haproxySocketPath = "/var/run/haproxy.sock"
)

// MetricsCollector handles system-wide metric collection
type MetricsCollector struct {
	memberlist        *memberlist.Memberlist
	stateManager      persistence.StateManagerInterface
	mutex             sync.RWMutex
	metrics           SystemMetrics
	wsConnCount       int
	clusterInfo       ClusterInfo
	haproxyMetrics    *network.HAProxyMetrics
	cpuGauge          prometheus.Gauge
	memGauge          prometheus.Gauge
	goroutinesGauge   prometheus.Gauge
	wsClientsGauge    prometheus.Gauge
	haproxyConnsGauge prometheus.Gauge
	httpReqCounter    prometheus.Counter
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
	ConfigState    map[string]string `json:"config_state"`
	ValueTypes     map[string]int    `json:"value_types"`

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
	HAProxy       struct {
		Status        string                   `json:"status"`
		TotalRequests int64                    `json:"total_requests"`
		CurrentConns  int                      `json:"current_conns"`
		BytesIn       int64                    `json:"bytes_in"`
		BytesOut      int64                    `json:"bytes_out"`
		FrontendStats map[string]network.Stats `json:"frontend_stats"`
		BackendStats  map[string]network.Stats `json:"backend_stats"`
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

func NewMetricsCollector(memberlist *memberlist.Memberlist, stateManager *persistence.StateManager) *MetricsCollector {
	mc := &MetricsCollector{
		memberlist:     memberlist,
		stateManager:   stateManager,
		haproxyMetrics: network.NewHAProxyMetrics(haproxySocketPath, network.HAProxyConfigPath),

		cpuGauge: promauto.NewGauge(prometheus.GaugeOpts{
			Name: "fusion_process_cpu_percent",
			Help: "CPU usage percent of this process",
		}),
		memGauge: promauto.NewGauge(prometheus.GaugeOpts{
			Name: "fusion_process_memory_bytes",
			Help: "Memory in use by this process (bytes)",
		}),
		goroutinesGauge: promauto.NewGauge(prometheus.GaugeOpts{
			Name: "fusion_go_goroutines",
			Help: "Number of Go routines",
		}),
		// Websocket client count
		wsClientsGauge: promauto.NewGauge(prometheus.GaugeOpts{
			Name: "fusion_websocket_clients",
			Help: "Current number of WebSocket clients connected",
		}),
		// HAProxy metrics (as gauges)
		haproxyConnsGauge: promauto.NewGauge(prometheus.GaugeOpts{
			Name: "fusion_haproxy_current_connections",
			Help: "Current HAProxy connections",
		}),
		// HTTP request rate as a counter
		httpReqCounter: promauto.NewCounter(prometheus.CounterOpts{
			Name: "fusion_http_requests_total",
			Help: "Total HTTP requests served",
		}),
	}

	go mc.collect()
	go mc.monitorCluster()

	return mc
}

func (mc *MetricsCollector) SetMemberlist(memberlist *memberlist.Memberlist) {
	mc.memberlist = memberlist
}

func (mc *MetricsCollector) collect() {

	ticker := time.NewTicker(collectInterval)
	defer ticker.Stop()

	for range ticker.C {
		// Gather raw stats
		var mem runtime.MemStats
		runtime.ReadMemStats(&mem)
		cpu := mc.getCPUUsage()
		gs := runtime.NumGoroutine()
		ws := mc.wsConnCount

		// Populate JSON-backed metrics struct
		state := mc.stateManager.GetFullState().State
		stateSummary := make(map[string]string, len(state))
		valueTypes := make(map[string]int)
		for k, v := range state {
			if v != nil {
				t := fmt.Sprintf("%T", v.Data)
				stateSummary[k] = t
				valueTypes[t]++
			} else {
				stateSummary[k] = "nil"
				valueTypes["nil"]++
			}
		}

		haproxyStats := mc.haproxyMetrics.GetStats()

		mc.mutex.Lock()
		mc.metrics = SystemMetrics{
			Timestamp:        time.Now(),
			Cluster:          mc.clusterInfo,
			NodeHealth:       mc.metrics.NodeHealth,
			ConfigKeys:       len(state),
			ConfigVersion:    time.Now().UnixNano(),
			LastUpdateTime:   time.Now(),
			ConfigState:      stateSummary,
			ValueTypes:       valueTypes,
			WebSocketClients: ws,
			CPUUsage:         cpu,
			MemoryUsage:      int64(mem.Alloc),
			Goroutines:       gs,
			HAProxyStatus:    mc.checkHAProxy(),
			BackendNodes:     len(mc.memberlist.Members()),

			HAProxy: struct {
				Status        string                   `json:"status"`
				TotalRequests int64                    `json:"total_requests"`
				CurrentConns  int                      `json:"current_conns"`
				BytesIn       int64                    `json:"bytes_in"`
				BytesOut      int64                    `json:"bytes_out"`
				FrontendStats map[string]network.Stats `json:"frontend_stats"`
				BackendStats  map[string]network.Stats `json:"backend_stats"`
				ServerStats   map[string]network.Stats `json:"server_stats"`
			}{
				Status:        haproxyStats.Status,
				TotalRequests: haproxyStats.TotalRequests,
				CurrentConns:  haproxyStats.CurrentConns,
				BytesIn:       haproxyStats.BytesIn,
				BytesOut:      haproxyStats.BytesOut,
				FrontendStats: haproxyStats.FrontendStats,
				BackendStats:  haproxyStats.BackendStats,
				ServerStats:   haproxyStats.ServerStats,
			},
		}
		mc.mutex.Unlock()

		// Prometheus metrics protect them selves. We don't need to lock.
		mc.memGauge.Set(float64(mem.Alloc))
		mc.cpuGauge.Set(cpu)
		mc.goroutinesGauge.Set(float64(gs))
		mc.wsClientsGauge.Set(float64(ws))
		mc.haproxyConnsGauge.Set(float64(haproxyStats.CurrentConns))

	}
}

func (mc *MetricsCollector) GetMetrics(w http.ResponseWriter, r *http.Request) {

	promhttp.Handler().ServeHTTP(w, r)

	// mc.mutex.RLock()
	// defer mc.mutex.RUnlock()

	// w.Header().Set(api.ContentType, api.JsonMIMEType)
	// json.NewEncoder(w).Encode(mc.metrics)
}

func (mc *MetricsCollector) GetClusterStatus(w http.ResponseWriter, r *http.Request) {
	mc.mutex.RLock()
	defer mc.mutex.RUnlock()

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(mc.clusterInfo)
}

func (mc *MetricsCollector) GetHealthCheck(w http.ResponseWriter, r *http.Request) {
	type healthCheckResponse struct {
		Status        string     `json:"status"`
		NodeHealth    NodeHealth `json:"node_health"`
		ClusterHealth float64    `json:"cluster_health"`
	}

	mc.mutex.RLock()
	health := mc.metrics.NodeHealth
	clusterHealth := mc.clusterInfo.ClusterHealth
	mc.mutex.RUnlock()

	status := "healthy"
	if clusterHealth < 50 || health.Status != "ALIVE" {
		status = "unhealthy"
		w.WriteHeader(http.StatusServiceUnavailable)
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(healthCheckResponse{
		Status:        status,
		NodeHealth:    health,
		ClusterHealth: clusterHealth,
	})
}

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
		members := mc.memberlist.Members()
		clusterMembers := make([]ClusterMember, len(members))
		aliveCount := 0
		suspectCount := 0
		deadCount := 0

		for i, member := range members {
			clusterMembers[i] = ClusterMember{
				Name:    member.Name,
				Address: member.Addr.String(),
				Port:    member.Port,
				State:   GetStateString(member.State),
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
			LocalNode:      mc.memberlist.LocalNode().Name,
			Members:        clusterMembers,
			LastUpdateTime: time.Now().UTC(),
			SuspectNodes:   suspectCount,
			DeadNodes:      deadCount,
			ClusterHealth:  float64(aliveCount) / float64(len(members)) * 100,
			AvgPingLatency: mc.calculateAvgPingLatency(),
		}

		mc.metrics.NodeHealth = NodeHealth{
			Status:           GetStateString(memberlist.StateAlive),
			LastHeartbeat:    time.Now(),
			UptimeSeconds:    int64(time.Since(startTime).Seconds()),
			StartTime:        startTime,
			HealthCheckCount: healthCheckCount,
		}

		mc.mutex.Unlock()
	}
}

func (mc *MetricsCollector) calculateAvgPingLatency() float64 {
	return 0.0 // Implementation needed
}

func (mc *MetricsCollector) checkHAProxy() string {
	cmd := exec.Command("systemctl", "status", "haproxy")
	if err := cmd.Run(); err != nil {
		return "stopped"
	}
	return "running"
}

func (mc *MetricsCollector) getCPUUsage() float64 {
	cmd := exec.Command("ps", "-p", fmt.Sprintf("%d", mc.getPID()), "-o", "%cpu")
	output, err := cmd.Output()
	if err != nil {
		return 0
	}
	lines := strings.Split(string(output), "\n")
	if len(lines) < 2 {
		return 0
	}
	var cpu float64
	fmt.Sscanf(strings.TrimSpace(lines[1]), "%f", &cpu)
	return cpu
}

func (mc *MetricsCollector) getPID() int {
	return os.Getpid()
}
