#!/bin/bash
set -e

INSTANCE_NAME="test-fusion"

# Check if instance exists and delete if it does
if multipass info $INSTANCE_NAME &>/dev/null; then
    echo "Instance exists, deleting..."
    multipass delete $INSTANCE_NAME
    multipass purge
fi

echo "Launching instance..."
multipass launch --name $INSTANCE_NAME --memory 2G --cpus 2

# Get the host's IP from the VM's perspective (gateway)
HOST_IP=$(multipass exec $INSTANCE_NAME -- ip route | grep default | cut -d' ' -f3)
echo "Host IP to use: $HOST_IP"

echo "Creating directories..."
multipass exec $INSTANCE_NAME -- sudo mkdir -p /usr/local/bin /etc/systemd/system /etc/keepalived

echo "Copying and moving files..."
# First transfer to home directory
multipass transfer scripts/setup-fusion.sh "$INSTANCE_NAME:"
multipass transfer scripts/check-haproxy.sh "$INSTANCE_NAME:"
multipass transfer scripts/fusion-server.service "$INSTANCE_NAME:"
multipass transfer scripts/keepalived.conf "$INSTANCE_NAME:"

# Then move them to the correct locations with sudo
multipass exec $INSTANCE_NAME -- sudo mv setup-fusion.sh /usr/local/bin/
multipass exec $INSTANCE_NAME -- sudo mv check-haproxy.sh /usr/local/bin/
multipass exec $INSTANCE_NAME -- sudo mv fusion-server.service /etc/systemd/system/
multipass exec $INSTANCE_NAME -- sudo mv keepalived.conf /etc/keepalived/

echo "Setting permissions..."
multipass exec $INSTANCE_NAME -- sudo chmod 755 /usr/local/bin/setup-fusion.sh /usr/local/bin/check-haproxy.sh

echo "Installing packages..."
multipass exec $INSTANCE_NAME -- sudo apt-get update
multipass exec $INSTANCE_NAME -- sudo apt-get install -y haproxy keepalived

echo "Starting HTTP server for fusion-server download..."
# Start HTTP server in the parent directory so build folder is accessible
python3 -m http.server 8000 --bind 0.0.0.0 &
HTTP_PID=$!

# Wait a moment for the HTTP server to start
sleep 2

# Create a modified setup script that uses the correct IP
cat > /tmp/modified-setup.sh << EOF
#!/bin/bash
set -ex

# Create required directories
mkdir -p /etc/haproxy /etc/keepalived /var/lib/fusion

echo "Using host IP: $HOST_IP"

# Download fusion-server with retry
MAX_RETRIES=5
RETRY_COUNT=0
while [ \$RETRY_COUNT -lt \$MAX_RETRIES ]; do
    if curl -L --connect-timeout 10 "http://$HOST_IP:8000/build/fusion-server" -o /usr/local/bin/fusion-server; then
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

# Start haproxy
systemctl enable haproxy
systemctl start haproxy

# Start keepalived
systemctl enable keepalived
systemctl start keepalived

# Show status
echo "Service status:"
systemctl status fusion-server --no-pager || true
systemctl status haproxy --no-pager || true
systemctl status keepalived --no-pager || true
ip addr show
EOF

# Copy and run the modified setup script
multipass transfer /tmp/modified-setup.sh $INSTANCE_NAME:
multipass exec $INSTANCE_NAME -- sudo mv modified-setup.sh /usr/local/bin/setup-fusion.sh
multipass exec $INSTANCE_NAME -- sudo chmod 755 /usr/local/bin/setup-fusion.sh
multipass exec $INSTANCE_NAME -- sudo bash -x /usr/local/bin/setup-fusion.sh

echo "Killing HTTP server..."
kill $HTTP_PID

echo "Setup complete. Instance info:"
multipass info $INSTANCE_NAME

echo "Checking services..."
echo "Fusion Server status:"
multipass exec $INSTANCE_NAME -- sudo systemctl status fusion-server --no-pager
