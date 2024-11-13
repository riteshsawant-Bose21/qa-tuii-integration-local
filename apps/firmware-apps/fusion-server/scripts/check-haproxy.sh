#!/bin/bash

# Check if HAProxy service is running
if ! systemctl is-active --quiet haproxy; then
    exit 1
fi

# Success if we get here
exit 0