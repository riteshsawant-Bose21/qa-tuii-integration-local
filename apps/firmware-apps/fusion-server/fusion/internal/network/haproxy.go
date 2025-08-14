package network

import (
	"bufio"
	"fmt"
	"net"
	"strconv"
	"strings"
	"sync"
	"time"
)

const HAProxyConfigPath = "/etc/haproxy/haproxy.cfg"

// HAProxyStats represents HAProxy server statistics
type HAProxyStats struct {
	Timestamp     time.Time        `json:"timestamp"`
	FrontendStats map[string]Stats `json:"frontend_stats"`
	BackendStats  map[string]Stats `json:"backend_stats"`
	ServerStats   map[string]Stats `json:"server_stats"`
	TotalRequests int64            `json:"total_requests"`
	BytesIn       int64            `json:"bytes_in"`
	BytesOut      int64            `json:"bytes_out"`
	CurrentConns  int              `json:"current_conns"`
	Status        string           `json:"status"`
}

// Stats represents metrics for a single HAProxy entity
type Stats struct {
	Name            string `json:"name"`
	Status          string `json:"status"`
	Weight          int    `json:"weight"`
	ActiveServers   int    `json:"active_servers"`
	BackupServers   int    `json:"backup_servers"`
	SessionsCurrent int    `json:"sessions_current"`
	SessionsTotal   int64  `json:"sessions_total"`
	BytesIn         int64  `json:"bytes_in"`
	BytesOut        int64  `json:"bytes_out"`
	RequestRate     int    `json:"request_rate"`
	ErrorConnects   int    `json:"error_connects"`
	ErrorResp       int    `json:"error_resp"`
	StatusCode2xx   int64  `json:"status_2xx"`
	StatusCode4xx   int64  `json:"status_4xx"`
	StatusCode5xx   int64  `json:"status_5xx"`
	LastCheck       string `json:"last_check"`
}

// HAProxyMetrics manages HAProxy metrics collection
type HAProxyMetrics struct {
	socketPath string
	configPath string
	mutex      sync.RWMutex
	stats      HAProxyStats
}

func NewHAProxyMetrics(socketPath, configPath string) *HAProxyMetrics {
	hm := &HAProxyMetrics{
		socketPath: socketPath,
		configPath: configPath,
		stats: HAProxyStats{
			FrontendStats: make(map[string]Stats),
			BackendStats:  make(map[string]Stats),
			ServerStats:   make(map[string]Stats),
		},
	}

	go hm.collect()
	return hm
}

// GetStats returns the current HAProxy stats
func (hm *HAProxyMetrics) GetStats() HAProxyStats {
	hm.mutex.RLock()
	defer hm.mutex.RUnlock()
	return hm.stats
}

func (hm *HAProxyMetrics) collect() {
	ticker := time.NewTicker(10 * time.Second)
	for range ticker.C {
		stats, err := hm.fetchStats()
		if err != nil {
			continue
		}

		hm.mutex.Lock()
		hm.stats = stats
		hm.mutex.Unlock()
	}
}

func (hm *HAProxyMetrics) fetchStats() (HAProxyStats, error) {
	conn, err := net.Dial("unix", hm.socketPath)
	if err != nil {
		return HAProxyStats{}, fmt.Errorf("failed to connect to HAProxy socket %s: %v", hm.socketPath, err)
	}
	defer conn.Close()

	// Send stats command
	_, err = fmt.Fprint(conn, "show stat\n")
	if err != nil {
		return HAProxyStats{}, fmt.Errorf("failed to send command to HAProxy socket: %v", err)
	}

	stats := HAProxyStats{
		Timestamp:     time.Now(),
		FrontendStats: make(map[string]Stats),
		BackendStats:  make(map[string]Stats),
		ServerStats:   make(map[string]Stats),
	}

	scanner := bufio.NewScanner(conn)
	first := true
	var headers []string

	for scanner.Scan() {
		line := scanner.Text()
		if line == "" {
			continue
		}

		fields := strings.Split(line, ",")
		if first {
			headers = fields
			first = false
			continue
		}

		values := make(map[string]string)
		for i, field := range fields {
			if i < len(headers) {
				values[headers[i]] = field
			}
		}

		switch values["svname"] {
		case "FRONTEND":
			pxName := values["pxname"]
			stats.FrontendStats[pxName] = parseProxyStats(values)
			stats.TotalRequests += parseInt64(values["req_tot"])
			stats.BytesIn += parseInt64(values["bin"])
			stats.BytesOut += parseInt64(values["bout"])
			stats.CurrentConns += parseInt(values["scur"])
		case "BACKEND":
			stats.BackendStats[values["pxname"]] = parseProxyStats(values)
		default:
			stats.ServerStats[values["svname"]] = parseProxyStats(values)
		}
	}

	if err := scanner.Err(); err != nil {
		return HAProxyStats{}, fmt.Errorf("error reading HAProxy stats: %v", err)
	}

	return stats, nil
}

// parseProxyStats uses keys are extracted from the HAProxy show stat CSV output from the stats socket
func parseProxyStats(values map[string]string) Stats {
	return Stats{
		Name:            values["svname"],
		Status:          values["status"],
		Weight:          parseInt(values["weight"]),
		ActiveServers:   parseInt(values["act"]),
		BackupServers:   parseInt(values["bck"]),
		SessionsCurrent: parseInt(values["scur"]),
		SessionsTotal:   parseInt64(values["stot"]),
		BytesIn:         parseInt64(values["bin"]),
		BytesOut:        parseInt64(values["bout"]),
		RequestRate:     parseInt(values["req_rate"]),
		ErrorConnects:   parseInt(values["econ"]),
		ErrorResp:       parseInt(values["eresp"]),
		StatusCode2xx:   parseInt64(values["hrsp_2xx"]),
		StatusCode4xx:   parseInt64(values["hrsp_4xx"]),
		StatusCode5xx:   parseInt64(values["hrsp_5xx"]),
		LastCheck:       values["check_status"],
	}
}

func parseInt(s string) int {
	v, _ := strconv.Atoi(s)
	return v
}

func parseInt64(s string) int64 {
	v, _ := strconv.ParseInt(s, 10, 64)
	return v
}
