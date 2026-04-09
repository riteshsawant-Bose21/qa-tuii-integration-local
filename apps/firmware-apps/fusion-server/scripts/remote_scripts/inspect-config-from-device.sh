#!/usr/bin/env bash

# Script used to inspect the fusion.db database used by fusion-server on a remote device.
set -euo pipefail

if [[ $# -lt 2 ]]; then
    cat <<EOF
Usage: $0 <user@host> <bbolt command> [<args>...]

This script makes a temporary copy of the Fusion database located at
/var/lib/fusion/fusion.db on the specified remote device and then
runs the bbolt command against that copy.

The expected usage of the command is:

  $0 <user@host> info
  $0 <user@host> dump
  $0 <user@host> stats
  $0 <user@host> buckets
  $0 <user@host> keys <bucket>
  $0 <user@host> get <bucket> <key>
  $0 <user@host> set <bucket> <key> <value>
  $0 <user@host> delete <bucket> <key>

Examples:
  # Show database info:
  $0 root@192.168.1.3 info

  # List all buckets:
  $0 root@192.168.1.3 buckets

  # List keys in the "state" bucket:
  $0 root@192.168.1.3 keys state

  # Retrieve the value for "mykey" in the "state" bucket:
  $0 root@192.168.1.3 get state mykey | jq

  # Filter on a specific JSON key in the database
  $0 root@192.168.1.3 get state latest | jq '.state.user_setting.data'
EOF
    exit 1
fi

target="$1"
shift

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
local_bbolt="$repo_root/tools/bbolt/cmd/bbolt-linux-arm64"

if [[ ! -f "$local_bbolt" ]]; then
  echo "Local bbolt binary not found: $local_bbolt" >&2
  exit 1
fi

remote_bbolt="/var/lib/fusion/bbolt-linux-arm64"
tmp_remote_bbolt="/tmp/bbolt-linux-arm64.$$"

remote_bbolt_exists="$(ssh "$target" "if [ -f '$remote_bbolt' ]; then echo yes; else echo no; fi")"

if [[ "$remote_bbolt_exists" != "yes" ]]; then
  scp "$local_bbolt" "$target:$tmp_remote_bbolt"
  ssh "$target" "mkdir -p /var/lib/fusion && mv $tmp_remote_bbolt $remote_bbolt && chmod +x $remote_bbolt"
fi

ssh "$target" bash -s -- "$remote_bbolt" "$@" <<'EOF'
set -euo pipefail

BBOLT_BIN="$1"
shift

if TMP_DB=$(mktemp /tmp/fusion-copy.XXXXXX 2>/dev/null); then
  :
elif TMP_DB=$(mktemp -t fusion-copy.XXXXXX 2>/dev/null); then
  :
else
  echo "Failed to create temporary database file on remote host" >&2
  exit 1
fi
trap 'rm -f "$TMP_DB"' EXIT

cp /var/lib/fusion/fusion.db "$TMP_DB"

cmd="$1"
shift

case "$cmd" in
    keys|get|set|delete)
    "$BBOLT_BIN" "$cmd" "$TMP_DB" "$@"
        ;;
    *)
    "$BBOLT_BIN" "$cmd" "$@" "$TMP_DB"
        ;;
esac
EOF
