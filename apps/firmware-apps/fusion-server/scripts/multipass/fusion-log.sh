#!/bin/bash

# Monitor the fusion-server log of a specific instance
set -ex

if [ $# -eq 0 ]; then
    echo "Usage: $0 <instance-name>"
    exit 1
fi

instance_name="$1"
multipass exec "$instance_name" -- sudo journalctl -u fusion-server -f
