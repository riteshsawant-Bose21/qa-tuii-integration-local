
# List snapshots
curl --request GET \
     --url http://192.168.2.100:8080/snapshots

# Delete snapshot
curl --request DELETE \
     --url http://192.168.2.100:8080/snapshots/:name

# Create snapshot
curl --request POST \
     --url http://192.168.2.100:8080/snapshots/:name

# Activate snapshot
curl --request POST \
  --url http://192.168.2.100:8080/snapshots/activate/:name

# Get active snapshot
curl --request GET \
  --url http://192.168.2.100:8080/snapshots/meta/active

# Set data
curl --request POST \
     --url http://192.168.2.100:8080/value \
     --header "Content-Type: application/json" \
     --data-binary @analog_in_config.json

# Get snapshot data
curl --request GET \
     --url http://192.168.2.100:8080/snapshots/:name | jq .


devices[0].dsp_static_config.parameter_settings[*]