#!/bin/bash

# API server address
API_PORT="8080"
API_SERVER="192.168.2.100"

# Fetch devices from the API server
device_data=$(curl -s http://$API_SERVER:$API_PORT/devices)

# Loop over each device address and issue a DELETE request to its /config endpoint
echo "$device_data" | jq -r '.[] | select(.address != "") | .address' | while read -r address; do
  echo "Sending DELETE to http://$address:$API_PORT/value"
  curl -X DELETE "http://$address:$API_PORT/value"
  echo -e "\n---"
done
