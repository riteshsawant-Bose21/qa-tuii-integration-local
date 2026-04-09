#!/bin/bash
set -euo pipefail

# Build the fusion-edge-gateway binary.

export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
export SSL_CERT_DIR=/etc/ssl/certs
source /home/ec2-user/fusion-nano-build-cache/bose/fusion-nano/yocto-sdk/environment-setup-armv8a-poky-linux
make release