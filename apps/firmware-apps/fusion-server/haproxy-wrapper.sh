#!/bin/sh

if [ "$1" = "service" ] && [ "$2" = "haproxy" ] && [ "$3" = "reload" ]; then
    echo "Reloading HAProxy"
    haproxy -f /etc/haproxy/haproxy.cfg -sf $(cat /var/run/haproxy.pid)
else
    exec "$@"
fi
