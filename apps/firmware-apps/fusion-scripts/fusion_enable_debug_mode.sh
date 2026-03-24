#!/usr/bin/env bash

set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SSH_OPTS=(
  -o ConnectTimeout=10
  -o BatchMode=yes
  -o StrictHostKeyChecking=accept-new
)

OUTPUT_ROOT="./debug_logs"
RUN_TIMESTAMP=""
SSH_FAILURE_REASON=""

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
  cat <<'EOF'
Usage:
  fusion_debug_logging.sh root@device1 [root@device2 ...]

Description:
  Enable or disable verbose logging for Fusion services on one or more devices via SSH.

Services:
  1) fusion-dsp
  2) fusion-system-monitor
  3) fusion-server

Examples:
  ./fusion_debug_logging.sh root@192.168.1.10 root@192.168.1.11
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

DEVICES=("$@")

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

require_tools() {
  local missing=0
  for tool in ssh awk sed grep mkdir; do
    if ! command_exists "$tool"; then
      print_error "Required command not found: $tool"
      missing=1
    fi
  done

  if [[ $missing -ne 0 ]]; then
    exit 1
  fi
}

write_error_file() {
  local path="$1"
  local msg="$2"
  {
    echo "ERROR"
    echo "$msg"
  } >"$path"
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

prompt_service() {
  local selection
  echo "Select Service:"
  echo "1) fusion-dsp"
  echo "2) fusion-system-monitor"
  echo "3) fusion-server"
  read -r -p "Enter choice [1-3]: " selection

  case "$selection" in
    1)
      SERVICE_NAME="fusion-dsp"
      UNIT_FILE="fusion-dsp.service"
      SERVICE_UNIT="fusion-dsp"
      VERBOSE_FLAG="-vv"
      ;;
    2)
      SERVICE_NAME="fusion-system-monitor"
      UNIT_FILE="fusion-system-monitor.service"
      SERVICE_UNIT="fusion-system-monitor"
      VERBOSE_FLAG="-vv"
      ;;
    3)
      SERVICE_NAME="fusion-server"
      UNIT_FILE="fusion-server.service"
      SERVICE_UNIT="fusion-server"
      VERBOSE_FLAG="-verbose"
      ;;
    *)
      print_error "Invalid service selection: $selection"
      exit 1
      ;;
  esac
}

check_connectivity() {
  local device="$1"
  local ssh_output ssh_code
  print_info "[$device] Checking SSH connectivity"
  ssh_output=$(ssh "${SSH_OPTS[@]}" "$device" 'exit 0' 2>&1)
  ssh_code=$?

  if [[ $ssh_code -eq 0 ]]; then
    SSH_FAILURE_REASON=""
    return 0
  fi

  if [[ -z "$ssh_output" ]]; then
    SSH_FAILURE_REASON="SSH exited with code $ssh_code and returned no diagnostic output"
  else
    SSH_FAILURE_REASON="$ssh_output"
  fi

  return 1
}

