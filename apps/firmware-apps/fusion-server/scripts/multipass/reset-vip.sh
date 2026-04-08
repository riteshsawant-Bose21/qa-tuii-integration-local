#!/bin/bash

set -euo pipefail

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Reset the current Multipass Fusion cluster back to a single target VIP without
recreating instances.

Options:
    --prefix PREFIX     Instance name prefix (default: fusion)
    --vip VIP           Target VIP to write and apply on all nodes
                        (default: 192.168.2.100)
    -h, --help          Show this help text

Examples:
    $0
    $0 --vip 192.168.2.101
    $0 --prefix test --vip 192.168.2.100
EOF
    exit 0
}

PREFIX="fusion"
TARGET_VIP="192.168.2.100"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prefix)
            PREFIX="${2:?Error: --prefix requires a value}"
            shift 2
            ;;
        --vip)
            TARGET_VIP="${2:?Error: --vip requires a value}"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Use --help for usage."
            exit 1
            ;;
    esac
done

instances_csv=$(multipass list --format csv | tail -n +2 || true)
if [[ -z "$instances_csv" ]]; then
    echo "No multipass instances found"
    exit 1
fi

instances=()
instance_ips=()
while IFS=',' read -r name state ipv4 _; do
    [[ "$name" =~ ^$PREFIX ]] || continue
    first_ip="${ipv4%% *}"
    if [[ -z "$first_ip" || "$first_ip" == "--" ]]; then
        echo "Skipping $name: no IPv4 address reported by multipass"
        continue
    fi
    instances+=("$name")
    instance_ips+=("$first_ip")
done <<< "$instances_csv"

if [[ ${#instances[@]} -eq 0 ]]; then
    echo "No multipass instances found with prefix '$PREFIX'"
    exit 1
fi

echo "Resetting VIP across instances with prefix '$PREFIX' to $TARGET_VIP"
echo

for i in "${!instances[@]}"; do
    name="${instances[$i]}"
    ip="${instance_ips[$i]}"
    echo "Writing VIP config on $name ($ip)"
    curl -fsS -m 5 -X POST "http://$ip:9090/devices/vip/$TARGET_VIP" >/dev/null
done

echo

for i in "${!instances[@]}"; do
    name="${instances[$i]}"
    ip="${instance_ips[$i]}"
    echo "Applying VIP config on $name ($ip)"
    curl -fsS -m 10 -X POST "http://$ip:9090/device/reload/vip" >/dev/null
done

echo
echo "Verification:"

candidate_vips=("$TARGET_VIP" "192.168.2.100" "192.168.2.101" "192.168.2.102")
seen=""
unique_candidates=()
for vip in "${candidate_vips[@]}"; do
    [[ " $seen " == *" $vip "* ]] && continue
    seen+=" $vip"
    unique_candidates+=("$vip")
done

for vip in "${unique_candidates[@]}"; do
    echo "=== $vip ==="
    curl -m 2 -sS "http://$vip:8080/devices/vip" || true
    echo
    echo
done

echo "Done."
