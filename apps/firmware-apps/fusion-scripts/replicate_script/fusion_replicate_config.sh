#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DEVICES_JSON="$SCRIPT_DIR/devices.json"
SOURCE_CONFIG_JSON="$SCRIPT_DIR/config.json"
PYTHON_BIN=""

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

ensure_local_python_for_visualizer() {
  local venv_python
  venv_python="$SCRIPT_DIR/.venv/bin/python"

  if [[ -x "$venv_python" ]]; then
    print_info "Using existing virtual environment: $SCRIPT_DIR/.venv"
  else
    if ! command_exists python3; then
      print_error "python3 is required to create local virtual environment"
      return 1
    fi

    print_info "Creating local virtual environment at $SCRIPT_DIR/.venv"
    if ! python3 -m venv "$SCRIPT_DIR/.venv"; then
      print_error "Failed to create virtual environment"
      return 1
    fi
  fi

  PYTHON_BIN="$venv_python"
  print_info "Using Python interpreter: $PYTHON_BIN"

  if ! "$PYTHON_BIN" -m pip --version >/dev/null 2>&1; then
    print_error "pip is unavailable in local virtual environment"
    return 1
  fi

  if ! "$PYTHON_BIN" -c 'import graphviz' >/dev/null 2>&1; then
    print_info "Installing Python package 'graphviz' in local virtual environment"
    if ! "$PYTHON_BIN" -m pip install --upgrade pip >/dev/null 2>&1; then
      print_warn "Could not upgrade pip. Continuing with existing pip version."
    fi
    if ! "$PYTHON_BIN" -m pip install graphviz; then
      print_error "Failed to install Python package: graphviz"
      return 1
    fi
  fi

  return 0
}

usage() {
  cat <<'EOF'
Usage:
  ./fusion_replicate_config <target_ip>

Description:
  Replicate source device identity fields and config to target hardware.

Requirements:
  - devices.json and config.json must exist in the same directory as this script.
  - Target device public API must be reachable at http://<target_ip>:8080.
  - Target device admin API must be reachable at http://<target_ip>:9090.

Examples:
  ./fusion_replicate_config 10.1.123.237
EOF
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

require_tools() {
  local missing=0
  for tool in curl jq; do
    if ! command_exists "$tool"; then
      print_error "Required command not found: $tool"
      missing=1
    fi
  done

  if [[ $missing -ne 0 ]]; then
    exit 1
  fi
}

require_source_files() {
  if [[ ! -f "$SOURCE_DEVICES_JSON" ]]; then
    print_error "Missing required file: $SOURCE_DEVICES_JSON"
    exit 1
  fi

  if [[ ! -f "$SOURCE_CONFIG_JSON" ]]; then
    print_error "Missing required file: $SOURCE_CONFIG_JSON"
    exit 1
  fi

  if ! jq -e 'type == "array"' "$SOURCE_DEVICES_JSON" >/dev/null; then
    print_error "devices.json must contain a top-level JSON array"
    exit 1
  fi

  if ! jq -e '.' "$SOURCE_CONFIG_JSON" >/dev/null; then
    print_error "config.json is not valid JSON"
    exit 1
  fi
}

fetch_target_devices() {
  local api_base="$1"

  print_info "Fetching target devices from ${api_base}/devices" >&2
  curl --fail --silent --show-error "${api_base}/devices"
}

normalize_devices_array() {
  jq -c 'if type == "array" then . else (.devices // []) end'
}

confirm_plan() {
  local source_count="$1"
  local target_count="$2"
  local source_summary="$3"
  local target_summary="$4"
  local api_base="$5"
  local admin_base="$6"
  local answer

  echo
  echo "Planned actions"
  echo "- Source file directory: $SCRIPT_DIR"
  echo "- Source devices: $source_count"
  echo "- Target devices: $target_count"
  echo "- Target API: ${api_base}"
  echo "- Target admin API: ${admin_base}"
  echo "- Device info updates: id, location, name (mapped by array index)"
  echo "- Config apply: PATCH ${admin_base}/state with config.json body"
  echo
  echo "Source device info (by index):"
  echo "$source_summary"
  echo
  echo "Target device info (by index):"
  echo "$target_summary"
  echo

  read -r -p "Proceed with replication? [y/N]: " answer
  case "$answer" in
    y|Y|yes|YES)
      return 0
      ;;
    *)
      print_warn "Replication aborted by user"
      return 1
      ;;
  esac
}

