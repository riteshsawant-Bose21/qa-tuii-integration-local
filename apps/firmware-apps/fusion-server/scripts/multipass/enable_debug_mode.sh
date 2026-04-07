#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PREFIX="fusion"
SERVICE_NAME="fusion-server"
UNIT_FILE="fusion-server.service"
SERVICE_UNIT="fusion-server"
VERBOSE_FLAG="-verbose"

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
  echo "Enable or disable verbose logging for fusion-server on Multipass instances."
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
  for tool in multipass awk sed grep cut tail; do
    if ! command_exists "$tool"; then
      print_error "Required command not found: $tool"
      missing=1
    fi
  done

  if [[ $missing -ne 0 ]]; then
    exit 1
  fi
}

prompt_action() {
  local selection
  echo "Select Action:"
  echo "1) Enable verbose logging"
  echo "2) Disable verbose logging"
  read -r -p "Enter choice [1-2]: " selection

  case "$selection" in
    1) ACTION="enable" ;;
    2) ACTION="disable" ;;
    *)
      print_error "Invalid action selection: $selection"
      exit 1
      ;;
  esac
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
  local output
  local rc=0

  print_info "[$instance] Processing ${SERVICE_NAME} (${ACTION})"

  if ! check_connectivity "$instance"; then
    print_error "[$instance] Multipass connectivity failed"
    print_error "[$instance] Skipping instance"
    FAILED_INSTANCES+=("$instance")
    return 1
  fi

  output=$(multipass exec "$instance" -- sudo bash -s -- "$UNIT_FILE" "$SERVICE_UNIT" "$ACTION" "$VERBOSE_FLAG" <<'EOS'
set -u

UNIT_FILE="$1"
SERVICE_UNIT="$2"
ACTION="$3"
FLAG="$4"

resolve_path() {
  if [[ -f "/usr/lib/systemd/system/${UNIT_FILE}" ]]; then
    echo "/usr/lib/systemd/system/${UNIT_FILE}"
    return 0
  fi

  if [[ -f "/lib/systemd/system/${UNIT_FILE}" ]]; then
    echo "/lib/systemd/system/${UNIT_FILE}"
    return 0
  fi

  return 1
}

service_path="$(resolve_path)"
if [[ -z "${service_path:-}" ]]; then
  echo "ERROR: unit file not found for ${UNIT_FILE}"
  exit 10
fi

exec_line="$(grep -E '^ExecStart=' "$service_path" | head -n 1 || true)"
if [[ -z "$exec_line" ]]; then
  echo "ERROR: ExecStart not found in ${service_path}"
  exit 11
fi

line_content="${exec_line#ExecStart=}"

normalize_spaces() {
  echo "$1" | awk '{$1=$1;print}'
}

remove_flag() {
  local line="$1"
  local flag="$2"
  local compact
  compact="$(echo " $line " | sed "s/ ${flag} / /g")"
  normalize_spaces "$compact"
}

if [[ "$ACTION" == "enable" ]]; then
  no_flag="$(remove_flag "$line_content" "$FLAG")"
  new_line="$(normalize_spaces "$no_flag $FLAG")"
else
  new_line="$(remove_flag "$line_content" "$FLAG")"
fi

if [[ "$(normalize_spaces "$line_content")" == "$(normalize_spaces "$new_line")" ]]; then
  echo "NO_CHANGE"
  echo "ExecStart=$line_content"
  exit 0
fi

timestamp="$(date '+%Y-%m-%d_%H-%M-%S')"
cp "$service_path" "${service_path}.backup_${timestamp}"

awk -v repl="ExecStart=$new_line" '
  BEGIN { done=0 }
  /^ExecStart=/ && done==0 { print repl; done=1; next }
  { print }
' "$service_path" >"${service_path}.tmp.$$"
mv "${service_path}.tmp.$$" "$service_path"

systemctl daemon-reload
systemctl restart "$SERVICE_UNIT"

grep -E '^ExecStart=' "$service_path" | head -n 1
EOS
  ) || rc=$?

  if [[ $rc -ne 0 ]]; then
    print_error "[$instance] Failed while modifying service"
    echo "$output"
    FAILED_INSTANCES+=("$instance")
    return 1
  fi

  if grep -q '^NO_CHANGE$' <<<"$output"; then
    print_warn "[$instance] No change needed; requested state already present"
    NO_CHANGE_INSTANCES+=("$instance")
  else
    print_success "[$instance] Service file updated and service restarted"
    CHANGED_INSTANCES+=("$instance")
  fi

  echo "Instance: ${instance}"
  echo "${SERVICE_UNIT} ExecStart:"
  grep -E '^ExecStart=' <<<"$output" | head -n 1
  echo
  return 0
}

main() {
  local total failures
  failures=0
  instances=()

  CHANGED_INSTANCES=()
  NO_CHANGE_INSTANCES=()
  FAILED_INSTANCES=()

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
  prompt_action

  while IFS= read -r line; do
    [[ -n "$line" ]] && instances+=("$line")
  done < <(get_instances)
  total=${#instances[@]}

  if [[ $total -eq 0 ]]; then
    print_warn "No multipass instances found with prefix '$PREFIX'"
    exit 0
  fi

  print_info "Action selected: ${ACTION}"
  print_info "Service selected: ${SERVICE_NAME}"
  print_info "Prefix selected: ${PREFIX}"
  print_info "Instances to process: ${total}"

  for instance in "${instances[@]}"; do
    if ! process_instance "$instance"; then
      failures=$((failures + 1))
    fi
  done

  echo "Operation completed."
  echo "Instances processed: ${total}"
  echo "Failures: ${failures}"
  echo
  echo "Summary of changes:"
  echo "Changed instances: ${#CHANGED_INSTANCES[@]}"
  if [[ ${#CHANGED_INSTANCES[@]} -gt 0 ]]; then
    printf '  - %s\n' "${CHANGED_INSTANCES[@]}"
  fi
  echo "No-change instances: ${#NO_CHANGE_INSTANCES[@]}"
  if [[ ${#NO_CHANGE_INSTANCES[@]} -gt 0 ]]; then
    printf '  - %s\n' "${NO_CHANGE_INSTANCES[@]}"
  fi
  echo "Failed instances: ${#FAILED_INSTANCES[@]}"
  if [[ ${#FAILED_INSTANCES[@]} -gt 0 ]]; then
    printf '  - %s\n' "${FAILED_INSTANCES[@]}"
  fi
}

main "$@"