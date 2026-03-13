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
CAPTURE_MODE_LABEL=""
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
  cat <<'EOF'
Usage:
  fusion_collect_logs.sh root@device1 [root@device2 ...]

Description:
  Collect diagnostic logs from one or more Fusion devices via SSH.

Examples:
  ./fusion_collect_logs.sh root@192.168.1.10 root@192.168.1.11
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
  for tool in ssh curl mkdir; do
    if ! command_exists "$tool"; then
      print_error "Required command not found: $tool"
      missing=1
    fi
  done
  if [[ $missing -ne 0 ]]; then
    exit 1
  fi
}

prompt_mode() {
  CAPTURE_SERVICE_LOGS=true
  CAPTURE_SYSTEM_DIAG=true
  CAPTURE_KERNEL=true
  CAPTURE_API=true
  CAPTURE_FULL_JOURNAL=true
  CAPTURE_MODE_LABEL="Capture all logs"
}

check_connectivity() {
  local device="$1"
  print_info "[$device] Checking SSH connectivity"
  if ssh "${SSH_OPTS[@]}" "$device" 'exit 0' >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

write_error_file() {
  local path="$1"
  local msg="$2"
  {
    echo "ERROR"
    echo "$msg"
  } >"$path"
}

remote_to_file() {
  local device="$1"
  local cmd="$2"
  local outfile="$3"

  print_info "[$device] Running: $cmd"
  if ! ssh "${SSH_OPTS[@]}" "$device" "$cmd" >"$outfile" 2>&1; then
    local body
    body=$(cat "$outfile")
    write_error_file "$outfile" "$body"
    return 1
  fi
  return 0
}

collect_service_logs() {
  local device="$1"
  local outdir="$2"
  local service outfile failures

  failures=0

  for service in fusion-dsp fusion-system-monitor fusion-server jackd.service ptp4l@lan3 phc2sys@lan3; do
    case "$service" in
      fusion-dsp) outfile="$outdir/fusion-dsp.log" ;;
      fusion-system-monitor) outfile="$outdir/fusion-system-monitor.log" ;;
      fusion-server) outfile="$outdir/fusion-server.log" ;;
      jackd.service) outfile="$outdir/jackd.log" ;;
      ptp4l@lan3) outfile="$outdir/ptp4l.log" ;;
      phc2sys@lan3) outfile="$outdir/phc2sys.log" ;;
      *) outfile="$outdir/${service//[@.]/_}.log" ;;
    esac

    if ! remote_to_file "$device" "journalctl -u '$service' --no-pager -l" "$outfile"; then
      print_warn "[$device] Failed to collect service log: $service"
      failures=$((failures + 1))
    fi
  done

  return $failures
}

collect_kernel_log() {
  local device="$1"
  local outdir="$2"
  if ! remote_to_file "$device" "dmesg -T" "$outdir/dmesg.log"; then
    print_warn "[$device] Failed to collect dmesg"
    return 1
  fi
  return 0
}

collect_full_journal_log() {
  local device="$1"
  local outdir="$2"
  if ! remote_to_file "$device" "journalctl --no-pager -l" "$outdir/journalctl-full.log"; then
    print_warn "[$device] Failed to collect full journalctl logs"
    return 1
  fi
  return 0
}

collect_api_data() {
  local ip="$1"
  local outdir="$2"
  local failures
  failures=0

  print_info "[${ip}] Calling API: /devices"
  if ! curl --fail --silent --show-error "http://${ip}:8080/devices" >"$outdir/devices.json" 2>"$outdir/devices.err"; then
    local err
    err=$(cat "$outdir/devices.err")
    write_error_file "$outdir/devices.json" "API request failed for /devices: $err"
    failures=$((failures + 1))
  fi
  rm -f "$outdir/devices.err"

  print_info "[${ip}] Calling API: /value"
  if ! curl --fail --silent --show-error "http://${ip}:8080/value" >"$outdir/config.json" 2>"$outdir/config.err"; then
    local err
    err=$(cat "$outdir/config.err")
    write_error_file "$outdir/config.json" "API request failed for /value: $err"
    failures=$((failures + 1))
  fi
  rm -f "$outdir/config.err"

  return $failures
}

