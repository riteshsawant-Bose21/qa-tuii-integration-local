#!/bin/bash

# Check if HAProxy service is running
if ! systemctl is-active --quiet haproxy; then
    exit 1
fi

# Check if HAProxy process is responding
if ! echo "show info" | socat unix-connect:/var/run/haproxy.sock stdio &>/dev/null; then
    exit 2
fi

# Check if there are backend servers available
if ! echo "show servers state" | socat unix-connect:/var/run/haproxy.sock stdio | grep -q "UP"; then
    exit 3
fi

exit 0