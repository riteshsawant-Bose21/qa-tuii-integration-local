#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEBUG_LOGS_DIR="${SCRIPT_DIR}/debug_logs"
BINARY=""
BASE_PORT=6060

print_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warn()    { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
  echo "Usage: $0 --binary PATH [--log-dir DIR] [--port PORT]"
  echo
  echo "Open fusion-server CPU profiles in the browser using go tool pprof."
  echo "Profiles are collected by fusion_collect_logs.sh into debug_logs/log_*."
  echo "By default uses the most recent log_* directory under debug_logs/."
  echo
  echo "Options:"
  echo "  --binary  PATH   Path to the fusion-server binary (required)"
  echo "  --log-dir DIR    Path to a specific log_* directory (default: latest)"
  echo "  --port    PORT   Base HTTP port (profiles use PORT, PORT+1, ... default: 6060)"
  echo "  -h, --help       Show this help"
  echo
  echo "Examples:"
  echo "  $0 --binary /path/to/fusion-server/fusion/fusion"
  echo "  $0 --binary ./fusion --log-dir ./debug_logs/log_2026-05-13_03-31-15"
  echo "  $0 --binary ./fusion --port 7070"
}

require_tools() {
  local missing=0
  for tool in go find; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      print_error "Required command not found: $tool"
      missing=1
    fi
  done
  if [[ $missing -ne 0 ]]; then exit 1; fi
}

find_latest_log_dir() {
  local latest
  latest=$(find "$DEBUG_LOGS_DIR" -maxdepth 1 -type d -name "log_*" \
    | sort | tail -n1)
  echo "$latest"
}

main() {
  local log_dir="" port="$BASE_PORT"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --binary)   BINARY="${2:?Error: --binary requires a value}";    shift 2 ;;
      --log-dir)  log_dir="${2:?Error: --log-dir requires a value}";  shift 2 ;;
      --port)     port="${2:?Error: --port requires a value}";         shift 2 ;;
      -h|--help)  usage; exit 0 ;;
      *)          print_error "Unknown argument: $1"; usage; exit 1 ;;
    esac
  done

  if [[ -z "$BINARY" ]]; then
    print_error "--binary is required. Provide the path to the fusion-server binary."
    echo
    usage
    exit 1
  fi

  require_tools

  # Resolve log directory
  if [[ -z "$log_dir" ]]; then
    log_dir="$(find_latest_log_dir)"
    if [[ -z "$log_dir" ]]; then
      print_error "No log_* directories found under $DEBUG_LOGS_DIR"
      print_error "Run ./fusion_collect_logs.sh first."
      exit 1
    fi
  fi

  if [[ ! -d "$log_dir" ]]; then
    print_error "Log directory not found: $log_dir"
    exit 1
  fi

  if [[ ! -f "$BINARY" ]]; then
    print_error "fusion-server binary not found: $BINARY"
    print_error "Build it first: cd fusion-server/fusion && go build ./cmd/fusion"
    exit 1
  fi

  # Collect all .prof files (nested under device_*/fusion-server/)
  local -a prof_files
  while IFS= read -r f; do
    [[ -n "$f" ]] && prof_files+=("$f")
  done < <(find "$log_dir" -name "*.prof" | sort)

  if [[ ${#prof_files[@]} -eq 0 ]]; then
    print_error "No .prof files found in $log_dir"
    print_error "Run ./fusion_collect_logs.sh after a stress test with profiling enabled."
    exit 1
  fi

  print_info "Log directory: $log_dir"
  print_info "Binary:        $BINARY"
  print_info "Found ${#prof_files[@]} profile(s)"
  echo

  local -a pids
  local current_port=$port

  for prof in "${prof_files[@]}"; do
    local name device_label
    name="$(basename "$prof" .prof)"
    # Include the device subfolder name in the label for clarity (e.g. device_10.1.123.18)
    device_label="$(basename "$(dirname "$(dirname "$prof")")")"
    print_info "Opening ${device_label}/${name} on http://localhost:${current_port}"
    go tool pprof -http=":${current_port}" "$BINARY" "$prof" &
    pids+=($!)
    current_port=$((current_port + 1))
  done

  echo
  print_success "Opened ${#prof_files[@]} profile(s):"
  current_port=$port
  for prof in "${prof_files[@]}"; do
    local device_label
    device_label="$(basename "$(dirname "$(dirname "$prof")")")"
    echo "  http://localhost:${current_port}  →  ${device_label}/$(basename "$prof")"
    current_port=$((current_port + 1))
  done
  echo
  print_info "Press Ctrl+C to stop all pprof servers."

  trap 'kill "${pids[@]}" 2>/dev/null; echo; print_info "Stopped all pprof servers."; exit 0' INT TERM
  wait "${pids[@]}" 2>/dev/null || true
}

main "$@"
