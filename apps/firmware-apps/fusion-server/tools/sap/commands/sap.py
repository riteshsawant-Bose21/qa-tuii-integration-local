import socket
import struct

multicast_group = '224.2.127.254'
port = 9875

# 1 byte VARTEC, 1 byte AuthLen, 2 bytes MsgIdHash, 4 bytes Origin
sap_header = bytearray()
sap_header.append(0x20)                    # Version=1, no compression/auth
sap_header.append(0x00)                    # auth len = 0
sap_header += (0).to_bytes(2, 'big')       # MsgIdHash = 0
sap_header += socket.inet_aton('0.0.0.0')  # Origin IP = 0.0.0.0

sdp_payload = b"""v=0
o=- 123456 1 IN IP4 239.255.255.250
s=Test Stream
c=IN IP4 239.255.255.250/32
t=0 0
m=audio 5004 RTP/AVP 0
"""

message = sap_header + sdp_payload

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
sock.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, 1)
sock.sendto(message, (multicast_group, port))
print("Sent SAP announcement.")
