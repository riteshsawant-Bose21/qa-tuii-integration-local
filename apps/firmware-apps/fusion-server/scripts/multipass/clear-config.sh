#!/bin/bash

# Function to display help message
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Delete the saved config data stored in /var/lib/fusion/fusion.db

Options:
    -h, --help          Show this help message
    --prefix PREFIX     Specify the instance name prefix to match (default: fusion)
    -s, --silent        Suppress console output

Examples:
    $0                 # Delete config data in instances starting with 'fusion'
    $0 --prefix test   # Delete config data in all instances starting with 'test'
    $0 --silent        # Run without console output
EOF
    exit 0
}

# Default prefix
PREFIX="fusion"
SILENT=false

# Print wrapper
log() {
    $SILENT || echo "$@"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        --prefix)
            if [ -z "$2" ]; then
                echo "Error: --prefix requires an argument"
                exit 1
            fi
            PREFIX="$2"
            shift 2
            ;;
        -s|--silent)
            SILENT=true
            shift
            ;;
        *)
            echo "Error: Unknown argument: $1"
            echo "Use --help to see available options"
            exit 1
            ;;
    esac
done

# Get list of running multipass instances that start with the specified prefix
instances=$(multipass list --format csv | tail -n +2 | cut -d',' -f1 | grep "^$PREFIX")

if [ -z "$instances" ]; then
    log "No instances starting with '$PREFIX' were found"
    exit 0
fi

log "Deleting config data in instances with prefix: $PREFIX"

for instance in $instances; do
    log "Deleting config data on instance: $instance"
    
    if $SILENT; then
        # silence all internal output
        multipass exec "$instance" -- sudo bash -c '
            systemctl stop fusion-server
            rm -f /var/lib/fusion/fusion.db
            systemctl set-environment FUSION_PROFILE=true
            systemctl start fusion-server
        ' >/dev/null 2>&1
    else
        multipass exec "$instance" -- sudo bash -c '
            systemctl stop fusion-server
            rm -f /var/lib/fusion/fusion.db
            systemctl set-environment FUSION_PROFILE=true
            systemctl start fusion-server
            systemctl status fusion-server --no-pager
        '
    fi
done
