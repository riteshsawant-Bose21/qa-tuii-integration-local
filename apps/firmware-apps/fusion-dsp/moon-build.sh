#!/bin/bash
set -euo pipefail

# Build the fusion-dsp binary in a single moon task.

source /home/ec2-user/fusion-mini-build-cache/bose/fusion/yocto-sdk/environment-setup-cortexa53-crypto-poky-linux
python3 ./waf configure --platform=varmini
python3 ./waf build