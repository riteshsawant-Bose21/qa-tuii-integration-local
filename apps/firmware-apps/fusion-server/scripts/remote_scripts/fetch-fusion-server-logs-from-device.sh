#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 user@ip [user@ip ...]" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
logs_dir="$script_dir/logs"

mkdir -p "$logs_dir"
rm -rf "$logs_dir"/*

for target in "$@"; do
  host_part="$target"
  if [[ "$target" == *"@"* ]]; then
    host_part="${target#*@}"
  fi

  log_file="$logs_dir/${host_part}.log"

  echo "Fetching logs from $target -> $log_file"
  ssh "$target" "journalctl -u fusion-server" >"$log_file"
  echo "Done: $log_file"
  echo
done
