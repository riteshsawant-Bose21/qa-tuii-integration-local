#!/bin/bash
set -e

# Default values
INSTANCE_NAME="fs1"
JOIN_ADDRESS=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            INSTANCE_NAME="$2"
            shift 2
            ;;
        --join)
            JOIN_ADDRESS="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--name instance_name] [--join join_address]"
            exit 1
            ;;
    esac
done

echo "Starting server monitoring script..."
echo "Using instance name: $INSTANCE_NAME"

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

# Construct the ExecStart command based on JOIN_ADDRESS
if [ ! -z "$JOIN_ADDRESS" ]; then
    EXEC_START="ExecStart=/usr/local/bin/fusion-server --name %H --addr 0.0.0.0 --port 7946 --join ${JOIN_ADDRESS}"
    # Add connectivity test to setup script
    EXTRA_SETUP="      # Test connectivity to cluster\n      echo \"Testing TCP connectivity to ${JOIN_ADDRESS}\"\n      nc -zv -w5 ${JOIN_ADDRESS%:*} ${JOIN_ADDRESS#*:} || echo \"Cannot connect to ${JOIN_ADDRESS}\""
else
    EXEC_START="ExecStart=/usr/local/bin/fusion-server --name %H --addr 0.0.0.0 --port 7946"
    EXTRA_SETUP=""
fi

# Create unified cloud-init configuration
CLOUD_INIT_FILE="cloud-init.yaml"
cat > "$CLOUD_INIT_FILE" <<EOF
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

# Launch instance
echo "Launching new multipass instance '$INSTANCE_NAME'..."
multipass launch --name "$INSTANCE_NAME" --cloud-init "$CLOUD_INIT_FILE" --memory 2G --cpus 2

# Wait for initialization
echo "Waiting for instance to initialize..."
sleep 15

# Check if binary exists and is executable
echo "Checking fusion-server binary..."
if ! multipass exec "$INSTANCE_NAME" -- test -x /usr/local/bin/fusion-server; then
    echo "Error: fusion-server binary is missing or not executable"
    multipass exec "$INSTANCE_NAME" -- ls -l /usr/local/bin/fusion-server || true
    exit 1
fi

# Check if service is running
echo "Checking fusion-server service..."
if multipass exec "$INSTANCE_NAME" -- systemctl is-active --quiet fusion-server; then
    echo "fusion-server is running"
    multipass exec "$INSTANCE_NAME" -- systemctl status fusion-server
    echo "Instance info:"
    multipass info "$INSTANCE_NAME"
    
    # Show all listening ports
    echo "Checking listening ports:"
    multipass exec "$INSTANCE_NAME" -- ss -tulpn || true
else
    echo "fusion-server is not running, checking status and logs..."
    multipass exec "$INSTANCE_NAME" -- systemctl status fusion-server || true
    multipass exec "$INSTANCE_NAME" -- journalctl -u fusion-server --no-pager || true
    exit 1
fi
