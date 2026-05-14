#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY="${SCRIPT_DIR}/../../fusion/fusion"
DEBUG_LOGS_DIR="${SCRIPT_DIR}/debug_logs"
BASE_PORT=6060

print_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warn()    { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
  echo "Usage: $0 [--log-dir DIR] [--binary PATH] [--port PORT]"
  echo
  echo "Open fusion-server CPU profiles in the browser using go tool pprof."
  echo "By default uses the most recent log_* directory under debug_logs/."
  echo
  echo "Options:"
  echo "  --log-dir DIR    Path to a specific log_* directory (default: latest)"
  echo "  --binary  PATH   Path to the fusion-server binary (default: auto-detected)"
  echo "  --port    PORT   Base HTTP port (profiles use PORT, PORT+1, ... default: 6060)"
  echo "  -h, --help       Show this help"
  echo
  echo "Examples:"
  echo "  $0"
  echo "  $0 --log-dir ./debug_logs/log_2026-05-13_03-31-15"
  echo "  $0 --port 7070"
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
  # Pick the most recently created log_* directory
  local latest
  latest=$(find "$DEBUG_LOGS_DIR" -maxdepth 1 -type d -name "log_*" \
    | sort | tail -n1)
  echo "$latest"
}

main() {
  local log_dir="" port="$BASE_PORT"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --log-dir)  log_dir="${2:?Error: --log-dir requires a value}";  shift 2 ;;
      --binary)   BINARY="${2:?Error: --binary requires a value}";    shift 2 ;;
      --port)     port="${2:?Error: --port requires a value}";         shift 2 ;;
      -h|--help)  usage; exit 0 ;;
      *)          print_error "Unknown argument: $1"; usage; exit 1 ;;
    esac
  done

  require_tools

  # Resolve log directory
  if [[ -z "$log_dir" ]]; then
    log_dir="$(find_latest_log_dir)"
    if [[ -z "$log_dir" ]]; then
      print_error "No log_* directories found under $DEBUG_LOGS_DIR"
      print_error "Run ./collect_logs.sh first."
      exit 1
    fi
  fi

  if [[ ! -d "$log_dir" ]]; then
    print_error "Log directory not found: $log_dir"
    exit 1
  fi

  # Resolve binary
  if [[ ! -f "$BINARY" ]]; then
    print_error "fusion-server binary not found: $BINARY"
    print_error "Build it first: cd fusion && go build ./cmd/fusion"
    exit 1
  fi

  # Collect all .prof files
  local -a prof_files
  while IFS= read -r f; do
    [[ -n "$f" ]] && prof_files+=("$f")
  done < <(find "$log_dir" -name "*.prof" | sort)

  if [[ ${#prof_files[@]} -eq 0 ]]; then
    print_error "No .prof files found in $log_dir"
    print_error "Run ./collect_logs.sh after a stress test with profiling enabled."
    exit 1
  fi

  print_info "Log directory: $log_dir"
  print_info "Binary:        $BINARY"
  print_info "Found ${#prof_files[@]} profile(s)"
  echo

  local -a pids
  local current_port=$port

  for prof in "${prof_files[@]}"; do
    local name
    name="$(basename "$prof" .prof)"
    print_info "Opening $name on http://localhost:${current_port}"
    go tool pprof -http=":${current_port}" "$BINARY" "$prof" &
    pids+=($!)
    current_port=$((current_port + 1))
  done

  echo
  print_success "Opened ${#prof_files[@]} profile(s):"
  current_port=$port
  for prof in "${prof_files[@]}"; do
    echo "  http://localhost:${current_port}  →  $(basename "$prof")"
    current_port=$((current_port + 1))
  done
  echo
  print_info "Press Ctrl+C to stop all pprof servers."

  # Wait for all pprof processes; clean up on Ctrl+C
  trap 'kill "${pids[@]}" 2>/dev/null; echo; print_info "Stopped all pprof servers."; exit 0' INT TERM
  wait "${pids[@]}" 2>/dev/null || true
}

main "$@"
