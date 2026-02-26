#!/bin/bash

# Push a new fusion-server binary to the specified instances.

# SSH key path for direct SSH fallback (multipass 1.16.1 bug workaround)
MULTIPASS_SSH_KEY="/var/root/Library/Application Support/multipassd/ssh-keys/id_rsa"

# Helper function to get instance IP
get_instance_ip() {
    local instance_name="$1"
    multipass info "$instance_name" 2>/dev/null | awk '/IPv4/{print $2; exit}'
}

# Wrapper for multipass exec with direct SSH fallback
mp_exec() {
    local instance_name="$1"
    shift
    local cmd="$*"
    
    # Try multipass exec first
    if multipass exec "$instance_name" -- $cmd 2>/dev/null; then
        return 0
    fi
    
    # Fall back to direct SSH
    local ip=$(get_instance_ip "$instance_name")
    if [ -n "$ip" ]; then
        sudo ssh -i "$MULTIPASS_SSH_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@"$ip" "$cmd" 2>/dev/null
        return $?
    fi
    return 1
}

# Wrapper for multipass transfer with direct SCP fallback
mp_transfer() {
    local src="$1"
    local dest="$2"
    
    # Try multipass transfer first
    if multipass transfer "$src" "$dest" 2>/dev/null; then
        return 0
    fi
    
    # Parse destination (instance_name:/path)
    local instance_name="${dest%%:*}"
    local remote_path="${dest#*:}"
    local ip=$(get_instance_ip "$instance_name")
    
    if [ -n "$ip" ]; then
        sudo scp -i "$MULTIPASS_SSH_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$src" ubuntu@"$ip":"$remote_path" 2>/dev/null
        return $?
    fi
    return 1
}

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Updates the fusion-server binary on multipass instances matching a specified prefix.

Options:
    -h, --help          Show this help message
    --prefix PREFIX     Specify the instance name prefix to match (default: fusion)

Examples:
    $0                  # Update all instances starting with 'fusion'
    $0 --prefix test   # Update all instances starting with 'test'
    $0 --help          # Show this help message

The script will:
1. Copy the new binary from build/fusion-server
2. Stop the fusion-server service
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
BINARY_PATH="build/fusion-server"

# Check if binary exists
if [ ! -f "$BINARY_PATH" ]; then
    echo "Error: Binary not found at $BINARY_PATH"
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
    echo "Updating fusion-server on instance: $instance"
    
    # Copy the new binary to the instance
    echo "  Copying binary..."
    if ! mp_transfer "$BINARY_PATH" "$instance:/tmp/fusion-server"; then
        echo "  Error: Failed to copy binary to $instance"
        continue
    fi
    
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
