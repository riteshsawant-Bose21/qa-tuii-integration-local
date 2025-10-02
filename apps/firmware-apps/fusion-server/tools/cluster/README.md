# UDP Cluster Listener

A UDP-based listener for fusion cluster updates

## Building for ARM64

### Create a Builder Instance
```bash
multipass launch -n arm-builder -c 2 -m 4G -d 10G --cloud-init - << EOF
#cloud-config
package_update: true
package_upgrade: false
packages:
 - g++
 - build-essential
 - libjsoncpp-dev
 - libspdlog-dev
 - libcurl4-openssl-dev
 - libboost-dev
 - libboost-program-options-dev
 - libjack-jackd2-dev
 - libsndfile1-dev

runcmd:
 - which g++
 - g++ --version
 - ld --version
EOF
```

### Setup Build Environment
```bash
# Copy the source to the instance and build
multipass transfer -r ../cluster arm-builder:
multipass exec arm-builder -- bash -c "cd cluster; make"

# Copy the binary to fusion1
multipass transfer arm-builder:cluster/cluster_listener /tmp
multipass transfer /tmp/cluster_listener fusion1:/tmp
multipass exec fusion1 -- sudo mv /tmp/cluster_listener /usr/local/bin
```

## Usage

Basic syntax:
```bash
/usr/local/bin/cluster_listener <server_ip> <port> <path>
```

## Example Output

Cluster status will be displayed with timestamps:

```
14:23:45 settings.audio.volume changed from: 0.5 to: 0.7
14:23:47 settings.audio.peq1.gain[2] changed from: -6.0 to: -3.0
14:23:50 devices[0].channel.volume changed from: 0.8 to: 0.6
```
