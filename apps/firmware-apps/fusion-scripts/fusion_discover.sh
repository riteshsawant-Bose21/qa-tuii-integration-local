#!/usr/bin/env bash

set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

MDNS_SERVICE="_fusion._tcp"
MDNS_DOMAIN="local"
BROWSE_TIMEOUT=10
LOOKUP_TIMEOUT=3
API_PORT=8080
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
  fusion_discover.sh [-h|--help]

Description:
  Discover Fusion devices on the local network via mDNS (_fusion._tcp).

  VIP SET     — Only one IP is advertised. Calls /devices on that VIP to
                list all cluster node IPs and reports "Cluster found".

  VIP NOT SET — Multiple devices advertise independently. Lists all found
                IPs and reports "Cluster not formed".

  After discovery you will be offered the option to run
  fusion_collect_logs.sh against the discovered devices.

Examples:
  ./fusion_discover.sh
EOF
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    *)
      print_error "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Prerequisites
# ---------------------------------------------------------------------------

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

require_tools() {
  local missing=0
  for tool in dns-sd python3 curl; do
    if ! command_exists "$tool"; then
      print_error "Required command not found: $tool"
      missing=1
    fi
  done
  [[ $missing -ne 0 ]] && exit 1
}

# ---------------------------------------------------------------------------
# mDNS helpers
# ---------------------------------------------------------------------------

# Browse _fusion._tcp for BROWSE_TIMEOUT seconds.
# Prints unique service instance names, one per line.
browse_services() {
  local tmpfile
  tmpfile=$(mktemp)

  dns-sd -B "${MDNS_SERVICE}" "${MDNS_DOMAIN}" >"$tmpfile" 2>&1 &
  local pid=$!
  sleep "${BROWSE_TIMEOUT}"
  kill "$pid" 2>/dev/null
  wait "$pid" 2>/dev/null

  # dns-sd -B output columns: timestamp Add/Remove ? iface domain regtype ServiceName
  # Service names with spaces are preserved at the end of the line.
  grep "Add" "$tmpfile" | awk '{
    # Everything from column 7 onward is the service name
    out = ""
    for (i = 7; i <= NF; i++) out = (out == "" ? "" : out " ") $i
    print out
  }' | sort -u

  rm -f "$tmpfile"
}

# Resolve a service instance name to its advertised hostname via dns-sd -L.
# Prints the hostname (e.g. fusion-node-1.local) or nothing on failure.
lookup_hostname() {
  local name="$1"
  local tmpfile
  tmpfile=$(mktemp)

  dns-sd -L "$name" "${MDNS_SERVICE}" "${MDNS_DOMAIN}" >"$tmpfile" 2>&1 &
  local pid=$!
  sleep "${LOOKUP_TIMEOUT}"
  kill "$pid" 2>/dev/null
  wait "$pid" 2>/dev/null

  # dns-sd -L output contains: "... can be reached at <hostname>:<port> ..."
  grep -i "can be reached at" "$tmpfile" \
    | sed 's/.*can be reached at \([^ :]*\).*/\1/' \
    | head -1

  rm -f "$tmpfile"
}

# Resolve a .local hostname to an IPv4 address using Python's mDNS-aware
# resolver (relies on macOS system resolver / mDNSResponder).
resolve_ip() {
  local hostname="$1"
  python3 - <<PYEOF 2>/dev/null
import socket
try:
    print(socket.gethostbyname("${hostname}"))
except Exception:
    pass
PYEOF
}

# ---------------------------------------------------------------------------
# API helper
# ---------------------------------------------------------------------------

# Fetch /devices from the given IP and extract all IPv4 addresses found in
# the response body. Prints one IP per line.
fetch_node_ips() {
  local ip="$1"
  local response
  response=$(curl --fail --silent --show-error \
    --max-time 5 \
    "http://${ip}:${API_PORT}/devices" 2>/dev/null) || true

  if [[ -z "$response" ]]; then
    return 1
  fi

  # Extract IPs from the JSON response. Use jq when available for precision,
  # otherwise fall back to a regex scan of the raw JSON.
  if command_exists jq; then
    # Try common field names for node addresses; suppress jq errors gracefully
    local ips
    ips=$(echo "$response" | jq -r \
      '.. | objects | (.ip // .address // .ipAddress // empty)' 2>/dev/null \
      | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | sort -u)
    if [[ -n "$ips" ]]; then
      echo "$ips"
      return 0
    fi
    # Fallback: pretty-print and let the regex below handle it
  fi

  # Regex fallback — pull every IPv4-looking token from the raw JSON
  echo "$response" \
    | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' \
    | sort -u
}

# ---------------------------------------------------------------------------
# Log-collection offer
# ---------------------------------------------------------------------------

