#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
SERVER_DIR="$ROOT_DIR/apps/firmware-apps/fusion-server"
DSP_DIR="$ROOT_DIR/apps/firmware-apps/fusion-dsp"
SERVER_BIN="${SERVER_BIN:-$SERVER_DIR/build/fusion-server_darwin_arm64}"
DSP_BIN="${DSP_BIN:-$DSP_DIR/build/fusion_dsp}"
API_URL="${API_URL:-http://127.0.0.1:8080}"
DEVICES_URL="${DEVICES_URL:-$API_URL/devices}"
SERVER_IP="${SERVER_IP:-127.0.0.1}"
FIXTURE_TEMPLATE="${FIXTURE_TEMPLATE:-$DSP_DIR/config/test_local_udp.json}"
TMP_DIR="$(mktemp -d /tmp/test-local-udp.XXXXXX)"
SERVER_LOG="$TMP_DIR/fusion-server.log"
DSP_LOG="$TMP_DIR/fusion-dsp.log"
STATE_JSON="$TMP_DIR/state.json"
OUTPUT_WAV="$TMP_DIR/out.wav"
SERVER_DATA_DIR="$TMP_DIR/server-data"
SERVER_AUDIO_DIR="$SERVER_DATA_DIR/audio"
SERVER_LOG_DIR="$TMP_DIR/server-logs"
SERVER_IDENTITY_DIR="$TMP_DIR/device-identity"

SERVER_PID=""
DSP_PID=""

cleanup() {
  local exit_code=$?
  if [[ -n "$DSP_PID" ]] && kill -0 "$DSP_PID" 2>/dev/null; then
    kill "$DSP_PID" 2>/dev/null || true
    wait "$DSP_PID" 2>/dev/null || true
  fi
  if [[ -n "$SERVER_PID" ]] && kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi

  echo
  echo "Logs:"
  echo "  server: $SERVER_LOG"
  echo "  dsp:    $DSP_LOG"
  echo "  state:  $STATE_JSON"

  if [[ $exit_code -ne 0 ]]; then
    echo
    echo "Last server log lines:"
    tail -n 40 "$SERVER_LOG" 2>/dev/null || true
    echo
    echo "Last DSP log lines:"
    tail -n 80 "$DSP_LOG" 2>/dev/null || true
  fi

  return $exit_code
}
trap cleanup EXIT

require_file() {
  local path=$1
  if [[ ! -x "$path" ]]; then
    echo "missing executable: $path" >&2
    exit 1
  fi
}

wait_for_http() {
  local url=$1
  local attempts=${2:-60}
  local delay=${3:-0.5}

  for ((i=0; i<attempts; i++)); do
    if curl -sf "$url" >/dev/null; then
      return 0
    fi
    sleep "$delay"
  done

  echo "timed out waiting for $url" >&2
  return 1
}

wait_for_log() {
  local needle=$1
  local file=$2
  local attempts=${3:-60}
  local delay=${4:-0.5}

  for ((i=0; i<attempts; i++)); do
    if grep -F "$needle" "$file" >/dev/null 2>&1; then
      return 0
    fi
    sleep "$delay"
  done

  echo "timed out waiting for '$needle' in $file" >&2
  return 1
}

require_file "$SERVER_BIN"
require_file "$DSP_BIN"
if [[ ! -f "$FIXTURE_TEMPLATE" ]]; then
  echo "missing fixture template: $FIXTURE_TEMPLATE" >&2
  exit 1
fi

echo "Starting fusion-server..."
mkdir -p "$SERVER_DATA_DIR" "$SERVER_AUDIO_DIR" "$SERVER_LOG_DIR" "$SERVER_IDENTITY_DIR"
FUSION_DATA_DIR="$SERVER_DATA_DIR" \
FUSION_AUDIO_DIR="$SERVER_AUDIO_DIR" \
FUSION_LOG_DIR="$SERVER_LOG_DIR" \
FUSION_IDENTITY_DIR="$SERVER_IDENTITY_DIR/" \
"$SERVER_BIN" --local --verbose >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!

wait_for_http "$DEVICES_URL"

DEVICE_JSON="$(curl -sf "$DEVICES_URL")"
DEVICE_ID="$(
  DEVICE_JSON="$DEVICE_JSON" python3 - <<'PY'
import json, os
devices = json.loads(os.environ["DEVICE_JSON"])
print(devices[0]["id"])
PY
)"

echo "Local device ID: $DEVICE_ID"

DEVICE_ID="$DEVICE_ID" FIXTURE_TEMPLATE="$FIXTURE_TEMPLATE" STATE_JSON="$STATE_JSON" OUTPUT_WAV="$OUTPUT_WAV" python3 - <<'PY'
import os
from pathlib import Path

device_id = os.environ["DEVICE_ID"]
template_path = Path(os.environ["FIXTURE_TEMPLATE"])
state_path = Path(os.environ["STATE_JSON"])
output_wav = os.environ["OUTPUT_WAV"]

rendered = template_path.read_text()
rendered = rendered.replace("__DEVICE_ID__", device_id)
rendered = rendered.replace("__OUTPUT_WAV__", output_wav)
state_path.write_text(rendered)
PY

echo "Seeding server state..."
curl -sf \
  -X POST \
  -H 'Content-Type: application/json' \
  --data @"$STATE_JSON" \
  "$API_URL/value" >/dev/null

echo "Starting fusion_dsp..."
(
  cd "$DSP_DIR"
  "$DSP_BIN" \
    -v \
    -n \
    -c config/configuration.json \
    -d config/algorithm-definitions.json \
    -s "$SERVER_IP"
) >"$DSP_LOG" 2>&1 &
DSP_PID=$!

wait_for_log "server ip $SERVER_IP" "$DSP_LOG"
wait_for_log "Got device ID: $DEVICE_ID" "$DSP_LOG"
wait_for_log '"name": "create_audio_task"' "$DSP_LOG"

echo "Patching gain via curl..."
PATCH_ONE='{"settings":{"audio":{"GAIN_LOCAL":{"gain":-12.5}}}}'
curl -sf \
  -X PATCH \
  -H 'Content-Type: application/json' \
  --data "$PATCH_ONE" \
  "$API_URL/value" >/dev/null

wait_for_log 'Server update: {"name":"gain","target":"GAIN_LOCAL","value":-12.5}' "$DSP_LOG"

echo "Patching mute via curl..."
PATCH_TWO='{"settings":{"audio":{"GAIN_LOCAL":{"mute":true}}}}'
curl -sf \
  -X PATCH \
  -H 'Content-Type: application/json' \
  --data "$PATCH_TWO" \
  "$API_URL/value" >/dev/null

wait_for_log 'Server update: {"name":"mute","target":"GAIN_LOCAL","value":true}' "$DSP_LOG"

if rg -n 'Error processing parameter setting|Unknown block|Failed to create block' "$DSP_LOG" >/dev/null 2>&1; then
  echo "DSP log contains parameter/configuration errors" >&2
  exit 1
fi

if [[ ! -f "$OUTPUT_WAV" ]]; then
  echo "expected output wav not created: $OUTPUT_WAV" >&2
  exit 1
fi

echo
echo "Success."
echo "  fusion-server accepted POST/PATCH updates on $API_URL/value"
echo "  fusion_dsp connected to $SERVER_IP:7947 and received live gain/mute updates"
echo "  output wav created at $OUTPUT_WAV"
