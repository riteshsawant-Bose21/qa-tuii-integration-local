#!/bin/bash
# See multipass.env for values of NET_INTERFACE and VIRTUAL_IP.
set -eu

# Fusion server configuration and startup script
fusion_server_start_path=/usr/local/bin/fusion-gateway-start.sh
fusion_server_service_path=/etc/systemd/system/fusion-gateway.service

# haproxy config
haproxy_conf_data_path=/usr/local/bin/haproxy_conf_data.sh

# Keepalived configuration
keepalived_service_path=/etc/systemd/system/keepalived.service
keepalived_conf_path=/etc/keepalived/keepalived.conf
keepalived_conf_data() {
  cat << EOF_K
# Fusion customized keepalived configuration
vrrp_track_process haproxy-service {
  process haproxy
  delay 2
}
global_defs {
  enable_script_security
}
vrrp_instance VI_1 {
  state BACKUP
  interface $NET_INTERFACE
  virtual_router_id 51
  priority 100
  advert_int 1
  authentication {
    auth_type PASS
    auth_pass fusion 
  }
  virtual_ipaddress {
    $VIRTUAL_IP/24
  }
  track_process {
    haproxy-service
  }
}
EOF_K
}

# HAProxy configuration
haproxy_service_path=/etc/systemd/system/haproxy.service
haproxy_conf_path=/etc/haproxy/haproxy.cfg
haproxy_conf_data() {
  cat << EOF_H
# Fusion default configuration for haproxy
# NOTE: This will be overwritten at runtime by fusion-gateway.
#       See gateway/internal/network/haproxy.go:generateConfig
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
EOF_H
}

indent_content() {
  # Outputs the content of the first argument and sends to stdout.
  # Indenting properly for the cloud-config yaml file.
  # Args: 
  #   $1 - A file to indent or the name of a function to call that outputs a
  #        string, see haproxy_conf_data for an example.
  if [ -f "$1" ]; then
    # Indent all lines except blank lines (yamllint).
    sed "s/^\([^$]\)/      \1/" "$1"
  else
    eval "$1" | sed "s/^\([^$]\)/      \1/"
  fi
}

# Generate the cloud-init configuration in YAML format.
generate_config() {
  local scripts_dir=${1:-"scripts"}

  cat << EOF
#cloud-config
---
package_update: true
package_upgrade: true
packages:
  - chrony
  - haproxy
  - keepalived
  - libjsoncpp25
  - net-tools
  - ntpdate
  - wget
write_files:
  - path: $fusion_server_start_path
    permissions: '0644'
    owner: root:root
    content: |
$(indent_content "$scripts_dir/fusion-gateway-start.sh")
  - path: $fusion_server_service_path
    permissions: '0644'
    owner: root:root
    content: |
$(indent_content "$scripts_dir/fusion-gateway.service")
  - path: $keepalived_service_path
    permissions: '0644'
    owner: root:root
    content: |
$(indent_content "$scripts_dir/keepalived.service")
  - path: $keepalived_conf_path
    permissions: '0644'
    owner: root:root
    content: |
$(indent_content 'keepalived_conf_data')
  - path: $haproxy_service_path
    permissions: '0644'
    owner: root:root
    content: |
$(indent_content "$scripts_dir/haproxy.service")
  - path: $haproxy_conf_path
    permissions: '0644'
    owner: root:root
    content: |
$(indent_content 'haproxy_conf_data')
  - path: $haproxy_conf_data_path
    permissions: '0755'
    owner: root:root
    content: |
EOF
}

write_configs_to_path() {
  # Output the config and service files to the correct location under CONFIG_TARGET_PREFIX.
  local scripts_dir=${1:-scripts}
  echo "Writing configs to $output_path"...

  # fusion-gateway
  mkdir -p "$(dirname "${output_path}$fusion_server_service_path")"
  cp -f "$scripts_dir/fusion-gateway.service" "${output_path}$fusion_server_service_path"

  # keepalived
  mkdir -p "$(dirname "${output_path}$keepalived_service_path")"
  mkdir -p "$(dirname "${output_path}$keepalived_conf_path")"
  cp -f "$scripts_dir/keepalived.service" "${output_path}$keepalived_service_path"
  keepalived_conf_data > "${output_path}$keepalived_conf_path"

  # haproxy
  mkdir -p "$(dirname "${output_path}$haproxy_service_path")"
  mkdir -p "$(dirname "${output_path}$haproxy_conf_path")"
  cp -f "$scripts_dir/haproxy.service" "${output_path}$haproxy_service_path"
  haproxy_conf_data > "${output_path}$haproxy_conf_path"
}

# Main execution
# Error if the variables from multipass.env are not set.
if [ -z "${NET_INTERFACE:-}" ] || [ -z "${VIRTUAL_IP:-}" ]; then
  printf "%s \n\tERROR: NET_INTERFACE or VIRTUAL_IP is not defined" "$0"
  exit 1
fi

# Define CONFIG_TARGET_PREFIX to generate the config files individually under
# the given root path, and not as part of a multipass yaml config.
output_path=${CONFIG_TARGET_PREFIX:-}

if [ -n "$output_path" ]; then
  write_configs_to_path "${1:-scripts}"
else
  # Generate the yaml config for multipass
  generate_config "${1:-scripts}"
fi