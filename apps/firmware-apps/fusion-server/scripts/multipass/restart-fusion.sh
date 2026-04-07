#!/bin/bash

# restart-fusion.sh
# Restart fusion-server on multipass instances matching a prefix.

set -euo pipefail

log_step() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

############################################
# Help
############################################
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Restart the fusion-server systemd service on multipass instances.

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

log_step "Step 1/2: Found matching instances for prefix '$PREFIX'"
for instance in $instances; do
    echo "  - $instance"
done
echo
log_step "Step 2/2: Restarting fusion-server on each instance"
echo

############################################
# Restart service on each instance
############################################
for instance in $instances; do
    log_step "Instance '$instance': starting"

    multipass exec "$instance" -- bash -c "
        set -euo pipefail
        echo '  [1/4] Verifying passwordless sudo access'
        if ! sudo -n true 2>/dev/null; then
            echo '  ERROR: passwordless sudo is not configured for this user.'
            echo '  Run: sudo visudo -f /etc/sudoers.d/99-fusion-nopasswd'
            echo '  Add: <username> ALL=(ALL) NOPASSWD: /bin/systemctl, /usr/bin/systemctl'
            exit 1
        fi

        echo '  [2/4] Stopping fusion-server (ignore if already stopped)'
        sudo -n systemctl stop fusion-server || true

        echo '  [3/4] Starting fusion-server'
        sudo -n systemctl start fusion-server

        echo '  [4/4] Checking status'
        sudo -n systemctl status fusion-server --no-pager || true
    "

    log_step "Instance '$instance': completed"
    echo
done

echo "All done."
