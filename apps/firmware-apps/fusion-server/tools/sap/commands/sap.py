#!/usr/bin/env python3

import socket
import struct
import argparse
import time
import hashlib

def build_sap_packet(stream_ip, stream_port, stream_name, origin_ip, delete=False):
    # SDP payload
    sdp_payload = f"""v=0
o=- 123456 1 IN IP4 {stream_ip}
s={stream_name}
c=IN IP4 {stream_ip}/32
t=0 0
m=audio {stream_port} RTP/AVP 0
""".encode('utf-8')

    # SAP header flags
    flags = 0x20  # Version=1, no compression/auth
    if delete:
        flags |= 0x10  # Set delete bit

    # Calculate a hash of the SDP payload (first 16 bits of MD5)
    msg_id_hash = int.from_bytes(hashlib.md5(sdp_payload).digest()[:2], 'big')

    sap_header = bytearray()
    sap_header.append(flags)
    sap_header.append(0x00)  # AuthLen = 0
    sap_header += msg_id_hash.to_bytes(2, 'big')
    sap_header += socket.inet_aton(origin_ip)

    return sap_header + sdp_payload

def send_sap_announcement(multicast_ip, port, message):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
    sock.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, 1)
    sock.sendto(message, (multicast_ip, port))
    sock.close()

# python3 sap.py --add --name "Test Stream 2" --stream-ip 239.255.255.250 --stream-port 5004
# python3 sap.py --delete --name "Test Stream 2" --stream-ip 239.255.255.250 --stream-port 5004
def main():
    parser = argparse.ArgumentParser(description="SAP Announcement Tool")
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument('--add', action='store_true', help="Add an announcement")
    action.add_argument('--remove', action='store_true', help="Remove an announcement")

    parser.add_argument('--name', default='Test Stream', help="Stream name (default: Test Stream)")
    parser.add_argument('--stream-ip', default='239.255.255.250', help="Multicast stream IP")
    parser.add_argument('--stream-port', type=int, default=5004, help="Stream port (default: 5004)")
    parser.add_argument('--sap-ip', default='224.2.127.254', help="SAP multicast group (default: 224.2.127.254)")
    parser.add_argument('--sap-port', type=int, default=9875, help="SAP port (default: 9875)")
    parser.add_argument('--origin-ip', default='0.0.0.0', help="Originating IP address")

    args = parser.parse_args()

    message = build_sap_packet(
        stream_ip=args.stream_ip,
        stream_port=args.stream_port,
        stream_name=args.name,
        origin_ip=args.origin_ip,
        delete=args.remove
    )

    send_sap_announcement(args.sap_ip, args.sap_port, message)

    print("Sent SAP {} announcement.".format("remove" if args.remove else "add"))

if __name__ == "__main__":
    main()