patch_devices() {
  local api_base="$1"
  local target_devices_json="$2"
  local source_count="$3"
  local i source_patch target_id

  for ((i = 0; i < source_count; i++)); do
    source_patch=$(jq -c --argjson i "$i" '
      .[$i]
      | {
          id: .id,
          location: .location,
          name: .name
        }
      | with_entries(select(.value != null))
    ' "$SOURCE_DEVICES_JSON")

    target_id=$(jq -r --argjson i "$i" '.[$i].id // empty' <<<"$target_devices_json")
    if [[ -z "$target_id" ]]; then
      print_error "Target device at index ${i} does not have a valid id"
      exit 1
    fi

    print_info "Patching target index ${i}, current id '${target_id}'"
    curl --fail --silent --show-error \
      -X PATCH \
      -H "Content-Type: application/json" \
      -d "$source_patch" \
      "${api_base}/devices/${target_id}" >/dev/null
  done
}

apply_config() {
  local admin_base="$1"

  print_info "Applying configuration to ${admin_base}/state"
  curl --fail --silent --show-error \
    -X PATCH \
    -H "Content-Type: application/json" \
    --data-binary "@$SOURCE_CONFIG_JSON" \
    "${admin_base}/state" >/dev/null
}

prompt_generate_output() {
  local answer
  read -r -p "Generate visualization output from config.json now? [y/N]: " answer
  case "$answer" in
    y|Y|yes|YES)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

generate_output_from_config() {
  local visualizer_script output_file

  visualizer_script="$SCRIPT_DIR/visualizer.py"
  output_file="$SCRIPT_DIR/dsp_diagram_out.png"

  if [[ ! -f "$visualizer_script" ]]; then
    print_error "Visualizer script not found: $visualizer_script"
    return 1
  fi

  if ! ensure_local_python_for_visualizer; then
    return 1
  fi

  if ! command_exists dot; then
    print_error "Missing Graphviz binary: dot"
    print_info "Install with: brew install graphviz"
    return 1
  fi

  print_info "Generating visualization from $SOURCE_CONFIG_JSON"
  if ! "$PYTHON_BIN" "$visualizer_script" -o "$SOURCE_CONFIG_JSON" -f "$output_file"; then
    print_error "Failed to generate visualization output"
    return 1
  fi

  print_success "Visualization saved to $output_file"
  return 0
}

main() {
  local target_ip api_base admin_base source_count target_devices_json target_count source_summary target_summary

  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  if [[ $# -ne 1 ]]; then
    usage
    exit 1
  fi

  target_ip="$1"
  api_base="http://${target_ip}:8080"
  admin_base="http://${target_ip}:9090"

  require_tools
  require_source_files

  source_count=$(jq 'length' "$SOURCE_DEVICES_JSON")
  target_devices_json=$(fetch_target_devices "$api_base" | normalize_devices_array)

  if ! jq -e 'type == "array"' <<<"$target_devices_json" >/dev/null; then
    print_error "Target API /devices did not return a devices array"
    exit 1
  fi

  target_count=$(jq 'length' <<<"$target_devices_json")

  if [[ "$source_count" -ne "$target_count" ]]; then
    print_error "Device count mismatch. Source: ${source_count}, Target: ${target_count}. No changes applied."
    exit 1
  fi

  source_summary=$(jq -r 'to_entries[] | "  [\(.key)] id=\(.value.id // "<no-id>") | location=\(.value.location // "") | name=\(.value.name // "")"' "$SOURCE_DEVICES_JSON")
  target_summary=$(jq -r 'to_entries[] | "  [\(.key)] id=\(.value.id // "<no-id>") | location=\(.value.location // "") | name=\(.value.name // "")"' <<<"$target_devices_json")

  if ! confirm_plan "$source_count" "$target_count" "$source_summary" "$target_summary" "$api_base" "$admin_base"; then
    exit 1
  fi

  patch_devices "$api_base" "$target_devices_json" "$source_count"
  print_success "Device identity fields replicated successfully"

  apply_config "$admin_base"
  print_success "Configuration replicated successfully"

  if prompt_generate_output; then
    if ! generate_output_from_config; then
      print_warn "Replication completed, but visualization generation failed"
    fi
  else
    print_info "Skipped visualization generation"
  fi
}

main "$@"