process_device() {
  local device="$1"
  local ip outdir
  local remote_script
  local output
  local rc=0

  ip="${device#*@}"
  outdir="$OUTPUT_ROOT/device_${ip}"
  mkdir -p "$outdir"

  print_info "[$device] Processing service ${SERVICE_NAME} (${ACTION})"

  if ! check_connectivity "$device"; then
    write_error_file "$outdir/device_error.txt" "SSH connection failure to $device
Details: ${SSH_FAILURE_REASON}"
    print_error "[$device] SSH connection failed: ${SSH_FAILURE_REASON}"
    print_error "[$device] Skipping device."
    FAILED_DEVICES+=("${ip}")
    return 1
  fi

  remote_script=$(cat <<'EOS'
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

add_flag_generic() {
  local line="$1"
  local flag="$2"
  if [[ " $line " == *" ${flag} "* ]]; then
    normalize_spaces "$line"
    return
  fi
  normalize_spaces "$line $flag"
}

if [[ "$ACTION" == "enable" ]]; then
  if [[ "$FLAG" == "-verbose" ]]; then
    no_flag="$(remove_flag "$line_content" "$FLAG")"
    new_line="$(normalize_spaces "$no_flag $FLAG")"
  else
    new_line="$(add_flag_generic "$line_content" "$FLAG")"
  fi
else
  new_line="$(remove_flag "$line_content" "$FLAG")"
fi

if [[ "$(normalize_spaces "$line_content")" == "$(normalize_spaces "$new_line")" ]]; then
  echo "NO_CHANGE"
  echo "SERVICE_PATH=$service_path"
  echo "ExecStart=$line_content"
  exit 0
fi

timestamp="$(date '+%Y-%m-%d_%H-%M-%S')"
backup_path="${service_path}.backup_${timestamp}"
cp "$service_path" "$backup_path"

awk -v repl="ExecStart=$new_line" '
  BEGIN { done=0 }
  /^ExecStart=/ && done==0 { print repl; done=1; next }
  { print }
' "$service_path" >"${service_path}.tmp.$$"
mv "${service_path}.tmp.$$" "$service_path"

if ! systemctl daemon-reload; then
  echo "ERROR: systemctl daemon-reload failed"
  exit 12
fi

if ! systemctl restart "$SERVICE_UNIT"; then
  echo "ERROR: systemctl restart ${SERVICE_UNIT} failed"
  exit 13
fi

final_exec="$(grep -E '^ExecStart=' "$service_path" | head -n 1 || true)"

echo "CHANGED"
echo "SERVICE_PATH=$service_path"
echo "BACKUP_PATH=$backup_path"
echo "$final_exec"
EOS
)

output=$(ssh "${SSH_OPTS[@]}" "$device" "bash -s -- '$UNIT_FILE' '$SERVICE_UNIT' '$ACTION' '$VERBOSE_FLAG'" <<<"$remote_script" 2>&1) || rc=$?
echo "$output" >"$outdir/operation_output.txt"

if [[ $rc -ne 0 ]]; then
    print_error "[$device] Failed while modifying service"
    write_error_file "$outdir/device_error.txt" "$output"
    FAILED_DEVICES+=("${ip}")
    return 1
  fi

if grep -q '^NO_CHANGE$' <<<"$output"; then
  print_warn "[$device] No change needed; requested state already present"
  NO_CHANGE_DEVICES+=("${ip}")
else
  print_success "[$device] Service file updated and service restarted"
  CHANGED_DEVICES+=("${ip}")
fi

echo "Device: ${ip}"
echo "${SERVICE_UNIT} ExecStart:"
grep -E '^ExecStart=' <<<"$output" | head -n 1
echo
return 0
}

main() {
  local total failures
  total=${#DEVICES[@]}
  failures=0

  CHANGED_DEVICES=()
  NO_CHANGE_DEVICES=()
  FAILED_DEVICES=()

  require_tools
  prompt_action
  prompt_service
  RUN_TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
  OUTPUT_ROOT="./debug_logs/enable_log_${RUN_TIMESTAMP}"
  mkdir -p "$OUTPUT_ROOT"

  print_info "Action selected: ${ACTION}"
  print_info "Service selected: ${SERVICE_NAME}"
  print_info "Devices to process: ${total}"
  print_info "Output root: ${OUTPUT_ROOT}"

  for device in "${DEVICES[@]}"; do
    if ! process_device "$device"; then
      failures=$((failures + 1))
    fi
  done

  echo "Operation completed."
  echo "Devices processed: ${total}"
  echo "Failures: ${failures}"
  echo
  echo "Summary of changes:"
  echo "Changed devices: ${#CHANGED_DEVICES[@]}"
  if [[ ${#CHANGED_DEVICES[@]} -gt 0 ]]; then
    printf '  - %s\n' "${CHANGED_DEVICES[@]}"
  fi
  echo "No-change devices: ${#NO_CHANGE_DEVICES[@]}"
  if [[ ${#NO_CHANGE_DEVICES[@]} -gt 0 ]]; then
    printf '  - %s\n' "${NO_CHANGE_DEVICES[@]}"
  fi
  echo "Failed devices: ${#FAILED_DEVICES[@]}"
  if [[ ${#FAILED_DEVICES[@]} -gt 0 ]]; then
    printf '  - %s\n' "${FAILED_DEVICES[@]}"
  fi

  echo
  echo "***************************************************************"
  echo "* Please reboot the device(s)  for a healthy operation.       *"
  echo "***************************************************************"
  echo
  echo "Operation logs stored at:"
  echo "${OUTPUT_ROOT}/"
}

main