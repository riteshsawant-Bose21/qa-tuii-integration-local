#!/bin/bash

# Push a new fusion-gateway binary to the specified instances.

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Updates the fusion-gateway binary on multipass instances matching a specified prefix.

Options:
    -h, --help          Show this help message
    --prefix PREFIX     Specify the instance name prefix to match (default: fusion)

Examples:
    $0                  # Update all instances starting with 'fusion'
    $0 --prefix test   # Update all instances starting with 'test'
    $0 --help          # Show this help message

The script will:
1. Copy the new binary from build/fusion-gateway
2. Stop the fusion-gateway service
3. Install the new binary
4. Restart the service
5. Display the service status
EOF
    exit 0
}

# Default prefix
PREFIX="fusion"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        --prefix)
            if [ -z "$2" ]; then
                echo "Error: --prefix requires an argument"
                exit 1
            fi
            PREFIX="$2"
            shift 2
            ;;
        *)
            echo "Error: Unknown argument: $1"
            echo "Use --help to see available options"
            exit 1
            ;;
    esac
done

# Path to the binary
BINARY_PATH="build/fusion-gateway"

# Check if binary exists
if [ ! -f "$BINARY_PATH" ]; then
    echo "Error: Binary not found at $BINARY_PATH"
    exit 1
fi

# Path to the launch script
SCRIPT_PATH="scripts/fusion-gateway-start.sh"

# Check if launch script exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "Error: Script not found at $SCRIPT_PATH"
    exit 1
fi


# Get list of running multipass instances that start with the specified prefix
instances=$(multipass list --format csv | tail -n +2 | cut -d',' -f1 | grep "^$PREFIX")

# Check if any matching instances were found
if [ -z "$instances" ]; then
    echo "No instances starting with '$PREFIX' were found"
    exit 0
fi

echo "Updating instances with prefix: $PREFIX"

for instance in $instances; do
    echo "Updating fusion-gateway on instance: $instance"
    
    # Copy the new binary to the instance
    multipass copy-files "$BINARY_PATH" "$instance:/tmp/fusion-gateway"
    
    # Copy the new launch script to the instance
    multipass copy-files "$SCRIPT_PATH" "$instance:/tmp/fusion-gateway-start.sh"

    # Execute commands on the instance to update and restart the service
    multipass exec "$instance" -- sudo bash -c '
        # Stop the service
        systemctl stop fusion-gateway
        
        # Copy new binary to destination
        cp /tmp/fusion-gateway /usr/local/bin/
        chmod +x /usr/local/bin/fusion-gateway
        
        # Clean up temp file
        rm /tmp/fusion-gateway

        # Copy new launch script to destination
        cp /tmp/fusion-gateway-start.sh /usr/local/bin/
        
        # Start the service
        systemctl start fusion-gateway
        
        # Verify service status
        systemctl status fusion-gateway --no-pager
    '
done
