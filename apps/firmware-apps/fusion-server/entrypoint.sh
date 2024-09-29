#!/bin/sh

echo "Starting entrypoint script"

# Generate Keepalived config
echo "Generating Keepalived config"
KEEPALIVED_CONF="/etc/keepalived/keepalived.conf"

echo "Creating new keepalived.conf"
cat << EOF > ${KEEPALIVED_CONF}
vrrp_instance VI_1 {
    state BACKUP
    interface eth0
    virtual_router_id 51
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        ${SERVICE_IP}
    }
}
EOF

# Ensure the file was created
if [ ! -f "${KEEPALIVED_CONF}" ]; then
    echo "Failed to create keepalived.conf"
    exit 1
fi

# Start Keepalived
echo "Starting Keepalived"
keepalived -n -l -D -f ${KEEPALIVED_CONF} &
KEEPALIVED_PID=$!

# Start HAProxy
echo "Starting HAProxy"
haproxy -f /etc/haproxy/haproxy.cfg -db &
HAPROXY_PID=$!

# Add a delay before starting fusion-gossip
sleep 5

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
