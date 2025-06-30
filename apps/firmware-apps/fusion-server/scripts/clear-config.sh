#!/bin/bash

# Function to display help message
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Delete the saved config data stored in /var/lib/fusion/fusion.db

Options:
    -h, --help          Show this help message
    --prefix PREFIX     Specify the instance name prefix to match (default: fusion)

Examples:
    $0                 # Delete config data in instances starting with 'fusion'
    $0 --prefix test   # Delete config data in all instances starting with 'test'
    $0 --help          # Show this help message

The script will:
    Delete the saved config data stored in /var/lib/fusion/fusion.db
EOF
    exit 0
}

# Default prefix
PREFIX="fusion"

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
        *)
            echo "Error: Unknown argument: $1"
            echo "Use --help to see available options"
            exit 1
            ;;
    esac
done


# Get list of running multipass instances that start with the specified prefix
instances=$(multipass list --format csv | tail -n +2 | cut -d',' -f1 | grep "^$PREFIX")

# Check if any matching instances were found
if [ -z "$instances" ]; then
    echo "No instances starting with '$PREFIX' were found"
    exit 0
fi

echo "Deleting config data in instances with prefix: $PREFIX"

for instance in $instances; do
    echo "Deleting config data on instance: $instance"
    
    multipass exec "$instance" -- sudo bash -c '
        
        systemctl stop fusion-server
        
        rm -f /var/lib/fusion/fusion.db
                
        systemctl start fusion-server
        
        systemctl status fusion-server --no-pager
    '
done
