#!/bin/sh
set -e

keepalived -n -l -D \
    -f /home/ubuntu/keepalived/keepalived.conf \
    --log-console \
    --log-detail \
    --dump-conf &

# Give Keepalived time to initialize
sleep 2

# Start HAProxy with proper logging
haproxy -f /home/ubuntu/haproxy/haproxy.cfg \
    -db \
    -V \
    -L localhost \
    -m 1024 &

# Start fusion-server
/app/fusion-server "$@" &
