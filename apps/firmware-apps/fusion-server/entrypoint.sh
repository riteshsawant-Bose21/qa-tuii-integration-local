#!/bin/sh

# Remove stale PID file if it exists
rm -f /run/keepalived/keepalived.pid

keepalived -n -l -D -f ${KEEPALIVED_CONF} &
KEEPALIVED_PID=$!

haproxy -f /etc/haproxy/haproxy.cfg -db &
HAPROXY_PID=$!

# Start fusion-server
/app/fusion-server "$@" &
FUSION_PID=$!

# Wait for any process to exit
wait -n

# Check which process exited
if ! kill -0 $KEEPALIVED_PID 2>/dev/null; then
   echo "Keepalived exited unexpectedly"
elif ! kill -0 $HAPROXY_PID 2>/dev/null; then
   echo "HAProxy exited unexpectedly"
elif ! kill -0 $FUSION_PID 2>/dev/null; then
   echo "fusion-server exited unexpectedly"
fi

# Exit with status of process that exited first
exit $?