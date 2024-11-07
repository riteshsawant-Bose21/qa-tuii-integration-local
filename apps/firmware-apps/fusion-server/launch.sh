#!/bin/bash
set -e

# Default values
BASE_NAME="fusion"
NUM_INSTANCES=1
JOIN_ADDRESS=""

# Function to display usage
usage() {
    echo "Usage: $0 [--name base_name] [--instances number_of_instances]"
    echo "  --name      : Base name for instances (default: fusion)"
    echo "  --instances : Number of instances to create (default: 1)"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            BASE_NAME="$2"
            shift 2
            ;;
        --instances)
            NUM_INSTANCES="$2"
            if ! [[ "$NUM_INSTANCES" =~ ^[0-9]+$ ]] || [ "$NUM_INSTANCES" -lt 1 ]; then
                echo "Error: Number of instances must be a positive integer"
                exit 1
            fi
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

echo "Starting cluster deployment..."
echo "Base name: $BASE_NAME"
echo "Number of instances: $NUM_INSTANCES"

# Start Python HTTP server in background
echo "Starting Python HTTP server..."
python3 -m http.server 8000 --bind 0.0.0.0 &
PYTHON_PID=$!

# Function to handle cleanup when script exits
cleanup() {
    echo "Cleaning up..."
    if [ ! -z "$PYTHON_PID" ]; then
        kill $PYTHON_PID 2>/dev/null || true
        echo "Stopped Python HTTP server"
    fi
}

trap cleanup EXIT SIGINT SIGTERM

# Function to create cloud-init configuration
create_cloud_init() {
    local instance_name="$1"
    local join_addr="$2"
    local cloud_init_file="cloud-init-${instance_name}.yaml"
    
    if [ ! -z "$join_addr" ]; then
        EXEC_START="ExecStart=/usr/local/bin/fusion-server --name %H --addr 0.0.0.0 --port 7946 --join ${join_addr}"
        EXTRA_SETUP="      # Test connectivity to cluster\n      echo \"Testing TCP connectivity to ${join_addr}\"\n      nc -zv -w5 ${join_addr%:*} ${join_addr#*:} || echo \"Cannot connect to ${join_addr}\""
    else
        EXEC_START="ExecStart=/usr/local/bin/fusion-server --name %H --addr 0.0.0.0 --port 7946"
        EXTRA_SETUP=""
    fi

    cat > "$cloud_init_file" <<EOF
#cloud-config
package_update: true
package_upgrade: true

packages:
  - curl
  - haproxy
  - keepalived
  - nc
  - iproute2

write_files:
  - path: /var/lib/fusion/config.json
    permissions: '0644'
    content: '{}'

  - path: /etc/systemd/system/fusion-server.service
    permissions: '0644'
    content: |
      [Unit]
      Description=Fusion Server
      After=network-online.target
      Wants=network-online.target

      [Service]
      Type=simple
      ${EXEC_START}
      Restart=always
      RestartSec=5

      [Install]
      WantedBy=multi-user.target

  - path: /usr/local/bin/setup-fusion.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      set -ex
      
      # Create required directories
      mkdir -p /etc/haproxy /etc/keepalived /var/lib/fusion
      
      # Get gateway IP
      GATEWAY=\$(ip route show | grep default | awk '{print \$3}')
      echo "Gateway IP: \$GATEWAY"
      
      # Download fusion-server with retry
      MAX_RETRIES=5
      RETRY_COUNT=0
      while [ \$RETRY_COUNT -lt \$MAX_RETRIES ]; do
        if curl -L --connect-timeout 10 "http://\$GATEWAY:8000/build/fusion-server" -o /usr/local/bin/fusion-server; then
          chmod +x /usr/local/bin/fusion-server
          echo "Successfully downloaded and configured fusion-server"
          break
        fi
        RETRY_COUNT=\$((RETRY_COUNT + 1))
        echo "Attempt \$RETRY_COUNT failed, retrying in 10 seconds..."
        sleep 10
      done
      
      # Enable and start services
      systemctl daemon-reload
      systemctl enable fusion-server
      systemctl start fusion-server

runcmd:
  - systemctl restart systemd-resolved
  - bash -x /usr/local/bin/setup-fusion.sh
EOF

    echo "$cloud_init_file"
}

# Function to verify instance
verify_instance() {
    local instance_name="$1"
    
    # Wait for initialization
    echo "Waiting for instance $instance_name to initialize..."
    sleep 15

    # Check if binary exists and is executable
    echo "Checking fusion-server binary for $instance_name..."
    if ! multipass exec "$instance_name" -- test -x /usr/local/bin/fusion-server; then
        echo "Error: fusion-server binary is missing or not executable in $instance_name"
        multipass exec "$instance_name" -- ls -l /usr/local/bin/fusion-server || true
        return 1
    fi

    # Check if service is running
    echo "Checking fusion-server service for $instance_name..."
    if multipass exec "$instance_name" -- systemctl is-active --quiet fusion-server; then
        echo "fusion-server is running on $instance_name"
        multipass exec "$instance_name" -- systemctl status fusion-server
        echo "Instance info:"
        multipass info "$instance_name"
        
        # Show all listening ports
        echo "Checking listening ports:"
        multipass exec "$instance_name" -- ss -tulpn || true
        return 0
    else
        echo "fusion-server is not running on $instance_name, checking status and logs..."
        multipass exec "$instance_name" -- systemctl status fusion-server || true
        multipass exec "$instance_name" -- journalctl -u fusion-server --no-pager || true
        return 1
    fi
}

# Launch first instance
FIRST_INSTANCE="${BASE_NAME}1"
echo "Launching first instance: $FIRST_INSTANCE"
cloud_init_file=$(create_cloud_init "$FIRST_INSTANCE" "")
multipass launch --name "$FIRST_INSTANCE" --cloud-init "$cloud_init_file" --memory 2G --cpus 2

# Verify first instance
verify_instance "$FIRST_INSTANCE" || exit 1

# Get the IP of the first instance
FIRST_IP=$(multipass info "$FIRST_INSTANCE" | grep IPv4 | head -1 | awk '{print $2}')
echo "First instance IP: $FIRST_IP"

# Launch additional instances if requested
if [ "$NUM_INSTANCES" -gt 1 ]; then
    for i in $(seq 2 "$NUM_INSTANCES"); do
        INSTANCE_NAME="${BASE_NAME}${i}"
        echo "Launching instance $i: $INSTANCE_NAME"
        cloud_init_file=$(create_cloud_init "$INSTANCE_NAME" "${FIRST_IP}:7946")
        multipass launch --name "$INSTANCE_NAME" --cloud-init "$cloud_init_file" --memory 2G --cpus 2
        
        # Verify additional instance
        verify_instance "$INSTANCE_NAME" || exit 1
    done
fi

echo "Cluster deployment complete!"
echo "Created $NUM_INSTANCES instances with base name '$BASE_NAME'"
multipass list
