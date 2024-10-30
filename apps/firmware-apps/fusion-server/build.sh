#!/bin/bash
set -euo pipefail

# Define variables
BINARY_NAME="fusion-server"
ARCH="arm64"
OS="linux"
DOCKER_IMAGE_NAME="fusion-server"
EXPECTED_BINARY="${BINARY_NAME}_${OS}_${ARCH}"

# Clean up old binary if it exists
if [ -f "$BINARY_NAME" ]; then
    echo "Removing old binary..."
    rm "$BINARY_NAME"
fi

# Build the binary
echo "Building ${BINARY_NAME} for ${OS}_${ARCH}..."
make "build-${OS}-${ARCH}"

# Check if the build produced the expected binary
if [ ! -f "$EXPECTED_BINARY" ]; then
    echo "Error: Build failed to produce ${EXPECTED_BINARY}"
    exit 1
fi

# Rename the binary
echo "Renaming binary..."
mv "$EXPECTED_BINARY" "$BINARY_NAME"

echo "Build process completed successfully."
