#!/bin/bash
set -ex

# Create required directories
mkdir -p /etc/haproxy /etc/keepalived /var/lib/fusion

# Get gateway IP
GATEWAY=$(ip route show | grep default | awk '{print $3}')
echo "Gateway IP: $GATEWAY"

# Download fusion-server with retry
MAX_RETRIES=5
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -L --connect-timeout 10 "http://$GATEWAY:8000/build/fusion-server" -o /usr/local/bin/fusion-server; then
        chmod +x /usr/local/bin/fusion-server
        echo "Successfully downloaded and configured fusion-server"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "Attempt $RETRY_COUNT failed, retrying in 10 seconds..."
    sleep 10
done

# Enable and start services
systemctl daemon-reload
systemctl enable fusion-server
systemctl start fusion-server

# Start keepalived
systemctl enable keepalived
systemctl start keepalived

# Show status
echo "Service status:"
systemctl status fusion-server --no-pager || true
systemctl status keepalived --no-pager || true
ip addr show
