
# List time machine entries
curl --request GET \
     --url http://192.168.2.100:8080/time-machine

# Delete time machine entry
curl --request DELETE \
     --url http://192.168.2.100:8080/time-machine/:name

# Create time machine entry
curl --request POST \
     --url http://192.168.2.100:8080/time-machine/:name

# Activate time machine entry
curl --request POST \
  --url http://192.168.2.100:8080/time-machine/activate/:name

# Get active time machine entry
curl --request GET \
  --url http://192.168.2.100:8080/time-machine/meta/active

# Set data
curl --request POST \
     --url http://192.168.2.100:8080/value \
     --header "Content-Type: application/json" \
     --data-binary @analog_in_config.json

# Get time machine entry data
curl --request GET \
     --url http://192.168.2.100:8080/time-machine/:name | jq .


devices[0].dsp_static_config.parameter_settings[*]