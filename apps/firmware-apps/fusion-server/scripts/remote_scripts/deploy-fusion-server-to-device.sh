#!/bin/bash
# filepath: deploy-fusion-server.sh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
BUILD_SCRIPT="./build-fusion-server"
BUILD_DIR="./build"
BINARY_NAME="fusion-server_linux_arm64"
REMOTE_PATH="/usr/local/bin/fusion-server"
SERVICE_NAME="fusion-server"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to validate remote host
validate_remote() {
    local remote=$1
    print_status "Validating connection to $remote..."
    
    if ssh -o ConnectTimeout=10 "$remote" exit 2>/dev/null; then
        print_success "Connection to $remote validated"
        return 0
    else
        print_error "Cannot connect to $remote"
        return 1
    fi
}

# Function to stop remote service
stop_remote_service() {
    local remote=$1
    print_status "Stopping $SERVICE_NAME service on $remote..."
    
    if ssh "$remote" "systemctl stop $SERVICE_NAME" 2>/dev/null; then
        print_success "Service stopped successfully"
    else
        print_warning "Failed to stop service (may not be running)"
    fi
}

# Function to build locally
build_local() {
    print_status "Building fusion-server locally..."
    
    if [ ! -f "$BUILD_SCRIPT" ]; then
        print_error "Build script not found: $BUILD_SCRIPT"
        exit 1
    fi
    
    if ! chmod +x "$BUILD_SCRIPT"; then
        print_error "Failed to make build script executable"
        exit 1
    fi
    
    if "$BUILD_SCRIPT"; then
        print_success "Build completed successfully"
    else
        print_error "Build failed"
        exit 1
    fi
}

# Function to verify binary exists
verify_binary() {
    local binary_path="$BUILD_DIR/$BINARY_NAME"
    
    if [ ! -f "$binary_path" ]; then
        print_error "Binary not found: $binary_path"
        print_status "Available files in build directory:"
        ls -la "$BUILD_DIR" 2>/dev/null || print_error "Build directory not found: $BUILD_DIR"
        exit 1
    fi
    
    print_success "Binary verified: $binary_path"
    local size=$(du -h "$binary_path" | cut -f1)
    print_status "Binary size: $size"
}

# Function to copy binary to remote
copy_binary() {
    local remote=$1
    local local_binary="$BUILD_DIR/$BINARY_NAME"
    
    print_status "Copying binary to $remote:$REMOTE_PATH..."
    
    if scp "$local_binary" "$remote:$REMOTE_PATH"; then
        print_success "Binary copied successfully"
    else
        print_error "Failed to copy binary"
        exit 1
    fi
    
    # Make binary executable on remote
    print_status "Making binary executable on remote..."
    if ssh "$remote" "chmod +x $REMOTE_PATH"; then
        print_success "Binary permissions set"
    else
        print_error "Failed to set binary permissions"
        exit 1
    fi
}

# Function to start remote service
start_remote_service() {
    local remote=$1
    print_status "Starting $SERVICE_NAME service on $remote..."
    
    if ssh "$remote" "systemctl start $SERVICE_NAME"; then
        print_success "Service started successfully"
    else
        print_error "Failed to start service"
        exit 1
    fi
    
    # Wait a moment and check service status
    sleep 2
    print_status "Checking service status..."
    if ssh "$remote" "systemctl is-active --quiet $SERVICE_NAME"; then
        print_success "Service is running"
    else
        print_warning "Service may not be running properly"
        ssh "$remote" "systemctl status $SERVICE_NAME --no-pager -l"
    fi
}

# Function to show service logs
show_logs() {
    local remote=$1
    print_status "Showing recent service logs from $remote..."
    ssh "$remote" "journalctl -u $SERVICE_NAME --no-pager -l -n 20"
}

# Main deployment function
deploy() {
    local remote=$1
    
    echo "======================================"
    echo "    Fusion Server Deployment Script"
    echo "======================================"
    echo "Remote target: $remote"
    echo "Binary: $BINARY_NAME"
    echo "Service: $SERVICE_NAME"
    echo "======================================"
    echo
    
    # Validate prerequisites
    if ! command_exists ssh; then
        print_error "ssh command not found"
        exit 1
    fi
    
    if ! command_exists scp; then
        print_error "scp command not found"
        exit 1
    fi
    
    # Execute deployment steps
    validate_remote "$remote"
    stop_remote_service "$remote"
    build_local
    verify_binary
    copy_binary "$remote"
    start_remote_service "$remote"
    
    echo
    print_success "Deployment completed successfully!"
    echo
    
    # Ask if user wants to see logs
    read -p "Would you like to see recent service logs? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        show_logs "$remote"
    fi
}

# Script usage
usage() {
    echo "Usage: $0 <remote-host>"
    echo
    echo "Examples:"
    echo "  $0 root@192.168.1.3"
    echo
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo
}

# Parse command line arguments
SHOW_LOGS_AFTER=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -l|--logs)
            SHOW_LOGS_AFTER=true
            shift
            ;;
        -*)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            REMOTE_HOST="$1"
            shift
            ;;
    esac
done

# Check if remote host is provided
if [ -z "$REMOTE_HOST" ]; then
    print_error "Remote host not specified"
    usage
    exit 1
fi

# Confirm deployment
echo -e "${YELLOW}Warning: This will stop the service, rebuild, and deploy to $REMOTE_HOST${NC}"
read -p "Continue? [y/N]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Deployment cancelled"
    exit 0
fi

# Run deployment
deploy "$REMOTE_HOST"