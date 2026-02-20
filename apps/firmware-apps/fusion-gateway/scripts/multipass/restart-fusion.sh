#!/bin/bash

# restart-fusion.sh
# Restart fusion-gateway on multipass instances matching a prefix.

set -euo pipefail

############################################
# Help
############################################
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Restart the fusion-gateway systemd service on multipass instances.

Options:
    --prefix PREFIX     Instance name prefix (default: fusion)
    -h, --help          Show this help text

Examples:
    $0                       # Restart all 'fusion*' instances
    $0 --prefix test         # Restart all 'test*' instances
EOF
    exit 0
}

############################################
# Parse args
############################################
PREFIX="fusion"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prefix)
            PREFIX="${2:?Error: --prefix requires a value}"
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

############################################
# Find matching instances
############################################
instances=$(multipass list --format csv \
    | tail -n +2 \
    | cut -d',' -f1 \
    | grep "^$PREFIX" || true)

if [[ -z "$instances" ]]; then
    echo "No multipass instances found with prefix '$PREFIX'"
    exit 0
fi

echo "Restarting fusion-gateway on instances with prefix '$PREFIX'..."
echo

############################################
# Restart service on each instance
############################################
for instance in $instances; do
    echo "→ Instance: $instance"

    multipass exec "$instance" -- sudo bash -c "
        set -e
        echo '  Stopping fusion-gateway...'
        systemctl stop fusion-gateway || true

        echo '  Starting fusion-gateway...'
        systemctl start fusion-gateway

        echo '  Checking status:'
        systemctl status fusion-gateway --no-pager || true
    "

    echo
done

echo "All done."
