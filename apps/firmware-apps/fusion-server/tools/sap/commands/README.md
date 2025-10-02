# Play a tone 
ffmpeg -re \
  -f lavfi -i sine=frequency=1000 \
  -c:a pcm_s16le \
  -f sap \
  "sap://224.2.127.254:5004?announce_port=9875&ttl=1"


ffmpeg -re \
  -f lavfi -i sine=frequency=440 \
  -f rtp -payload_type 96 -sdp_file test.sdp \
  -muxrate 100k -flags +global_header \
  "rtp://224.2.127.254:5004?ttl=1"

# Listen to the stream
fplay \
  -protocol_whitelist file,udp,rtp \
  -i test.sdp
