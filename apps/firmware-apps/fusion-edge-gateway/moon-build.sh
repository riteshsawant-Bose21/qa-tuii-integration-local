#!/bin/bash
set -euo pipefail

# Build the fusion-edge-gateway binary.

source /home/ec2-user/fusion-mini-build-cache/bose/fusion/yocto-sdk/environment-setup-cortexa53-crypto-poky-linux
make release