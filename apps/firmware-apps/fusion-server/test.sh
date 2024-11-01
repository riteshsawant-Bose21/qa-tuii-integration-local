#!/bin/bash

# Set error handling
set -e

echo "Starting fusion-server testing setup..."

# Check if fusion-server.yaml exists
if [ ! -f "fusion-server.yaml" ]; then
    echo "Error: fusion-server.yaml not found in current directory"
    exit 1
fi

# Check if Multipass is installed
if ! command -v multipass &> /dev/null; then
    echo "Multipass is not installed. Installing via Homebrew..."
    brew install --cask multipass
fi

echo "Creating test instances..."

# Launch instances with specific IP addresses
# Note: We use the default network since custom network creation isn't supported in current Multipass
multipass launch 22.04 --name node1 --cloud-init fusion-server.yaml || {
    echo "Failed to create node1"
    exit 1
}

multipass launch 22.04 --name node2 --cloud-init fusion-server.yaml || {
    echo "Failed to create node2"
    exit 1
}

echo "Waiting for instances to initialize (30 seconds)..."
sleep 30

echo "Instance Status:"
multipass list

echo "Testing node1 configuration..."

# Function to run command and handle errors
run_command() {
    echo "Running: $2"
    multipass exec node1 -- $1 || echo "Warning: Command failed: $2"
}

# Test various components
run_command "sudo cat /var/log/cloud-init.log" "Checking cloud-init logs"
run_command "sudo systemctl status haproxy" "Checking HAProxy status"
run_command "sudo systemctl status keepalived" "Checking Keepalived status"
run_command "ip addr show" "Checking network configuration"
run_command "sudo haproxy -c -f /home/configs/haproxy/haproxy.cfg" "Validating HAProxy config"
run_command "sudo keepalived -t -f /home/configs/keepalived/keepalived.conf" "Validating Keepalived config"

echo "
Testing complete. To access the instances:
- multipass shell node1
- multipass shell node2

To clean up when done:
- multipass delete node1 node2
- multipass purge

Current running instances:"
multipass list
