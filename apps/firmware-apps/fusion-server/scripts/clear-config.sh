#!/bin/bash

# API server address
API_PORT="8080"
API_SERVER="192.168.2.100"

# Fetch devices from the API server
device_data=$(curl -s http://$API_SERVER:$API_PORT/devices)

# Loop over each device address and clear runtime audio settings.
# /devices now returns a wrapped response shape: {"devices":[...]}.
echo "$device_data" | jq -r '(.devices // .)[] | select(.address != "") | .address' | while read -r address; do
  echo "Sending DELETE to http://$address:$API_PORT/settings/audio"
  curl -X DELETE "http://$address:$API_PORT/settings/audio"
  echo -e "\n---"
done
