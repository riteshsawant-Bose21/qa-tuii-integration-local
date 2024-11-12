# Fusion Server

Fusion Server is a distributed configuration management system with high availability features, built using Go. It provides real-time configuration synchronization across multiple nodes with support for load balancing and failover.

## Features

- Distributed configuration storage with real-time synchronization
- High availability with HAProxy load balancing and Keepalived failover
- WebSocket support for real-time updates
- REST API for configuration management
- State persistence and recovery
- JSON import/export functionality
- Automatic HAProxy configuration management
- Health monitoring and debug capabilities

## Architecture

### Components

1. **State Management**
   - Distributed state synchronization across nodes
   - Version-based conflict resolution
   - Real-time state updates via WebSocket
   - Persistent storage of configuration data

2. **High Availability**
   - HAProxy load balancing across cluster nodes
   - Keepalived for VIP (Virtual IP) management
   - Automatic failover support
   - Dynamic backend server registration

3. **Networking**
   - Gossip-based cluster membership
   - WebSocket connections for real-time updates
   - REST API for configuration management
   - Unix Domain sockets for configuration management 
   - Health check endpoints

## Setup

#### Multipass

[Multipass](https://multipass.run/) is used to create and manage Ubuntu VM instances for development and testing. It provides a quick way to spin up consistent Ubuntu environments across different platforms.

**macOS**
```bash
brew install --cask multipass
```

**Ubuntu**
```bash
sudo snap install multipass
```

**Windows**
- Download the installer from [Multipass website](https://multipass.run/download/windows)


#### State Management

The system maintains a distributed state with the following features:
- Version-based conflict resolution
- Timestamp-based tie-breaking
- Real-time state synchronization
- Persistent state storage
- State verification and validation

## High Availability

### Load Balancing

HAProxy provides load balancing with:
- Round-robin distribution
- Health checks every 2 seconds
- Automatic backend server management
- Statistics monitoring

### Failover

Keepalived ensures high availability through:
- Virtual IP management
- Automatic master/backup failover
- VRRP protocol for IP takeover
- Quick failure detection

## Dependencies

- github.com/hashicorp/memberlist - Cluster membership and failure detection
- github.com/gorilla/websocket - WebSocket support
- Standard Go libraries

### Configuration

   **HAProxy Configuration**
   - Automatically generated based on cluster membership
   - Default configuration includes:
     - HTTP mode
     - Round-robin load balancing
     - Health checks on /getValue endpoint
     - Configurable timeouts and connection limits

   **Keepalived Configuration**
   - Virtual IP (VIP): 192.168.64.100
   - VRRP configuration for high availability
   - Automatic failover between nodes

   **Node Configuration**
   - Each node requires:
     - Unique node name
     - Bind address and port
     - Optional join address for cluster membership

## Installation

**Clone the repository and build the server**
```bash
git clone git@github.com:BoseProfessional/fusion-services.git
sh build.sh
```

## Usage
### Launch a single server instance
```bash
./launch.sh
```

**Create multiple instances with default name "fusion"**
```bash
./launch.sh --instances 3
```

### Launch from within instance
**This would only be used during development to restart and update the server.**
```bash
./fusion-server --name <node-name> --addr <bind-address> --port <port> [--join <existing-node-address>]
```

### Stopping instances
**Stop instances with default name**
```bash
./launch.sh --kill
```

**Stop instances with specific name**
```bash
./launch.sh --name fusion --kill
```

### API Endpoints

1. **Configuration Management**
   - `POST /setValue` - Set a configuration value
   - `GET /getValue` - Retrieve configuration value(s)
   - `GET /ws` - WebSocket endpoint for real-time updates

2. **State Management**
   - `POST /upload` - Import configuration state
   - `GET /download` - Export configuration state

3. **Volume Control**
   - `POST /setVolume` - Update volume settings

### Set a single value
```bash
curl -X POST http://192.168.64.100:8080/setValue \
  -H "Content-Type: application/json" \
  -d '{"key": "server.name", "value": "production-1"}'
```

### Set a nested configuration object
```bash
curl -X POST http://192.168.64.100:8080/setValue \
  -H "Content-Type: application/json" \
  -d '{
    "key": "database.config",
    "value": {
      "host": "localhost",
      "port": 5432,
      "maxConnections": 100
    }
  }'
```

### Get a specific value
```bash
curl "http://192.168.64.100:8080/getValue?key=server.name"
```

### Get all configuration values
```bash
curl http://192.168.64.100:8080/getValue
```

### Download current configuration state
```bash
curl -O http://192.168.64.100:8080/download
```

### Download and save with specific filename
```bash
curl http://192.168.64.100:8080/download > backup_config.json
```

## Websockets

### Simple connection that prints received messages
```bash
websocat ws://192.168.64.100:8080/ws
```

### Connect with interactive mode to send and receive messages
```bash
websocat -v ws://192.168.64.100:8080/ws
```

## Unix Domain Sockets
Unix Domain Sockets are used to communicate between server instances. The
socket is not public and can only be accessed within the internal network.

### Get all values
echo '{"action":"get"}' | nc -u localhost 7947

### Set a value
echo '{"action":"set","key":"test","value":"hello"}' | nc -u localhost 7947

## Security

- TLS support for secure communication
- WebSocket origin checking
- File permission management
- Proper service isolation

## Troubleshooting

1. **VIP Issues**
   - Check network interface configuration
   - Verify Keepalived status
   - Monitor VRRP advertisements

2. **Cluster Synchronization**
   - Check node connectivity
   - Verify gossip protocol communication
   - Monitor state version numbers

3. **Load Balancer Issues**
   - Check HAProxy configuration
   - Verify backend health checks
   - Monitor HAProxy logs

#### Basic Commands

1. **Create a new instance**
```bash
./launch.sh
```

2. **List instances**
```bash
multipass list
```

3. **Start/Stop instances**
```bash
multipass stop fusion1
multipass start fusion1
```

4. **Access instance shell**
```bash
multipass shell fusion1
```

5. **Get instance information**
```bash
multipass info fusion1
```

6. **Mount local directory**
```bash
multipass mount /local/path fusion1:/home/ubuntu/mounted
```

7. **Delete instance**
```bash
multipass delete fusion1
multipass purge  # Remove deleted instances completely
```

#### Creating Multiple Nodes

For a three-node cluster setup:

```bash
# Create instances
./launch.sh --instances 3

# Get IP addresses
multipass list

# Shell into instances
multipass shell fusion1
```

#### Useful Tips

1. **Transfer files to instance**
```bash
multipass transfer /local/file.txt fusion1:/home/ubuntu/
```

2. **Execute command in instance**
```bash
multipass exec fusion1 -- command
```

3. **View instance logs**
```bash
multipass exec fusion1 -- cat /var/log/cloud-init-output.log
multipass exec fusion1 -- sudo journalctl
multipass exec fusion1 -- sudo dmesg -w
multipass exec fusion1 -- sudo journalctl -u haproxy -f
multipass exec fusion1 -- sudo journalctl -u keepalived-server -f
multipass exec fusion1 -- sudo journalctl -u fusion-server -f
```
4. **Network configuration**
```bash
# Get instance IP address
multipass info fusion1 | grep IPv4
```

#### Troubleshooting Multipass

1. **Instance fails to start**
   - Check cloud-init logs:
   ```bash
   multipass exec fusion1 -- cat /var/log/cloud-init-output.log
   ```
   - Verify resource availability on host machine
   - Ensure cloud-config.yaml is valid

2. **Network connectivity issues**
   - Verify host network connectivity
   - Check instance network status:
   ```bash
   multipass exec fusion1 -- ip addr
   ```
3. **systemd status**
```bash
multipass exec fusion1 -- systemctl status haproxy
multipass exec fusion1 -- systemctl status keepalived
multipass exec fusion1 -- systemctl status fusion-server
```

4. **Mount problems**
   - Ensure source path exists
   - Check permissions on host directory
   - Unmount and retry:
   ```bash
   multipass unmount fusion1
   multipass mount /local/path fusion1:/home/ubuntu/mounted
   ```

### Testing

**Launch a single server instance**
```bash
./launch.sh
```
**Build and run test**
```bash
make test
```

## Monitoring

1. **Metrics Server**
   - Available on configurable port (default: 9090)
   - Endpoints:
     - `/metrics` - Complete system metrics
     - `/cluster/status` - Detailed cluster information
     - `/health` - Health check endpoint
   - Metrics include:
     - Cluster health and membership
     - Configuration state statistics
     - System resource usage
     - Network connectivity
     - Process health

2. **HAProxy Statistics**
   - Real-time server status
   - Connection statistics
   - Health check status

3. **Debug Mode**
   - Cluster state monitoring
   - Health check logging
   - State verification
   - Connectivity testing

### Monitoring Endpoints

#### Get Complete System Metrics
```bash
curl http://192.168.64.100:9090/metrics
```
Response includes:
- Timestamp
- Cluster metrics
- Node health
- Configuration state
- Network statistics
- Process metrics
- HAProxy status

#### Check Cluster Status
```bash
curl http://192.168.64.100:9090/cluster/status
```
Response includes:
- Member count
- Alive/suspect/dead nodes
- Cluster health percentage
- Node details
- Ping latency

### Command Line Flags
```bash
./fusion-server \
  --name <node-name> \
  --addr <bind-address> \
  --port <port> \
  [--join <existing-node-address>]
```

### Sample Metrics Output
```json
{
  "timestamp": "2024-11-08T12:00:00Z",
  "cluster": {
    "member_count": 3,
    "alive_count": 3,
    "local_node": "node1",
    "cluster_health": 100,
    "members": [
      {
        "name": "node1",
        "address": "192.168.64.101",
        "port": 7946,
        "state": "ALIVE"
      }
    ]
  },
  "node_health": {
    "status": "ALIVE",
    "uptime_seconds": 3600,
    "health_check_count": 720
  },
  "config_keys": 15,
  "websocket_clients": 3,
  "cpu_usage": 2.5,
  "memory_usage": 1048576,
  "goroutines": 25
}
```

### Monitoring Integration

The metrics server can be integrated with monitoring systems:

1. **Prometheus Configuration**
```yaml
scrape_configs:
  - job_name: 'fusion'
    static_configs:
      - targets: ['localhost:9090']
```

2. **Grafana Dashboard**
   - Import provided dashboard template
   - Add Prometheus data source
   - Configure alerts based on metrics

### Common Monitoring Commands

1. **Check all metrics**
```bash
curl -s http://192.168.64.100:9090/metrics | jq
```

2. **Monitor cluster health**
```bash
watch -n 1 'curl -s http://192.168.64.100:9090/health'
```

3. **Track cluster membership**
```bash
watch -n 1 'curl -s http://192.168.64.100:9090/cluster/status | jq .members'
```

4. **System resource usage**
```bash
curl -s http://192.168.64.100:9090/metrics | jq 'select(.cpu_usage, .memory_usage, .goroutines)'
```

### Diagram

```mermaid
graph TB
    subgraph Client
        C1[Client] 
        C2[Client]
        C3[Client]
    end

    subgraph Load Balancer
        VIP[Virtual IP<br>192.168.64.100]
        HAP[HAProxy<br>Port 80]
        KA[Keepalived<br>VRRP]
    end

    subgraph Server
        subgraph Node 1
            F1[Fusion Server 1<br>Port 8080]
            S1[(State 1)]
        end
        
        subgraph Node 2
            F2[Fusion Server 2<br>Port 8080]
            S2[(State 2)]
        end
        
        subgraph Node 3
            F3[Fusion Server 3<br>Port 8080]
            S3[(State 3)]
        end
    end

    %% Client connections
    C1 --> VIP
    C2 --> VIP
    C3 --> VIP
    
    %% VIP to HAProxy
    VIP --> HAP
    KA --> VIP
    
    %% HAProxy to Fusion Servers
    HAP --> F1
    HAP --> F2
    HAP --> F3
    
    %% State connections
    F1 --> S1
    F2 --> S2
    F3 --> S3
    
    %% Gossip protocol connections
    F1 <--> F2
    F2 <--> F3
    F1 <--> F3

    classDef client fill:#a8e6cf
    classDef lb fill:#ffd3b6
    classDef server fill:#ffaaa5
    classDef state fill:#dcedc1
    
    class C1,C2,C3 client
    class VIP,HAP,KA lb
    class F1,F2,F3 server
    class S1,S2,S3 state
```

## Project Structure

```
fusion-server/
├── build/
│   └── fusion-server*        # Compiled binary
├── fusion/
│   ├── cmd/
│   │   └── fusion/
│   │       └── main.go      # Application entry point
│   ├── configs/
│   │   ├── entrypoint.sh*   # Container entrypoint script
│   │   ├── keepalived.conf  # Primary Keepalived configuration
│   │   └── keepalived-backup.conf
│   └── internal/
│       ├── api/             # API type definitions
│       ├── cluster/         # Cluster management
│       ├── config/          # Configuration handling
│       ├── logging/         # Debug logging facilities
│       └── network/         # Network and proxy management
├── tools/
│   ├── noise-generator*     # Testing utility
│   ├── build.sh
│   ├── random.sh
│   └── main.go
├── Makefile
├── build.sh
├── fusion-server.yaml
└── README.md
```
