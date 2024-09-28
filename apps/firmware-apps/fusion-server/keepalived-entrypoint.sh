#!/bin/bash

echo "Starting entrypoint script" >> /tmp/entrypoint.log
ls -l /tmp/keepalived.conf >> /tmp/entrypoint.log
cat /tmp/keepalived.conf >> /tmp/entrypoint.log
echo "Copying and modifying config file" >> /tmp/entrypoint.log

# Perform variable substitution
sed "s/\${NETWORK_PREFIX}/$NETWORK_PREFIX/g" /tmp/keepalived.conf > /usr/local/etc/keepalived/keepalived.conf

echo "Config file copied and modified" >> /tmp/entrypoint.log
ls -l /usr/local/etc/keepalived/keepalived.conf >> /tmp/entrypoint.log
cat /usr/local/etc/keepalived/keepalived.conf >> /tmp/entrypoint.log

# Ensure Keepalived uses our configuration
export KEEPALIVED_COMMAND="--dont-fork --log-console --log-detail --log-facility 7 --vrrp -f /usr/local/etc/keepalived/keepalived.conf"

# Run the original entrypoint
exec /container/tool/run