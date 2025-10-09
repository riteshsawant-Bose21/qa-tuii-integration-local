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
/usr/local/bin/cluster_listener <port>
```

## Example Output

Cluster status will be displayed with timestamps:

```
2024-06-12T14:23:45Z {"cluster_id": "main", "status": "active", "nodes": [{"id": "node1", "state": "online"}, {"id": "node2", "state": "offline"}], "load": 0.42}
2024-06-12T14:23:47Z {"cluster_id": "main", "status": "active", "nodes": [{"id": "node1", "state": "online"}, {"id": "node2", "state": "online"}], "load": 0.38}
2024-06-12T14:23:50Z {"cluster_id": "main", "status": "degraded", "nodes": [{"id": "node1", "state": "online"}, {"id": "node2", "state": "offline"}], "load": 0.65}```
