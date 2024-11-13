#!/bin/bash
set -e

# Function to check and enable IP forwarding
check_ip_forwarding() {
    if [[ "$(uname)" == "Darwin" ]]; then  # Check if running on macOS
        if [ $(sysctl -n net.inet.ip.forwarding) -eq 0 ]; then
            echo "Enabling IP forwarding..."
            if ! sudo sysctl -w net.inet.ip.forwarding=1; then
                echo "Failed to enable IP forwarding. Please run script with sudo or enable manually."
                exit 1
            fi
            echo "IP forwarding enabled successfully."
        fi
    fi
}

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
            shift 2
            ;;
        --kill)
            KILL_MODE=true
            shift
            ;;
        *)
            usage
            ;;
    esac
done

# Handle kill mode first
if [ "$KILL_MODE" = true ]; then
    echo "Stopping and removing instances with base name: $BASE_NAME"
    for instance in $(multipass list --format csv | grep "^$BASE_NAME" | cut -d',' -f1); do
        echo "Deleting instance: $instance"
        multipass delete "$instance"
    done
    multipass purge
    echo "Cleanup complete"
    exit 0
fi

# Check IP forwarding before proceeding
check_ip_forwarding

# Check for the fusion-server binary and build if not found
if [ ! -f "build/fusion-server" ]; then
    echo "fusion-server binary not found in build directory"
    echo "Running build.sh to generate binary..."
    if [ ! -f "build.sh" ]; then
        echo "Error: build.sh script not found"
        exit 1
    fi
    
    if ! ./build.sh; then
        echo "Error: build.sh failed to generate binary"
        exit 1
    fi
    
    if [ ! -f "build/fusion-server" ]; then
        echo "Error: build.sh completed but binary still not found"
        exit 1
    fi
    
    echo "Successfully built fusion-server binary"
fi

# Function to setup and activate Python virtual environment
setup_python_env() {
    
    # Check if virtual environment exists
    if [ ! -d "fusion-env" ]; then
        echo "Creating new Python virtual environment..."
        python3 -m venv fusion-env
        if [ $? -ne 0 ]; then
            echo "Failed to create virtual environment"
            exit 1
        fi
    fi

    # Activate virtual environment
    echo "Activating Python virtual environment..."
    source fusion-env/bin/activate
    if [ $? -ne 0 ]; then
        echo "Failed to activate virtual environment"
        exit 1
    fi

    # Install PyYAML if not already installed
    if ! python3 -c "import yaml" 2>/dev/null; then
        echo "Installing PyYAML..."
        python3 -m pip install PyYAML
        if [ $? -ne 0 ]; then
            echo "Failed to install PyYAML"
            exit 1
        fi
    fi
}

# Function to generate cloud-init configuration
generate_cloud_init() {
    echo "Generating cloud-init configuration..."
    ./scripts/generate_cloud_config.py > fusion-server.yaml
}

# Add the Python environment setup and cloud-init generation before starting the cluster deployment
echo "Starting cluster deployment..."
echo "Base name: $BASE_NAME"
echo "Number of instances: $NUM_INSTANCES"

# Setup Python environment
setup_python_env

# Start Python HTTP server in background
IP_ADDR=$(ifconfig | grep -A 1 "192.168.64" | grep "inet " | awk '{print $2}')
echo "Starting download server on $IP_ADDR:8000"
python3 -m http.server 8000 > /dev/null 2>&1 &
PYTHON_PID=$!

# Generate cloud-init configuration
generate_cloud_init

# Function to handle cleanup when script exits
cleanup() {
    # Only perform cleanup if not already in progress
    if [ -z "$CLEANUP_IN_PROGRESS" ]; then
        CLEANUP_IN_PROGRESS=1
        echo
        echo "Cleaning up..."
        if [ ! -z "$PYTHON_PID" ]; then
            # Send SIGTERM and wait for process to exit
            kill -TERM $PYTHON_PID 2>/dev/null
            wait $PYTHON_PID 2>/dev/null
            echo "Stopped download server"
        fi
        
        # Clean up temporary cloud-init files
        echo "Cleaning up temporary cloud-init files..."
        rm -f /tmp/cloud-init-${BASE_NAME}*.yaml

        # Deactivate Python virtual environment if it's active
        if [ -n "$VIRTUAL_ENV" ]; then
            deactivate
            echo "Deactivated Python virtual environment"
        fi
    fi
}

# Set up more comprehensive signal handling
trap 'cleanup' EXIT
trap 'exit 2' INT TERM

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
if ! multipass launch --name "$FIRST_INSTANCE" --cloud-init "$cloud_init_file" --memory 2G --cpus 2 ; then
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
