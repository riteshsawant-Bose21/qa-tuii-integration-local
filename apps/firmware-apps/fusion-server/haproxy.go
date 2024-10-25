package main

import (
	"fmt"
	"html/template"
	"os"
	"os/exec"
	"strings"

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
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    pidfile /var/run/haproxy.pid

defaults
    log global
    mode http
    option httplog
    option dontlognull
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend http-in
    bind *:80
    default_backend servers

backend servers
    balance roundrobin
    {{range .Backends}}
    server {{.}} {{.}} check
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

func reloadHAProxy() error {
	pidFile := "/var/run/haproxy.pid"

	if _, err := os.Stat(pidFile); os.IsNotExist(err) {
		// If PID file doesn't exist, start HAProxy
		cmd := exec.Command("haproxy", "-f", "/etc/haproxy/haproxy.cfg", "-W")
		return cmd.Start()
	}

	pidBytes, err := os.ReadFile(pidFile)
	if err != nil {
		return fmt.Errorf("failed to read HAProxy PID: %v", err)
	}
	pid := strings.TrimSpace(string(pidBytes))

	cmd := exec.Command("haproxy", "-f", "/etc/haproxy/haproxy.cfg", "-sf", pid)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("failed to reload HAProxy: %v, output: %s", err, output)
	}
	return nil
}
