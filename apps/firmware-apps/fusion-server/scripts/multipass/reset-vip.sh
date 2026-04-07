#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
KEEPALIVED_CONF="/etc/keepalived/keepalived.conf"
VIP_PLACEHOLDER="VIP_NOT_SET/24"

print_status() {
	echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
	echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
	echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
	echo -e "${YELLOW}[WARNING]${NC} $1"
}

command_exists() {
	command -v "$1" >/dev/null 2>&1
}

validate_instance() {
	local instance=$1
	print_status "Validating multipass instance $instance..."

	if multipass exec "$instance" -- true >/dev/null 2>&1; then
		print_success "Instance $instance is reachable"
		return 0
	fi

	print_error "Cannot execute commands on instance $instance"
	return 1
}

reset_vip_in_keepalived() {
	local instance=$1
	print_status "Resetting VIP in $instance:$KEEPALIVED_CONF to $VIP_PLACEHOLDER..."

	if ! multipass exec "$instance" -- sudo grep -qE '^[[:space:]]*virtual_ipaddress[[:space:]]*\{' "$KEEPALIVED_CONF"; then
		print_error "virtual_ipaddress block not found in $KEEPALIVED_CONF on $instance"
		return 1
	fi

	if multipass exec "$instance" -- sudo cp "$KEEPALIVED_CONF" "${KEEPALIVED_CONF}.bak.$(date +%s)"; then
		print_success "Backup created on instance"
	else
		print_error "Failed to backup $KEEPALIVED_CONF on $instance"
		return 1
	fi

	if multipass exec "$instance" -- sudo bash -c "awk -v vip='$VIP_PLACEHOLDER' '
		/^[[:space:]]*virtual_ipaddress[[:space:]]*\\{/ {
			print
			print \"    \" vip
			in_vip=1
			next
		}
		in_vip && /^[[:space:]]*\\}/ {
			in_vip=0
			print
			next
		}
		in_vip { next }
		{ print }
	' '$KEEPALIVED_CONF' > '$KEEPALIVED_CONF.tmp' && mv '$KEEPALIVED_CONF.tmp' '$KEEPALIVED_CONF'"; then
		print_success "VIP block reset"
		print_success "Updated keepalived config"
	else
		print_error "Failed to rewrite $KEEPALIVED_CONF on $instance"
		return 1
	fi

	if multipass exec "$instance" -- sudo grep -qE "^[[:space:]]*$VIP_PLACEHOLDER[[:space:]]*$" "$KEEPALIVED_CONF"; then
		print_success "Verified VIP placeholder is set"
	else
		print_error "VIP placeholder was not found after edit"
		return 1
	fi
}

reload_keepalived() {
	local instance=$1
	print_status "Reloading keepalived on $instance..."

	if multipass exec "$instance" -- sudo systemctl reload keepalived 2>/dev/null; then
		print_success "keepalived reloaded"
		return 0
	fi

	print_warning "Reload failed, attempting restart"
	if multipass exec "$instance" -- sudo systemctl restart keepalived 2>/dev/null; then
		print_success "keepalived restarted"
	else
		print_warning "Could not reload/restart keepalived. Please check service state manually"
	fi
}

usage() {
	echo "Usage: $0 [OPTIONS]"
	echo
	echo "Reset keepalived VIP on multipass instances matching prefix."
	echo
	echo "Options:"
	echo "  --prefix PREFIX  Instance name prefix (default: fusion)"
	echo "  -h, --help       Show this help message"
	echo
	echo "Examples:"
	echo "  $0"
	echo "  $0 --prefix fusion"
	echo "  $0 --prefix test"
	echo
}

PREFIX="fusion"

while [[ $# -gt 0 ]]; do
	case $1 in
		--prefix)
			if [[ -z ${2:-} ]]; then
				print_error "Missing value for --prefix"
				usage
				exit 1
			fi
			PREFIX="$2"
			shift 2
			;;
		-h|--help)
			usage
			exit 0
			;;
		-*)
			print_error "Unknown option: $1"
			usage
			exit 1
			;;
		*)
			print_error "Unknown argument: $1"
			usage
			exit 1
			;;
	esac
done

if ! command_exists multipass; then
	print_error "multipass command not found"
	exit 1
fi

INSTANCES=$(multipass list --format csv | tail -n +2 | cut -d',' -f1 | grep "^$PREFIX" || true)

if [[ -z "$INSTANCES" ]]; then
	print_warning "No multipass instances found with prefix '$PREFIX'"
	exit 0
fi

echo -e "${YELLOW}Warning: This will replace configured VIPs with '$VIP_PLACEHOLDER' on:${NC}"
for instance in $INSTANCES; do
	echo "  - $instance"
done
read -p "Do you want to continue? [y/N]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	print_status "Operation cancelled"
	exit 0
fi

for instance in $INSTANCES; do
	echo
	echo "######################################"
	print_status "Resetting VIP on $instance"
	echo "######################################"

	validate_instance "$instance"
	reset_vip_in_keepalived "$instance"
	reload_keepalived "$instance"
done

echo
print_success "VIP reset operation completed"
