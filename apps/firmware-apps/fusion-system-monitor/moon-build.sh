#!/bin/bash
set -euo pipefail

# Build the fusion-system-monitor binary in a single moon task.

source /home/ec2-user/fusion-nano-build-cache/bose/fusion-nano/yocto-sdk/environment-setup-armv8a-poky-linux
python3 ./waf configure --platform=varmini
python3 ./waf build
ls -ltr