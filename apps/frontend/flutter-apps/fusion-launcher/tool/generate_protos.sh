#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
APP_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
REPO_ROOT=$(cd "$APP_DIR/../../../.." && pwd)
PROTO_ROOT="$REPO_ROOT/libs/proto"
OUT_DIR="$APP_DIR/lib/generated/proto"
PLUGIN="$APP_DIR/tool/protoc-gen-dart"

mkdir -p "$OUT_DIR"

protoc \
  -I "$PROTO_ROOT" \
  --plugin=protoc-gen-dart="$PLUGIN" \
  --dart_out="$OUT_DIR" \
  "$PROTO_ROOT/fusion/device_config.proto"
