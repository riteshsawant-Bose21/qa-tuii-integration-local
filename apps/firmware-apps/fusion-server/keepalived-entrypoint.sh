#!/bin/bash

# Perform variable substitution
sed "s/\${NETWORK_PREFIX}/$NETWORK_PREFIX/g" /tmp/keepalived.conf > /usr/local/etc/keepalived/keepalived.conf

# Ensure Keepalived uses our configuration
export KEEPALIVED_COMMAND="--dont-fork --log-console --log-detail --log-facility 7 --vrrp -f /usr/local/etc/keepalived/keepalived.conf"

# Run the original entrypoint
exec /container/tool/run