collect_system_diag() {
  local device="$1"
  local outdir="$2"
  local sysdir failures
  failures=0
  sysdir="$outdir/system"
  mkdir -p "$sysdir"

  if ! remote_to_file "$device" "ip addr" "$sysdir/ip_addr.txt"; then failures=$((failures + 1)); fi
  if ! remote_to_file "$device" "ip route" "$sysdir/ip_route.txt"; then failures=$((failures + 1)); fi
  if ! remote_to_file "$device" "df -h" "$sysdir/df.txt"; then failures=$((failures + 1)); fi
  if ! remote_to_file "$device" "ps aux" "$sysdir/ps.txt"; then failures=$((failures + 1)); fi
  if ! remote_to_file "$device" "lsmod" "$sysdir/lsmod.txt"; then failures=$((failures + 1)); fi
  if ! remote_to_file "$device" "top -b -n 1" "$sysdir/cpu_usage.txt"; then failures=$((failures + 1)); fi
  if ! remote_to_file "$device" "free -h" "$sysdir/memory_usage.txt"; then failures=$((failures + 1)); fi

  return $failures
}

device_ip() {
  local device="$1"
  if [[ "$device" == *@* ]]; then
    echo "${device#*@}"
  else
    echo "$device"
  fi
}

process_device() {
  local device="$1"
  local ip outdir local_failures tmp

  ip="$(device_ip "$device")"
  outdir="$OUTPUT_ROOT/device_${ip}"
  mkdir -p "$outdir"

  local_failures=0

  print_info "[$device] Starting collection"
  if ! check_connectivity "$device"; then
    write_error_file "$outdir/device_error.txt" "SSH connection failure to $device"
    print_error "[$device] SSH connection failed. Skipping device."
    return 1
  fi

  if $CAPTURE_SERVICE_LOGS; then
    collect_service_logs "$device" "$outdir"
    tmp=$?
    local_failures=$((local_failures + tmp))
  fi

  if $CAPTURE_FULL_JOURNAL; then
    if ! collect_full_journal_log "$device" "$outdir"; then
      local_failures=$((local_failures + 1))
    fi
  fi

  if $CAPTURE_KERNEL; then
    if ! collect_kernel_log "$device" "$outdir"; then
      local_failures=$((local_failures + 1))
    fi
  fi

  if $CAPTURE_API; then
    collect_api_data "$ip" "$outdir"
    tmp=$?
    local_failures=$((local_failures + tmp))
  fi

  if $CAPTURE_SYSTEM_DIAG; then
    collect_system_diag "$device" "$outdir"
    tmp=$?
    local_failures=$((local_failures + tmp))
  fi

  if [[ $local_failures -eq 0 ]]; then
    print_success "[$device] Collection complete"
    return 0
  fi

  print_warn "[$device] Collection completed with ${local_failures} issue(s)"
  return 0
}

main() {
  local total failures
  total=${#DEVICES[@]}
  failures=0

  require_tools
  prompt_mode
  RUN_TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
  OUTPUT_ROOT="./debug_logs/log_${RUN_TIMESTAMP}"
  mkdir -p "$OUTPUT_ROOT"

  print_info "Devices to process: ${total}"
  print_info "Output root: ${OUTPUT_ROOT}"
  print_info "Capture mode: ${CAPTURE_MODE_LABEL}"
  print_info "Included: service logs, full journalctl logs, kernel logs, API data, system diagnostics"

  for device in "${DEVICES[@]}"; do
    if ! process_device "$device"; then
      failures=$((failures + 1))
    fi
  done

  echo
  echo "Logs collected successfully."
  echo
  echo "Capture mode: ${CAPTURE_MODE_LABEL}"
  echo "Devices processed: ${total}"
  echo "Failures: ${failures}"
  echo
  echo "Logs stored at:"
  echo "${OUTPUT_ROOT}/"
}

main