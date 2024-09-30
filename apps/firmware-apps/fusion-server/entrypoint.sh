#!/bin/sh

# Function to start a process
start_process() {
    echo "Starting $1..."
    $@ &
    echo $! > /var/run/$1.pid
}

# Function to stop a process
stop_process() {
    if [ -f /var/run/$1.pid ]; then
        pid=$(cat /var/run/$1.pid)
        if kill -0 $pid 2>/dev/null; then
            echo "Stopping $1 (PID: $pid)..."
            kill $pid
            rm /var/run/$1.pid
        else
            echo "$1 is not running."
            rm /var/run/$1.pid
        fi
    else
        echo "$1 is not running."
    fi
}

# Function to check if a process is running
is_running() {
    if [ -f /var/run/$1.pid ]; then
        pid=$(cat /var/run/$1.pid)
        if kill -0 $pid 2>/dev/null; then
            return 0
        else
            rm /var/run/$1.pid
            return 1
        fi
    else
        return 1
    fi
}

# Stop any existing processes
stop_process keepalived

# Start processes
start_process keepalived -n -l -D -f ${KEEPALIVED_CONF}

# Wait for any process to exit
wait -n

# Check which process exited
for process in keepalived haproxy fusion-gossip; do
    if ! is_running $process; then
        echo "$process exited unexpectedly"
        exit 1
    fi
done

# If we get here, all processes are still running
echo "All processes exited unexpectedly"
exit 1