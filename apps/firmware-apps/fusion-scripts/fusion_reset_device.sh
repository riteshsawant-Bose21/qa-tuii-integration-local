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

AUDIO_DIR="/var/lib/fusion/audio"
DATABASE_FILE="/var/lib/fusion/fusion.db"
OUTPUT_ROOT="./debug_logs"
RUN_TIMESTAMP=""
SELECTED_SCOPE=""
ASSUME_YES=false
SSH_FAILURE_REASON=""
REMOTE_CMD=""

DEVICES=()
CHANGED_DEVICES=()
REBOOTED_DEVICES=()
NO_CHANGE_DEVICES=()
FAILED_DEVICES=()

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
  fusion_reset_device.sh [--scope all|audio|database] [--yes] root@device1 [root@device2 ...]

Description:
  Reset Fusion device data remotely over SSH.

Scopes:
  all       Reset audio data and database
  audio     Reset audio data only
  database  Reset database only

Examples:
  ./fusion_reset_device.sh root@10.1.123.250 root@10.1.123.251
  ./fusion_reset_device.sh --scope audio root@10.1.123.250
  ./fusion_reset_device.sh --scope database --yes root@10.1.123.250
EOF
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

require_tools() {
  local missing=0
  for tool in ssh mkdir date; do
    if ! command_exists "$tool"; then
      print_error "Required command not found: $tool"
      missing=1
    fi
  done

  if [[ $missing -ne 0 ]]; then
    exit 1
  fi
}

device_ip() {
  local device="$1"
  if [[ "$device" == *@* ]]; then
    echo "${device#*@}"
  else
    echo "$device"
  fi
}

write_error_file() {
  local path="$1"
  local stage="$2"
  local msg="$3"
  {
    echo "STATUS=ERROR"
    echo "STAGE=${stage}"
    echo "MESSAGE=${msg}"
  } >"$path"
}

parse_args() {
  DEVICES=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --scope)
        if [[ $# -lt 2 ]]; then
          print_error "Missing value for --scope"
          usage
          exit 1
        fi

        case "$2" in
          all|audio|database)
            SELECTED_SCOPE="$2"
            ;;
          *)
            print_error "Invalid scope: $2"
            usage
            exit 1
            ;;
        esac
        shift 2
        ;;
      --yes|-y)
        ASSUME_YES=true
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      --)
        shift
        while [[ $# -gt 0 ]]; do
          DEVICES+=("$1")
          shift
        done
        ;;
      -*)
        print_error "Unknown option: $1"
        usage
        exit 1
        ;;
      *)
        DEVICES+=("$1")
        shift
        ;;
    esac
  done

  if [[ ${#DEVICES[@]} -lt 1 ]]; then
    usage
    exit 1
  fi
}

prompt_scope() {
  local selection

  if [[ -n "$SELECTED_SCOPE" ]]; then
    return 0
  fi

  echo "Select Reset Scope:"
  echo "1) all"
  echo "2) audio"
  echo "3) database"
  read -r -p "Enter choice [1-3]: " selection

  case "$selection" in
    1) SELECTED_SCOPE="all" ;;
    2) SELECTED_SCOPE="audio" ;;
    3) SELECTED_SCOPE="database" ;;
    *)
      print_error "Invalid scope selection: $selection"
      exit 1
      ;;
  esac
}

print_scope_details() {
  echo
  echo "Selected scope: ${SELECTED_SCOPE}"
  echo "Actions by scope:"
  echo "- all: reset audio data and remove fusion.db"
  echo "- audio: reset audio data only"
  echo "- database: remove fusion.db only"
  echo
}

confirm_destructive_action() {
  local answer

  if $ASSUME_YES; then
    print_warn "Destructive confirmation bypassed via --yes"
    return 0
  fi

  print_warn "This operation is destructive and will delete device data for scope '${SELECTED_SCOPE}'."
  read -r -p "Type 'RESET' to proceed: " answer

  if [[ "$answer" != "RESET" ]]; then
    print_warn "Reset aborted by user"
    return 1
  fi

  return 0
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

build_remote_command() {
  case "$SELECTED_SCOPE" in
    all)
      REMOTE_CMD='set -u
changed=0
if [[ -d "'"$AUDIO_DIR"'" ]]; then
  if find "'"$AUDIO_DIR"'" -mindepth 1 -print -quit | grep -q .; then
    if find "'"$AUDIO_DIR"'" -mindepth 1 -exec rm -rf -- {} +; then
      changed=1
      echo "AUDIO_STATUS=changed"
      echo "AUDIO_DETAIL=audio contents deleted"
    else
      echo "AUDIO_STATUS=error"
      echo "AUDIO_DETAIL=failed to remove audio contents"
      exit 20
    fi
  else
    echo "AUDIO_STATUS=no_change"
    echo "AUDIO_DETAIL=audio directory already empty"
  fi
else
  echo "AUDIO_STATUS=no_change"
  echo "AUDIO_DETAIL=audio directory missing"
fi

if [[ -f "'"$DATABASE_FILE"'" ]]; then
  if rm -f -- "'"$DATABASE_FILE"'"; then
    changed=1
    echo "DB_STATUS=changed"
    echo "DB_DETAIL=database file removed"
  else
    echo "DB_STATUS=error"
    echo "DB_DETAIL=failed to remove database file"
    exit 21
  fi
else
  echo "DB_STATUS=no_change"
  echo "DB_DETAIL=database file not present"
fi

echo "CHANGED=${changed}"
exit 0'
      ;;
    audio)
      REMOTE_CMD='set -u
