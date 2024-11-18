#!/bin/bash

# Function to read a file
read_file() {
    cat "$1"
}

# Generate the cloud-init configuration
generate_config() {
    local scripts_dir=${1:-"scripts"}
    
    # Keepalived configuration
    read -r -d '' KEEPALIVED_CONF << 'EOF'
vrrp_script chk_haproxy {
 script "/usr/local/bin/check-haproxy.sh"
 interval 2
 weight 2
}
global_defs {
 enable_script_security
}
vrrp_instance VI_1 {
 state BACKUP
 interface enp0s1
 virtual_router_id 51
 priority 100
 advert_int 1
 authentication {
 auth_type PASS
 auth_pass fusion
 }
 virtual_ipaddress {
 192.168.64.100/24
 }
 track_script {
 chk_haproxy
 }
}
EOF

    # HAProxy configuration
    read -r -d '' HAPROXY_CONF << 'EOF'
global
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
EOF

    # Output cloud-config in YAML format
    cat << EOF
#cloud-config
package_update: true
package_upgrade: true
packages:
  - haproxy
  - keepalived
  - libjsoncpp25
  - net-tools
write_files:
  - path: /etc/systemd/system/fusion-server.service
    permissions: '0644'
    owner: root:root
    content: |
$(read_file "$scripts_dir/fusion-server.service" | sed 's/^/      /')
  - path: /etc/systemd/system/keepalived.service
    permissions: '0644'
    owner: root:root
    content: |
$(read_file "$scripts_dir/keepalived.service" | sed 's/^/      /')
  - path: /etc/keepalived/keepalived.conf
    permissions: '0644'
    owner: root:root
    content: |
$(echo "$KEEPALIVED_CONF" | sed 's/^/      /')
  - path: /etc/haproxy/haproxy.cfg
    permissions: '0644'
    owner: root:root
    content: |
$(echo "$HAPROXY_CONF" | sed 's/^/      /')
  - path: /usr/local/bin/check-haproxy.sh
    permissions: '0755'
    owner: root:root
    content: |
$(read_file "$scripts_dir/check-haproxy.sh" | sed 's/^/      /')
  - path: /usr/local/bin/setup-fusion.sh
    permissions: '0755'
    owner: root:root
    content: |
$(read_file "$scripts_dir/setup-fusion.sh" | sed 's/^/      /')
EOF
}

# Main execution
generate_config "${1:-scripts}"