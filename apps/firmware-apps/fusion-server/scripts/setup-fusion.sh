#!/bin/bash
set -ex

# Create required directories
mkdir -p /etc/haproxy /etc/keepalived /var/lib/fusion

# Function to check if a package is installed
check_package() {
    dpkg -l | grep -q "^ii  $1 " || {
        echo "Package $1 is not installed"
        exit 1
    }
}

# Verify required packages are installed
check_package haproxy
check_package keepalived

# Get gateway IP
GATEWAY=$(ip route show | grep default | awk '{print $3}')
echo "Gateway IP: $GATEWAY"
if [ -z "$GATEWAY" ]; then
    echo "Error: Could not determine gateway IP"
    exit 1
fi

# Test connectivity before proceeding with download
echo "Testing connectivity to download server..."
for i in {1..3}; do
    if nc -zv $GATEWAY 8000; then
        echo "Download server is accessible"
        break
    fi
    if [ $i -eq 3 ]; then
        echo "Error: Download server not accessible after 3 attempts"
        exit 1
    fi
    echo "Attempt $i failed, retrying in 5 seconds..."
    sleep 5
done

# Function to verify downloaded binary
verify_binary() {
    local binary="/usr/local/bin/fusion-server"
    if [ ! -f "$binary" ]; then
        echo "Binary not found at $binary"
        return 1
    fi

    chmod +x $binary

    if [ ! -x "$binary" ]; then
        echo "Binary is not executable"
        return 1
    fi

    local file_size=$(stat -f%z "$binary" 2>/dev/null || stat -c%s "$binary")
    if [ "$file_size" -lt 1000 ]; then  # Adjust minimum size as needed
        echo "Binary file too small ($file_size bytes), likely invalid"
        return 1
    fi
    echo "Binary verification passed"
    return 0
}

# Download fusion-server binary with retries
MAX_RETRIES=5
RETRY_COUNT=0
SUCCESS=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo "Attempting download (try $((RETRY_COUNT + 1))/$MAX_RETRIES)..."

    if curl -v -L --connect-timeout 10 --retry 3 --retry-delay 5 \
            --retry-connrefused --retry-max-time 60 \
            "http://${GATEWAY}:8000/build/fusion-server" \
            -o /usr/local/bin/fusion-server && \
       verify_binary; then
        SUCCESS=true
        break
    fi

    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
        echo "Download or verification failed. Retrying in 10 seconds..."
        sleep 10
    fi
done

if [ "$SUCCESS" = false ]; then
    echo "Failed to download and verify fusion-server after $MAX_RETRIES attempts"
    exit 1
fi

# Make binary executable (in case it isn't already)
chmod +x /usr/local/bin/fusion-server

# Enable and start services
systemctl daemon-reload
sudo systemctl enable haproxy keepalived fusion-server
sudo systemctl start haproxy keepalived fusion-server

echo "Setup complete"