changed=0
if [[ -d "'"$AUDIO_DIR"'" ]]; then
  if find "'"$AUDIO_DIR"'" -mindepth 1 -print -quit | grep -q .; then
    if find "'"$AUDIO_DIR"'" -mindepth 1 -exec rm -rf -- {} +; then
      changed=1
      echo "AUDIO_STATUS=changed"
      echo "AUDIO_DETAIL=audio contents deleted"
    else
      echo "AUDIO_STATUS=error"
      echo "AUDIO_DETAIL=failed to remove audio contents"
      exit 22
    fi
  else
    echo "AUDIO_STATUS=no_change"
    echo "AUDIO_DETAIL=audio directory already empty"
  fi
else
  echo "AUDIO_STATUS=no_change"
  echo "AUDIO_DETAIL=audio directory missing"
fi

echo "CHANGED=${changed}"
exit 0'
      ;;
    database)
      REMOTE_CMD='set -u
changed=0
if [[ -f "'"$DATABASE_FILE"'" ]]; then
  if rm -f -- "'"$DATABASE_FILE"'"; then
    changed=1
    echo "DB_STATUS=changed"
    echo "DB_DETAIL=database file removed"
  else
    echo "DB_STATUS=error"
    echo "DB_DETAIL=failed to remove database file"
    exit 23
  fi
else
  echo "DB_STATUS=no_change"
  echo "DB_DETAIL=database file not present"
fi

echo "CHANGED=${changed}"
exit 0'
      ;;
    *)
      print_error "Unsupported scope selected: ${SELECTED_SCOPE}"
      exit 1
      ;;
  esac
}

process_device() {
  local device="$1"
  local ip outdir output_file err_file
  local output rc changed reboot_output reboot_rc

  ip="$(device_ip "$device")"
  outdir="$OUTPUT_ROOT/device_${ip}"
  output_file="$outdir/operation_output.txt"
  err_file="$outdir/device_error.txt"

  mkdir -p "$outdir"

  print_info "[$device] Starting reset for scope '${SELECTED_SCOPE}'"

  if ! check_connectivity "$device"; then
    write_error_file "$err_file" "ssh-connect" "SSH connection failure to ${device}. Details: ${SSH_FAILURE_REASON}"
    print_error "[$device] SSH connection failed: ${SSH_FAILURE_REASON}"
    FAILED_DEVICES+=("${ip}")
    return 1
  fi

  build_remote_command

  rc=0
  output=$(ssh "${SSH_OPTS[@]}" "$device" "$REMOTE_CMD" 2>&1) || rc=$?
  echo "$output" >"$output_file"

  if [[ $rc -ne 0 ]]; then
    write_error_file "$err_file" "reset-operations" "Remote reset failed (exit ${rc}). See operation_output.txt"
    print_error "[$device] Reset operations failed"
    FAILED_DEVICES+=("${ip}")
    return 1
  fi

  changed=0
  if grep -q '^CHANGED=1$' <<<"$output"; then
    changed=1
  fi

  if [[ $changed -eq 1 ]]; then
    print_info "[$device] Reset changed data. Rebooting device"
    reboot_rc=0
    reboot_output=$(ssh "${SSH_OPTS[@]}" "$device" 'reboot' 2>&1) || reboot_rc=$?
    {
      echo
      echo "----- REBOOT OUTPUT -----"
      echo "$reboot_output"
    } >>"$output_file"

    if [[ $reboot_rc -ne 0 ]]; then
      write_error_file "$err_file" "reboot" "Reset succeeded, but reboot failed (exit ${reboot_rc}). See operation_output.txt"
      print_error "[$device] Reset succeeded but reboot failed"
      FAILED_DEVICES+=("${ip}")
      return 1
    fi

    print_success "[$device] Reset succeeded and reboot triggered"
    CHANGED_DEVICES+=("${ip}")
    REBOOTED_DEVICES+=("${ip}")
    return 0
  fi

  print_warn "[$device] Reset completed with no data changes; reboot not required"
  NO_CHANGE_DEVICES+=("${ip}")
  return 0
}

main() {
  local total failures

  parse_args "$@"
  require_tools
  prompt_scope

  print_scope_details
  if ! confirm_destructive_action; then
    exit 1
  fi

  RUN_TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
  OUTPUT_ROOT="./debug_logs/reset_log_${RUN_TIMESTAMP}"
  mkdir -p "$OUTPUT_ROOT"

  total=${#DEVICES[@]}
  failures=0

  print_info "Devices to process: ${total}"
  print_info "Output root: ${OUTPUT_ROOT}"
  print_info "Scope selected: ${SELECTED_SCOPE}"

  for device in "${DEVICES[@]}"; do
    if ! process_device "$device"; then
      failures=$((failures + 1))
    fi
  done

  echo
  echo "Reset operation completed."
  echo "Devices processed: ${total}"
  echo "Failures: ${failures}"
  echo
  echo "Summary of changes:"
  echo "Changed devices: ${#CHANGED_DEVICES[@]}"
  if [[ ${#CHANGED_DEVICES[@]} -gt 0 ]]; then
    printf '  - %s\n' "${CHANGED_DEVICES[@]}"
  fi
  echo "Rebooted devices: ${#REBOOTED_DEVICES[@]}"
  if [[ ${#REBOOTED_DEVICES[@]} -gt 0 ]]; then
    printf '  - %s\n' "${REBOOTED_DEVICES[@]}"
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
  echo "Operation logs stored at:"
  echo "${OUTPUT_ROOT}/"
}

main "$@"
