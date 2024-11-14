#!/bin/bash

# Path to the new binary
BINARY_PATH="build/fusion-server"

# Check if binary exists
if [ ! -f "$BINARY_PATH" ]; then
    echo "Error: Binary not found at $BINARY_PATH"
    exit 1
fi

# Get list of running multipass instances
instances=$(multipass list --format csv | tail -n +2 | cut -d',' -f1)

for instance in $instances; do
    echo "Updating fusion-server on instance: $instance"
    
    # Copy the new binary to the instance
    multipass copy-files "$BINARY_PATH" "$instance:/tmp/fusion-server"
    
    # Execute commands on the instance to update and restart the service
    multipass exec "$instance" -- sudo bash -c '
        # Stop the service
        systemctl stop fusion-server
        
        # Copy new binary to destination
        cp /tmp/fusion-server /usr/local/bin/
        chmod +x /usr/local/bin/fusion-server
        
        # Clean up temp file
        rm /tmp/fusion-server
        
        # Start the service
        systemctl start fusion-server
        
        # Verify service status
        systemctl status fusion-server --no-pager
    '
done