offer_log_collection() {
  local -a targets=("$@")

  local collect_script="${SCRIPT_DIR}/fusion_collect_logs.sh"
  if [[ ! -f "$collect_script" ]]; then
    print_warn "fusion_collect_logs.sh not found at: ${collect_script}"
    return
  fi

  echo
  echo -n "Run fusion_collect_logs.sh on the discovered devices? [y/N] "
  read -r answer
  if [[ "$(echo "$answer" | tr '[:upper:]' '[:lower:]')" == "y" ]]; then
    bash "$collect_script" "${targets[@]+${targets[@]}}"
  else
    print_info "Skipping log collection."
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  require_tools

  echo
  print_info "Browsing for ${MDNS_SERVICE}.${MDNS_DOMAIN} (${BROWSE_TIMEOUT}s) ..."
  echo

  # --- Phase 1: discover service instance names ---
  local -a service_names=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && service_names+=("$line")
  done < <(browse_services)

  if [[ ${#service_names[@]} -eq 0 ]]; then
    print_warn "No Fusion devices found on the network."
    exit 0
  fi

  print_info "Found ${#service_names[@]} mDNS advertisement(s). Resolving ..."
  echo

  # --- Phase 2: resolve each service to an IP ---
  local -a resolved_ips=()
  local name hostname ip

  for name in "${service_names[@]}"; do
    print_info "Looking up: ${name}"

    hostname=$(lookup_hostname "$name")
    if [[ -z "$hostname" ]]; then
      print_warn "  Could not look up hostname for: ${name}"
      continue
    fi

    ip=$(resolve_ip "$hostname")
    if [[ -z "$ip" ]]; then
      print_warn "  Could not resolve IP for hostname: ${hostname}"
      continue
    fi

    print_success "  ${name}  ->  ${hostname}  ->  ${ip}"
    resolved_ips+=("$ip")
  done

  # Deduplicate while preserving order (bash 3.2 compatible — no -A)
  local -a unique_ips=()
  local dup_found
  for ip in "${resolved_ips[@]}"; do
    dup_found=0
    local u
    for u in "${unique_ips[@]+"${unique_ips[@]}"}"; do
      if [[ "$u" == "$ip" ]]; then
        dup_found=1
        break
      fi
    done
    [[ $dup_found -eq 0 ]] && unique_ips+=("$ip")
  done

  if [[ ${#unique_ips[@]} -eq 0 ]]; then
    echo
    print_error "Could not resolve any Fusion device IPs. Check network connectivity."
    exit 1
  fi

  # --- Phase 3: report ---
  echo
  echo -e "${CYAN}========================================${NC}"

  local -a node_ips=()

  if [[ ${#unique_ips[@]} -eq 1 ]]; then
    # ---- VIP SET ----
    local vip="${unique_ips[0]}"
    echo -e "${GREEN}  CLUSTER FOUND${NC}  —  VIP is set"
    echo -e "${CYAN}========================================${NC}"
    echo
    print_info "VIP address : ${vip}"
    print_info "Fetching cluster node list from /devices ..."
    echo
    while IFS= read -r node_ip; do
      [[ -n "$node_ip" ]] && node_ips+=("$node_ip")
    done < <(fetch_node_ips "$vip")

    if [[ ${#node_ips[@]} -eq 0 ]]; then
      print_warn "Could not retrieve node IPs from ${vip}:${API_PORT}/devices."
      print_warn "The VIP may be reachable but the API returned no addresses."
      echo
      echo -e "  VIP  ->  ${vip}"
    else
      echo "  Cluster nodes:"
      for node_ip in "${node_ips[@]}"; do
        echo "    -  ${node_ip}"
      done
    fi

  else
    # ---- VIP NOT SET ----
    echo -e "${YELLOW}  CLUSTER NOT FORMED${NC}  —  VIP is NOT set"
    echo -e "${CYAN}========================================${NC}"
    echo
    echo "  ${#unique_ips[@]} devices advertising independently:"
    for ip in "${unique_ips[@]}"; do
      echo "    -  ${ip}"
    done
  fi

  echo -e "${CYAN}========================================${NC}"

  # --- Phase 4: offer log collection ---
  local -a log_targets=()
  if [[ ${#unique_ips[@]} -eq 1 ]]; then
    # For the VIP case, collect from node IPs if we got them, else the VIP
    if [[ ${#node_ips[@]} -gt 0 ]]; then
      for node_ip in "${node_ips[@]}"; do
        log_targets+=("root@${node_ip}")
      done
    else
      log_targets+=("root@${unique_ips[0]}")
    fi
  else
    for ip in "${unique_ips[@]}"; do
      log_targets+=("root@${ip}")
    done
  fi

  offer_log_collection "${log_targets[@]+${log_targets[@]}}"
}

main
