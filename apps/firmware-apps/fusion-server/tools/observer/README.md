# Create an instance to build under arm64
```
multipass launch -n arm-builder -c 2 -m 4G -d 10G --cloud-init - << EOF
#cloud-config
packages:
  - build-essential
  - g++-aarch64-linux-gnu
  - libjsoncpp-dev
EOF
```

# Create the target directory
```
multipass exec arm-builder -- mkdir -p observer
```

# Copy the source to the instance and build
```
multipass transfer Makefile arm-builder:observer/Makefile
multipass transfer observer.cpp arm-builder:observer/observer.cpp
multipass exec arm-builder -- bash -c "cd observer; make arm64"
```

# Copy the binary to fusion1
```
multipass transfer arm-builder:observer/build/arm64/observer /tmp
multipass transfer /tmp/observer fusion1:/tmp
multipass exec fusion1 -- sudo mv /tmp/observer /usr/local/bin
```

# Launch
```
/usr/local/bin/observer 
Usage: /usr/local/bin/observer <server_ip> <port> <key>
Example: /usr/local/bin/observer 127.0.0.1 7947 volume
```
