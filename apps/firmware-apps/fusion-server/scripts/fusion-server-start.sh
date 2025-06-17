#!/bin/sh

# Script used by systemd to launch fusion-server

get_ip_addr() {
    # Try to use the ip command if available
    if command -v ip >/dev/null 2>&1; then
        # Get the interface from the default route (works in many cases)
        iface=$(ip route list 0.0.0.0/0 2>/dev/null | awk '{print $5; exit}')
        # If no default route was found, grab the first non-loopback interface with an IP
        if [ -z "$iface" ]; then
            iface=$(ip -o addr show | awk '!/ lo / && /inet / {print $2; exit}')
        fi
        # Extract the IPv4 address (strip the CIDR suffix)
        ip_addr=$(ip addr show "$iface" | awk '/inet / { sub(/\/.*/, "", $2); print $2; exit }')
        echo "$ip_addr"
        return
    fi

    # If ip isn't available, try ifconfig (commonly found in BusyBox)
    if command -v ifconfig >/dev/null 2>&1; then
        # Pick the first non-loopback interface
        iface=$(ifconfig | awk '/^[a-zA-Z0-9]/ {print $1; exit}')
        # Extract the IP address.
        # This covers both BusyBox and Linux distributions that show either "inet addr:" or "inet"
        ip_addr=$(ifconfig "$iface" | awk '/inet / {
            for(i=1;i<=NF;i++){
                if ($i ~ /addr:/) { split($i,a,":"); print a[2]; exit }
                else if ($i ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) { print $i; exit }
            }
        }')
        echo "$ip_addr"
        return
    fi

    echo "No suitable command found to determine the IP address" >&2
    return 1
}

# Get the IP address and assign it to IP_ADDR
IP_ADDR=$(get_ip_addr)

# Ensure IP is available before starting the server
if [ -z "$IP_ADDR" ]; then
    echo "Error: Could not determine IP address." >&2
    exit 1
fi

echo "Starting fusion-server on IP: $IP_ADDR"

exec /usr/local/bin/fusion-server -bind-addr "$IP_ADDR"
