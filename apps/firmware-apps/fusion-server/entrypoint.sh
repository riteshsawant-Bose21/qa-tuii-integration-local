#!/bin/sh

echo "Starting entrypoint script"

# Start Keepalived
echo "Starting Keepalived"
keepalived -n -l -D -f ${KEEPALIVED_CONF} &
KEEPALIVED_PID=$!

# Start HAProxy
echo "Starting HAProxy"
haproxy -f /etc/haproxy/haproxy.cfg -db &
HAPROXY_PID=$!

# Start fusion-gossip
echo "Starting fusion-gossip"
/app/fusion-gossip "$@" &
FUSION_PID=$!

# Print process IDs for debugging
echo "Keepalived PID: $KEEPALIVED_PID"
echo "HAProxy PID: $HAPROXY_PID"
echo "fusion-gossip PID: $FUSION_PID"

# Wait for any process to exit
wait -n

# Check which process exited
if ! kill -0 $KEEPALIVED_PID 2>/dev/null; then
    echo "Keepalived exited unexpectedly"
elif ! kill -0 $HAPROXY_PID 2>/dev/null; then
    echo "HAProxy exited unexpectedly"
elif ! kill -0 $FUSION_PID 2>/dev/null; then
    echo "fusion-gossip exited unexpectedly"
fi

# Exit with status of process that exited first
exit $?
