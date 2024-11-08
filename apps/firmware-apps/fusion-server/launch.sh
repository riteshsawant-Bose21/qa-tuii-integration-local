#!/bin/bash
set -e

# Default values
BASE_NAME="fusion"
NUM_INSTANCES=1
JOIN_ADDRESS=""
KILL_MODE=false

# Function to display usage
usage() {
    echo "Usage: $0 [--name base_name] [--instances number_of_instances] [--kill]"
    echo "  --name      : Base name for instances (default: fusion)"
    echo "  --instances : Number of instances to create (default: 1)"
    echo "  --kill      : Delete and purge all instances with the specified base name"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            BASE_NAME="$2"
            shift 2
            ;;
        --instances)
            NUM_INSTANCES="$2"
            if ! [[ "$NUM_INSTANCES" =~ ^[0-9]+$ ]] || [ "$NUM_INSTANCES" -lt 1 ]; then
                echo "Error: Number of instances must be a positive integer"
                exit 1
            fi
            shift 2
            ;;
        --kill)
            KILL_MODE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Function to kill all instances with given base name
kill_instances() {
    local base_name="$1"
    echo "Looking for instances matching pattern: ${base_name}*"
    
    # Get list of matching instances
    local instances=$(multipass list --format csv | grep "^${base_name}" | cut -d',' -f1)
    
    if [ -z "$instances" ]; then
        echo "No instances found matching pattern '${base_name}*'"
        return 0
    fi
    
    echo "Found instances to delete:"
    echo "$instances"
    echo
    
    # Prompt for confirmation
    read -p "Are you sure you want to delete these instances? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled"
        exit 0
    fi
    
    # Stop instances first
    echo "Stopping instances..."
    for instance in $instances; do
        echo "Stopping $instance..."
        multipass stop "$instance" || echo "Warning: Failed to stop $instance"
    done
    
    # Delete instances
    echo "Deleting instances..."
    for instance in $instances; do
        echo "Deleting $instance..."
        multipass delete "$instance" || echo "Warning: Failed to delete $instance"
    done
    
    # Purge all deleted instances
    echo "Purging deleted instances..."
    multipass purge
    
    echo "Instance cleanup complete!"
}

# Handle kill mode if specified
if [ "$KILL_MODE" = true ]; then
    kill_instances "$BASE_NAME"
    exit 0
fi

# Rest of the original script continues here...
echo "Starting cluster deployment..."
echo "Base name: $BASE_NAME"
echo "Number of instances: $NUM_INSTANCES"

# Start Python HTTP server in background
echo "Starting Python HTTP server..."
python3 -m http.server 8000 --bind 0.0.0.0 &
PYTHON_PID=$!

# Function to handle cleanup when script exits
cleanup() {
    # Only perform cleanup if not already in progress
    if [ -z "$CLEANUP_IN_PROGRESS" ]; then
        CLEANUP_IN_PROGRESS=1
        echo
        echo "Cleaning up..."
        if [ ! -z "$PYTHON_PID" ]; then
            kill $PYTHON_PID 2>/dev/null || true
            echo "Stopped Python HTTP server"
        fi
        
        # Clean up temporary cloud-init files
        echo "Cleaning up temporary cloud-init files..."
        rm -f /tmp/cloud-init-${BASE_NAME}*.yaml
    fi
}

# Set up trap but don't exit on errors
set +e
trap cleanup EXIT

# Function to create instance-specific cloud-init configuration
create_cloud_init() {
    local instance_name="$1"
    local join_addr="$2"
    local cloud_init_file="/tmp/cloud-init-${instance_name}.yaml"
    
    # Read the base configuration
    if [ ! -f "fusion-server.yaml" ]; then
        echo "Error: fusion-server.yaml not found"
        return 1
    fi

    # Create instance-specific cloud-init
    cp fusion-server.yaml "$cloud_init_file"
    
    if [ ! -z "$join_addr" ]; then
        # For additional instances, modify the ExecStart line while preserving YAML structure
        awk -v join="${join_addr}" '
        /ExecStart=\/usr\/local\/bin\/fusion-server/ {
            indent=$0
            gsub(/[^ ].*$/, "", indent)  # Preserve indentation
            print indent "ExecStart=/usr/local/bin/fusion-server -name %H -addr 0.0.0.0 -port 7946 -join " join
            next
        }
        { print }' "$cloud_init_file" > "${cloud_init_file}.tmp" && mv "${cloud_init_file}.tmp" "$cloud_init_file"
    fi

    echo "$cloud_init_file"
}

# Function to verify instance
verify_instance() {
    local instance_name="$1"
    local max_retries=30
    local retry_count=0
    
    echo "Waiting for instance $instance_name to initialize..."
    
    # Wait for instance to be ready
    while [ $retry_count -lt $max_retries ]; do
        if multipass exec "$instance_name" -- systemctl is-active --quiet fusion-server; then
            echo "fusion-server is running on $instance_name"
            multipass exec "$instance_name" -- systemctl status fusion-server
            echo "Instance info:"
            multipass info "$instance_name"
            
            # Show all listening ports
            echo "Checking listening ports:"
            multipass exec "$instance_name" -- ss -tulpn || true
            return 0
        fi
        
        echo "Waiting for fusion-server to start (attempt $((retry_count + 1))/$max_retries)..."
        sleep 10
        ((retry_count++))
    done
    
    echo "Error: fusion-server failed to start on $instance_name after $max_retries attempts"
    multipass exec "$instance_name" -- systemctl status fusion-server || true
    multipass exec "$instance_name" -- journalctl -u fusion-server --no-pager || true
    return 1
}

# Launch first instance
FIRST_INSTANCE="${BASE_NAME}1"
echo "Launching first instance: $FIRST_INSTANCE"
cloud_init_file=$(create_cloud_init "$FIRST_INSTANCE" "")
if ! multipass launch --name "$FIRST_INSTANCE" --cloud-init "$cloud_init_file" --memory 2G --cpus 2; then
    echo "Failed to launch first instance"
    exit 1
fi

# Verify first instance
if ! verify_instance "$FIRST_INSTANCE"; then
    echo "Failed to verify first instance"
    exit 1
fi

# Get the IP of the first instance
FIRST_IP=$(multipass info "$FIRST_INSTANCE" | grep IPv4 | head -1 | awk '{print $2}')
echo "First instance IP: $FIRST_IP"

# Launch additional instances if requested
if [ "$NUM_INSTANCES" -gt 1 ]; then
    for i in $(seq 2 "$NUM_INSTANCES"); do
        INSTANCE_NAME="${BASE_NAME}${i}"
        echo "Launching instance $i: $INSTANCE_NAME"
        cloud_init_file=$(create_cloud_init "$INSTANCE_NAME" "${FIRST_IP}:7946")
        
        if ! multipass launch --name "$INSTANCE_NAME" --cloud-init "$cloud_init_file" --memory 2G --cpus 2; then
            echo "Failed to launch instance $INSTANCE_NAME"
            continue
        fi
        
        if ! verify_instance "$INSTANCE_NAME"; then
            echo "Failed to verify instance $INSTANCE_NAME"
            continue
        fi
    done
fi

echo "Cluster deployment complete!"
echo "Created instances with base name '$BASE_NAME':"
multipass list
