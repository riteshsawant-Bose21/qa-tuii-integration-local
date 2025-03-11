#!/bin/bash

# Script used by systemd to launch fusion-server

# Get the first non-loopback IPv4 address
IP_ADDR=$(hostname -I | awk '{print $1}')

# Ensure IP is available before starting the server
if [ -z "$IP_ADDR" ]; then
    echo "Error: Could not determine IP address." >&2
    exit 1
fi

echo "Starting fusion-server on IP: $IP_ADDR"

# Start fusion-server with the correct IP
exec /usr/local/bin/fusion-server -name "$(hostname)" -addr "$IP_ADDR" -port 7946 -verbose
