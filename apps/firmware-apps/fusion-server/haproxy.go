package main

import (
	"fmt"
	"html/template"
	"os"
	"os/exec"
	"strings"
	"time"

	"github.com/hashicorp/memberlist"
)

type HAProxyConfig struct {
	Backends []string
}

func generateHAProxyConfig(members []*memberlist.Node) error {
	config := HAProxyConfig{
		Backends: make([]string, len(members)),
	}
	for i, member := range members {
		config.Backends[i] = fmt.Sprintf("%s:%d", member.Addr, 8080)
	}

	tmpl := template.Must(template.New("haproxy").Parse(`
global
    log stdout format raw local0 debug
    maxconn 32768
    user haproxy
    group haproxy
    
defaults
    log global
    mode http
    option httplog
    option dontlognull
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend http_front
    bind *:80
    default_backend servers

backend servers
    balance roundrobin
    option httpchk GET /getValue
    default-server inter 2s fall 3 rise 2
    {{range .Backends}}
    server srv{{.}} {{.}} check
    {{end}}

listen stats
    bind *:8404
    stats enable
    stats uri /
    stats refresh 5s

# Make sure there's a newline at the end of the file
`))

	f, err := os.Create("/etc/haproxy/haproxy.cfg")
	if err != nil {
		return err
	}
	defer f.Close()
	return tmpl.Execute(f, config)
}

func waitForVIP(timeout time.Duration) error {
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		out, err := exec.Command("ip", "addr", "show", "eth0").Output()
		if err == nil && strings.Contains(string(out), "172.18.0.2") {
			return nil
		}
		time.Sleep(500 * time.Millisecond)
	}
	return fmt.Errorf("timeout waiting for VIP")
}

func reloadHAProxy() error {
	// Wait for VIP to be available
	if err := waitForVIP(10 * time.Second); err != nil {
		return fmt.Errorf("VIP not ready: %v", err)
	}

	pidFile := "/var/run/haproxy.pid"

	// Check if HAProxy is running
	if _, err := os.Stat(pidFile); os.IsNotExist(err) {
		// Start HAProxy if not running
		cmd := exec.Command("haproxy", "-f", "/etc/haproxy/haproxy.cfg", "-W", "-p", pidFile)
		if err := cmd.Start(); err != nil {
			return fmt.Errorf("failed to start HAProxy: %v", err)
		}
		return nil
	}

	// Read existing PID
	pidBytes, err := os.ReadFile(pidFile)
	if err != nil {
		return fmt.Errorf("failed to read HAProxy PID: %v", err)
	}
	pid := strings.TrimSpace(string(pidBytes))

	// Graceful reload
	cmd := exec.Command("haproxy", "-f", "/etc/haproxy/haproxy.cfg", "-sf", pid)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("failed to reload HAProxy: %v, output: %s", err, output)
	}

	return nil
}
