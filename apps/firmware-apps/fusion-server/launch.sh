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
    echo "  --verbose   : Show detailed status output during setup and verification"
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

# Function to handle cleanup when script exits
cleanup() {
    echo
    echo "Cleaning up..."
    
    # Clean up temporary cloud-init files
    echo "Cleaning up temporary cloud-init files..."
    rm -f /tmp/cloud-init-${BASE_NAME}*.yaml
    
    # Deactivate Python virtual environment if it's active
    if [ -n "$VIRTUAL_ENV" ]; then
        deactivate
        echo "Deactivated Python virtual environment"
    fi
}

# Function to display instance status
show_instance_status() {
    local instance_name="$1"
    
    echo "Instance Status:"
    echo "==============="
    
    # Show network status
    echo "Network Configuration:"
    multipass exec "$instance_name" -- networkctl status
    
    # Show service status
    echo
    echo "Service Status:"
    for service in fusion-server keepalived haproxy; do
        echo
        echo "=== $service ==="
        multipass exec "$instance_name" -- systemctl status "$service" --no-pager || true
    done
    
    # Show IP configuration
    echo
    echo "IP Configuration:"
    multipass exec "$instance_name" -- ip addr show

    # Show process list
    echo
    echo "Process Status:"
    multipass exec "$instance_name" -- ps aux | grep -E 'fusion-server|keepalived|haproxy' || true
}

# Function to setup instance
setup_instance() {
    local instance_name="$1"
    local instance_number="$2"
    
    echo "Setting up instance: $instance_name (number: $instance_number)"
    
    # Wait a bit for the instance to be ready
    echo "Waiting for instance to initialize..."
    sleep 10
    
    # Copy fusion-server binary
    echo "Copying fusion-server binary..."
    if ! multipass transfer build/fusion-server "$instance_name":/tmp/; then
        echo "Error: Failed to copy fusion-server binary"
        return 1
    fi
    
    # Install binary and set permissions
    echo "Installing binary..."
    if ! multipass exec "$instance_name" -- sudo cp /tmp/fusion-server /usr/local/bin/ || \
       ! multipass exec "$instance_name" -- sudo chmod 755 /usr/local/bin/fusion-server || \
       ! multipass exec "$instance_name" -- rm /tmp/fusion-server; then
        echo "Error: Failed to install fusion-server binary"
        return 1
    fi
    
    # Update keepalived priority based on instance number
    echo "Configuring keepalived priority..."
    local priority=$((100 - instance_number))
    multipass exec "$instance_name" -- sudo sed -i "s/priority 100/priority ${priority}/" /etc/keepalived/keepalived.conf
    
    # Start services
    echo "Starting services..."
    if ! multipass exec "$instance_name" -- sudo systemctl daemon-reload || \
       ! multipass exec "$instance_name" -- sudo systemctl enable --now fusion-server || \
       ! multipass exec "$instance_name" -- sudo systemctl enable --now keepalived || \
       ! multipass exec "$instance_name" -- sudo systemctl enable --now haproxy; then
        echo "Error: Failed to start services"
        return 1
    fi
    
    # Show instance status
    [ "$VERBOSE" = true ] && show_instance_status "$instance_name"
    
    return 0
}

# Function to verify instance services
verify_instance() {
    local instance_name="$1"
    local max_retries=30
    local retry_count=0
    
    echo "Verifying instance $instance_name..."
    
    echo "Verifying services..."
    while [ $retry_count -lt $max_retries ]; do
        # Check if binary exists
        if ! multipass exec "$instance_name" -- test -x /usr/local/bin/fusion-server; then
            echo "Waiting for fusion-server binary (attempt $((retry_count + 1))/$max_retries)..."
            sleep 5
            ((retry_count++))
            continue
        fi
        
        # Check services one by one
        local all_services_running=true
        for service in fusion-server keepalived haproxy; do
            if ! multipass exec "$instance_name" -- systemctl is-active --quiet "$service"; then
                echo "Service $service is not running"
                all_services_running=false
                break
            fi
        done
        
        if [ "$all_services_running" = true ]; then
            echo "All services are running on $instance_name"
            # Verify VIP is accessible and capture the response
            echo "Checking VIP accessibility..."
            local response
            response=$(multipass exec "$instance_name" -- curl -sf http://192.168.64.100:8080 2>/dev/null)
            if [ $? -eq 0 ]; then
                echo "VIP is accessible"
                echo "Server response: $response"
                return 0
            else
                echo "Warning: VIP is not accessible yet (attempt $((retry_count + 1))/$max_retries)"
            fi
        fi
        
        echo "Waiting for services to start (attempt $((retry_count + 1))/$max_retries)..."
        sleep 5
        ((retry_count++))
    done
    
    echo "Error: services failed to start on $instance_name after $max_retries attempts"
    # Show full status on failure
    show_instance_status "$instance_name"
    return 1
}

# Function to launch instance
launch_instance() {
    local instance_name="$1"
    local instance_number="$2"
    local join_addr="$3"
    local cloud_init_file="/tmp/cloud-init-${instance_name}.yaml"
    
    # Copy base cloud-init and modify if needed
    cp fusion-server.yaml "$cloud_init_file"
    
    if [ ! -z "$join_addr" ]; then
        # Modify the fusion-server service to include join address
        sed -i.bak "s|ExecStart=/usr/local/bin/fusion-server.*|ExecStart=/usr/local/bin/fusion-server -name %H -addr 0.0.0.0 -port 7946 -join ${join_addr}|" "$cloud_init_file"
    fi
    
    echo "Launching instance: $instance_name"
    if ! multipass launch --name "$instance_name" --cloud-init "$cloud_init_file" --memory 2G --cpus 2; then
        echo "Failed to launch instance $instance_name"
        return 1
    fi
    echo "Launched: $instance_name"
    
    # Setup the instance
    if ! setup_instance "$instance_name" "$instance_number"; then
        echo "Failed to setup instance $instance_name"
        return 1
    fi
    
    # Verify the instance
    if ! verify_instance "$instance_name"; then
        echo "Failed to verify instance $instance_name"
        return 1
    fi
    
    return 0
}

# Set up trap but don't exit on errors
trap cleanup EXIT

echo "Starting cluster deployment..."
echo "Base name: $BASE_NAME"
echo "Number of instances: $NUM_INSTANCES"

# Setup Python environment
if [ ! -d "fusion-env" ]; then
    python3 -m venv fusion-env
fi
echo "Activating Python virtual environment..."
source fusion-env/bin/activate

# Generate base cloud-init
echo "Generating cloud-init configuration..."
./scripts/generate_cloud_config.py > fusion-server.yaml

# Launch first instance
FIRST_INSTANCE="${BASE_NAME}1"
if ! launch_instance "$FIRST_INSTANCE" 1 ""; then
    echo "Failed to launch first instance"
    exit 1
fi

# Get the IP of the first instance
FIRST_IP=$(multipass info "$FIRST_INSTANCE" | grep IPv4 | head -1 | awk '{print $2}')
echo "First instance IP: $FIRST_IP"

# Launch additional instances if requested
if [ "$NUM_INSTANCES" -gt 1 ]; then
    for i in $(seq 2 "$NUM_INSTANCES"); do
        INSTANCE_NAME="${BASE_NAME}${i}"
        if ! launch_instance "$INSTANCE_NAME" "$i" "${FIRST_IP}:7946"; then
            echo "Failed to launch instance $INSTANCE_NAME"
            continue
        fi
    done
fi

echo "Cluster deployment complete!"
echo "Created instances with base name '$BASE_NAME':"
multipass list
