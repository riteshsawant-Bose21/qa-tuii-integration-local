#!/bin/bash
set -euo pipefail

# Build the stress_tester binary.
#
# Usage:
#   ./build_stress_tester.sh [--target <target>] [--arch <arch>]
#     --target    Target OS (default: darwin)
#     --arch      Target architecture (default: arm64)

BINARY_NAME="stress_tester"
TARGET="${TARGET:-darwin}"
ARCH="${ARCH:-arm64}"

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --target)
      TARGET="$2"
      shift 2
      ;;
    --arch)
      ARCH="$2"
      shift 2
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Building $BINARY_NAME (${TARGET}/${ARCH})..."

if [[ -f "$BINARY_NAME" ]]; then
  echo "Removing old binary..."
  rm "$BINARY_NAME"
fi

GOWORK=off GOOS="$TARGET" GOARCH="$ARCH" go build -o "$BINARY_NAME" .

echo "Build complete: ${SCRIPT_DIR}/${BINARY_NAME}"
