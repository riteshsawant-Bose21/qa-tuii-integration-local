#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
APP_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
REPO_ROOT=$(cd "$APP_DIR/../../../.." && pwd)
PROTO_ROOT="$REPO_ROOT/libs/proto"
OUT_DIR="$REPO_ROOT/libs/flutter-libs/fusion_lib/lib/generated/proto"
PLUGIN="$APP_DIR/tool/protoc-gen-dart"
PROTOBUF_INCLUDE="/opt/homebrew/include"

mkdir -p "$OUT_DIR"

protoc \
  -I "$PROTO_ROOT" \
  -I "$PROTOBUF_INCLUDE" \
  --plugin=protoc-gen-dart="$PLUGIN" \
  --dart_out="$OUT_DIR" \
  "$PROTOBUF_INCLUDE/google/protobuf/struct.proto" \
  "$PROTOBUF_INCLUDE/google/protobuf/timestamp.proto" \
  "$PROTO_ROOT/fusion/controllers.proto" \
  "$PROTO_ROOT/fusion/device_config.proto" \
  "$PROTO_ROOT/fusion/device_config_audio.proto" \
  "$PROTO_ROOT/fusion/device_config_dro.proto" \
  "$PROTO_ROOT/fusion/device_config_static.proto" \
  "$PROTO_ROOT/fusion/devices.proto" \
  "$PROTO_ROOT/fusion/health.proto" \
  "$PROTO_ROOT/fusion/metadata.proto" \
  "$PROTO_ROOT/fusion/pava.proto" \
  "$PROTO_ROOT/fusion/sessions.proto" \
  "$PROTO_ROOT/fusion/software_update.proto" \
  "$PROTO_ROOT/fusion/tasks.proto" \
  "$PROTO_ROOT/fusion/time_machine.proto" \
  "$PROTO_ROOT/fusion/udp.proto" \
  "$PROTO_ROOT/fusion/version.proto" \
  "$PROTO_ROOT/fusion/vip.proto" \
  "$PROTO_ROOT/fusion/websocket.proto"
