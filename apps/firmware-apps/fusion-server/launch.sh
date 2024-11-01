#!/bin/bash

# Function to handle cleanup when script exits
cleanup() {
    echo "Cleaning up..."
    # Kill the Python HTTP server running in background
    if [ ! -z "$PYTHON_PID" ]; then
        kill $PYTHON_PID
        echo "Stopped Python HTTP server"
    fi
    exit 0
}

# Set up trap to catch script termination
trap cleanup SIGINT SIGTERM

# Function to kill existing process on port 8000
kill_existing_process() {
    local pid=$(lsof -t -i:8000)
    if [ ! -z "$pid" ]; then
        echo "Found existing process on port 8000 (PID: $pid)"
        echo "Attempting to terminate existing process..."
        kill $pid
        sleep 2
        if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null ; then
            echo "Failed to free up port 8000. Please check the process manually."
            exit 1
        fi
        echo "Successfully terminated existing process"
    fi
}

# Function to check and handle port availability
check_port() {
    if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null ; then
        echo "Port 8000 is in use"
        read -p "Do you want to terminate the existing process and restart? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            kill_existing_process
        else
            echo "Exiting script"
            exit 1
        fi
    fi
}

# Function to start Python HTTP server
start_python_server() {
    echo "Starting Python HTTP server..."
    python3 -m http.server 8000 --bind 0.0.0.0 &
    PYTHON_PID=$!
    
    # Wait briefly to ensure server starts
    sleep 2
    
    # Check if server started successfully
    if ! ps -p $PYTHON_PID > /dev/null; then
        echo "Error: Failed to start Python HTTP server"
        exit 1
    fi
    echo "Python HTTP server started successfully (PID: $PYTHON_PID)"
}

# Function to check and handle multipass instance
handle_multipass_instance() {
    # Check if cloud-init file exists
    if [ ! -f "fusion-server.yaml" ]; then
        echo "Error: fusion-server.yaml not found in current directory"
        cleanup
        exit 1
    fi

    # Check if instance already exists
    if multipass info fs1 &>/dev/null; then
        echo "Multipass instance 'fs1' already exists"
        read -p "Do you want to delete and recreate it? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Deleting existing instance..."
            multipass delete fs1
            multipass purge
            echo "Existing instance deleted"
        else
            echo "Using existing instance"
            return
        fi
    fi

    # Launch new instance
    echo "Launching new multipass instance 'fs1'..."
    if ! multipass launch --name fs1 --cloud-init fusion-server.yaml; then
        echo "Error: Failed to launch multipass instance"
        cleanup
        exit 1
    fi
    echo "Multipass instance launched successfully"
    
    # Wait for instance to be ready
    echo "Waiting for instance to initialize..."
    sleep 10
}

# Main execution
echo "Starting server monitoring script..."

# Check if port 8000 is available
check_port

# Start Python HTTP server
start_python_server

# Handle multipass instance
handle_multipass_instance

# Monitor instance status
echo "Multipass instance 'fs1' is running"
multipass info fs1

# Clean up and exit
cleanup
