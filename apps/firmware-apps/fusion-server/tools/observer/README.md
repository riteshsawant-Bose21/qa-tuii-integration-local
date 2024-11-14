multipass launch -n arm-builder -c 2 -m 4G -d 10G --cloud-init - << EOF
#cloud-config
packages:
  - build-essential
  - g++-aarch64-linux-gnu
  - libjsoncpp-dev
EOF

# Install static library package for ARM64
sudo apt-get install libjsoncpp-dev:arm64

# Change LIBS in Makefile to use full path
LIBS := -l:/usr/lib/aarch64-linux-gnu/libjsoncpp.a -static-libgcc -static-libstdc++

# Create the target directory
multipass exec arm-builder -- mkdir -p observer

multipass exec arm-builder -- sudo apt-get update
multipass exec arm-builder -- sudo apt-get install -y libjsoncpp-dev

# Copy the Makefile to the instance
multipass transfer Makefile arm-builder:observer/Makefile
multipass transfer observer.cpp arm-builder:observer/observer.cpp


multipass transfer arm-builder:observer/build/arm64/observer /tmp
multipass transfer /tmp/observer fusion1:/tmp
multipass exec fusion1 -- sudo mv /tmp/observer /usr/local/bin

