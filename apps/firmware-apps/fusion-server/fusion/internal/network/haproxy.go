package network

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"text/template"
	"time"

	"github.com/hashicorp/memberlist"
)

const haproxyTemplate = `global
 log /dev/log local0
 stats socket /var/run/haproxy.sock mode 600 level admin
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

backend servers
 balance roundrobin
 option httpchk GET /health
 {{range .}}
 server {{.Name}} {{.Addr}}:8080 check
 {{end}}

`

// ManageHAProxy continuously updates HAProxy configuration based on cluster membership
func ManageHAProxy(list *memberlist.Memberlist) {
	tmpl := template.Must(template.New("haproxy").Parse(haproxyTemplate))

	for {
		members := list.Members()
		if err := generateConfig(tmpl, members); err != nil {
			log.Printf("Failed to generate HAProxy config: %v", err)
		}

		if err := reloadHAProxy(); err != nil {
			log.Printf("Failed to reload HAProxy: %v", err)
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
