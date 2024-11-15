package network

import (
	"bufio"
	"fmt"
	"log"
	"net"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"sync"
	"text/template"
	"time"

	"github.com/hashicorp/memberlist"
)

const haproxyTemplate = `global
    log /dev/log local0
    stats socket /var/run/haproxy.sock mode 600 level admin expose-fd listeners
    stats timeout 2m
    maxconn 4096

defaults
    log global
    mode http
    option httplog
    option dontlognull
    timeout connect 5000
    timeout client 50000
    timeout server 50000

frontend http-in
    bind *:80
    default_backend servers
    
backend servers
    balance roundrobin
	
`

// ManageHAProxy continuously updates HAProxy configuration based on cluster membership
func ManageHAProxy(list *memberlist.Memberlist) {
	tmpl := template.Must(template.New("haproxy").Parse(haproxyTemplate))

	for {
		members := list.Members()
		if err := generateConfig(tmpl, members); err != nil {
			log.Printf("[ERROR] Failed to generate HAProxy config: %v", err)
		}

		if err := reloadHAProxy(); err != nil {
			log.Printf("[ERROR] Failed to reload HAProxy: %v", err)
		}

		time.Sleep(10 * time.Second)
	}
}

func generateConfig(tmpl *template.Template, members []*memberlist.Node) error {
	file, err := os.Create("/etc/haproxy/haproxy.cfg")
	if err != nil {
		return fmt.Errorf("failed to create config file: %v", err)
	}
	defer file.Close()

	if err := tmpl.Execute(file, members); err != nil {
		return fmt.Errorf("failed to write config: %v", err)
	}

	return nil
}

func reloadHAProxy() error {
	cmd := exec.Command("systemctl", "reload", "haproxy")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to reload HAProxy: %v", err)
	}
	return nil
}

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
	mutex      sync.RWMutex
	stats      HAProxyStats
}

// NewHAProxyMetrics creates a new HAProxy metrics collector
func NewHAProxyMetrics(socketPath string) *HAProxyMetrics {
	hm := &HAProxyMetrics{
		socketPath: socketPath,
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
		return HAProxyStats{}, fmt.Errorf("failed to connect to HAProxy socket: %v", err)
	}
	defer conn.Close()

	// Send stats command
	fmt.Fprintf(conn, "show stat\n")

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

		// Create a map of field names to values
		values := make(map[string]string)
		for i, field := range fields {
			if i < len(headers) {
				values[headers[i]] = field
			}
		}

		// Parse the stats based on proxy type
		switch values["svname"] {
		case "FRONTEND":
			stats.FrontendStats[values["pxname"]] = parseProxyStats(values)
			stats.TotalRequests += parseInt64(values["req_tot"])
			stats.BytesIn += parseInt64(values["bytes_in"])
			stats.BytesOut += parseInt64(values["bytes_out"])
			stats.CurrentConns += parseInt(values["scur"])
		case "BACKEND":
			stats.BackendStats[values["pxname"]] = parseProxyStats(values)
		default:
			stats.ServerStats[values["svname"]] = parseProxyStats(values)
		}
	}

	return stats, nil
}

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
