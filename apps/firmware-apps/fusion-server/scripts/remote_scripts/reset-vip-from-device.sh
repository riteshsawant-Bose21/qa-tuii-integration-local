#!/bin/bash

set -e

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

validate_remote() {
	local remote=$1
	print_status "Validating connection to $remote..."

	if ssh -o ConnectTimeout=10 "$remote" exit 2>/dev/null; then
		print_success "Connection to $remote validated"
		return 0
	fi

	print_error "Cannot connect to $remote"
	return 1
}

reset_vip_in_keepalived() {
	local remote=$1
	print_status "Resetting VIP in $remote:$KEEPALIVED_CONF to $VIP_PLACEHOLDER..."

	if ! ssh "$remote" "grep -qE '^[[:space:]]*virtual_ipaddress[[:space:]]*\{' '$KEEPALIVED_CONF'" 2>/dev/null; then
		print_error "virtual_ipaddress block not found in $KEEPALIVED_CONF on $remote"
		return 1
	fi

	if ssh "$remote" "cp '$KEEPALIVED_CONF' '${KEEPALIVED_CONF}.bak.$(date +%s)'"; then
		print_success "Backup created on remote"
	else
		print_error "Failed to backup $KEEPALIVED_CONF on $remote"
		return 1
	fi

	if ssh "$remote" "awk '
		/^[[:space:]]*virtual_ipaddress[[:space:]]*\{/ {
			print
			print \"    $VIP_PLACEHOLDER\"
			in_vip=1
			next
		}
		in_vip && /^[[:space:]]*\}/ {
			in_vip=0
			print
			next
		}
		in_vip { next }
		{ print }
	' '$KEEPALIVED_CONF' > '${KEEPALIVED_CONF}.tmp' && mv '${KEEPALIVED_CONF}.tmp' '$KEEPALIVED_CONF'"; then
		print_success "VIP block reset"
	else
		print_error "Failed to edit $KEEPALIVED_CONF on $remote"
		return 1
	fi

	if ssh "$remote" "grep -qE '^[[:space:]]*$VIP_PLACEHOLDER[[:space:]]*$' '$KEEPALIVED_CONF'"; then
		print_success "Verified VIP placeholder is set"
	else
		print_error "VIP placeholder was not found after edit"
		return 1
	fi
}

reload_keepalived() {
	local remote=$1
	print_status "Reloading keepalived on $remote..."

	if ssh "$remote" "systemctl reload keepalived" 2>/dev/null; then
		print_success "keepalived reloaded"
		return 0
	fi

	print_warning "Reload failed, attempting restart"
	if ssh "$remote" "systemctl restart keepalived" 2>/dev/null; then
		print_success "keepalived restarted"
	else
		print_warning "Could not reload/restart keepalived. Please check service state manually"
	fi
}

usage() {
	echo "Usage: $0 [options] <remote-host> [remote-host ...]"
	echo
	echo "Examples:"
	echo "  $0 root@192.168.1.3"
	echo "  $0 root@192.168.1.3 root@192.168.1.4"
	echo
	echo "Options:"
	echo "  -h, --help      Show this help message"
	echo
}

REMOTE_HOSTS=()

while [[ $# -gt 0 ]]; do
	case $1 in
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
			REMOTE_HOSTS+=("$1")
			shift
			;;
	esac
done

if [ ${#REMOTE_HOSTS[@]} -eq 0 ]; then
	print_error "At least one remote host must be specified"
	usage
	exit 1
fi

if ! command_exists ssh; then
	print_error "ssh command not found"
	exit 1
fi

echo -e "${YELLOW}Warning: This will replace configured VIPs with '$VIP_PLACEHOLDER' on:${NC}"
for host in "${REMOTE_HOSTS[@]}"; do
	echo "  - $host"
done
read -p "Do you want to continue? [y/N]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	print_status "Operation cancelled"
	exit 0
fi

for host in "${REMOTE_HOSTS[@]}"; do
	echo
	echo "######################################"
	print_status "Resetting VIP on $host"
	echo "######################################"

	validate_remote "$host"
	reset_vip_in_keepalived "$host"
	reload_keepalived "$host"
done

echo
print_success "VIP reset operation completed"
