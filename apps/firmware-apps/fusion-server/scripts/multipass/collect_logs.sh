#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PREFIX="fusion"
OUTPUT_ROOT="./debug_logs"
RUN_TIMESTAMP=""

print_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warn() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

usage() {
  echo "Usage: $0 [--prefix PREFIX]"
  echo
  echo "Collect diagnostic logs from Multipass instances matching prefix."
  echo
  echo "Options:"
  echo "  --prefix PREFIX   Multipass instance name prefix (default: fusion)"
  echo "  -h, --help        Show this help"
  echo
  echo "Examples:"
  echo "  $0"
  echo "  $0 --prefix fusion"
  echo "  $0 --prefix test"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

require_tools() {
  local missing=0
  for tool in multipass cut tail grep; do
    if ! command_exists "$tool"; then
      print_error "Required command not found: $tool"
      missing=1
    fi
  done
  if [[ $missing -ne 0 ]]; then
    exit 1
  fi
}

get_instances() {
  multipass list --format csv \
    | tail -n +2 \
    | cut -d',' -f1 \
    | grep "^$PREFIX" || true
}

check_connectivity() {
  local instance="$1"
  print_info "[$instance] Checking Multipass connectivity"

  if multipass exec "$instance" -- true >/dev/null 2>&1; then
    return 0
  fi

  return 1
}

process_instance() {
  local instance="$1"
  local outfile

  outfile="$OUTPUT_ROOT/${instance}.log"

  print_info "[$instance] Collecting fusion-server log -> $outfile"

  if ! check_connectivity "$instance"; then
    print_error "[$instance] Multipass connectivity failed, skipping"
    return 1
  fi

  if ! multipass exec "$instance" -- sudo journalctl -u fusion-server --no-pager -l >"$outfile" 2>&1; then
    print_warn "[$instance] Failed to collect fusion-server log"
    return 1
  fi

  print_success "[$instance] Log saved: $outfile"
  return 0
}

main() {
  local failures
  local -a instances
  failures=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --prefix)
        PREFIX="${2:?Error: --prefix requires a value}"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        print_error "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done

  require_tools

  while IFS= read -r line; do
    [[ -n "$line" ]] && instances+=("$line")
  done < <(get_instances)

  if [[ ${#instances[@]} -eq 0 ]]; then
    print_warn "No multipass instances found with prefix '$PREFIX'"
    exit 0
  fi

  RUN_TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
  OUTPUT_ROOT="./debug_logs/log_${RUN_TIMESTAMP}"
  mkdir -p "$OUTPUT_ROOT"

  print_info "Prefix: ${PREFIX}"
  print_info "Instances to process: ${#instances[@]}"
  print_info "Output root: ${OUTPUT_ROOT}"

  for instance in "${instances[@]}"; do
    echo
    echo "######################################"
    print_info "Collecting logs from $instance"
    echo "######################################"
    if ! process_instance "$instance"; then
      failures=$((failures + 1))
    fi
  done

  echo
  echo "Done."
  echo "Instances processed: ${#instances[@]}"
  echo "Failures: ${failures}"
  echo
  echo "Logs stored at: ${OUTPUT_ROOT}/"
}

main "$@"