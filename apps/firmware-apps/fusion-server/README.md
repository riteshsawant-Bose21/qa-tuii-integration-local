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
   - Health check endpoints

## Setup

### Prerequisites

- Linux environment
- HAProxy
- Keepalived
- Go 1.x or higher

### Installation

1. Clone the repository and build the server:
```bash
go build -o fusion-server
```

2. Configure the cloud-init file for node setup:
```yaml
#cloud-config
package_update: true
package_upgrade: true
packages:
  - haproxy
  - keepalived
```

3. Set up the required directories:
```bash
sudo mkdir -p /etc/haproxy
sudo mkdir -p /etc/keepalived
sudo mkdir -p /var/lib/fusion
```

### Configuration

1. **HAProxy Configuration**
   - Automatically generated based on cluster membership
   - Default configuration includes:
     - HTTP mode
     - Round-robin load balancing
     - Health checks on /getValue endpoint
     - Statistics page on port 8404
     - Configurable timeouts and connection limits

2. **Keepalived Configuration**
   - Virtual IP (VIP): 192.168.64.100
   - VRRP configuration for high availability
   - Automatic failover between nodes

3. **Node Configuration**
   - Each node requires:
     - Unique node name
     - Bind address and port
     - Optional join address for cluster membership

## Usage

### Starting a Node

```bash
./fusion-server --name <node-name> --addr <bind-address> --port <port> [--join <existing-node-address>]
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

### State Management

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

## Monitoring

1. **HAProxy Statistics**
   - Available at `http://<node-ip>:8404/`
   - Real-time server status
   - Connection statistics
   - Health check status

2. **Debug Mode**
   - Cluster state monitoring
   - Health check logging
   - State verification
   - Connectivity testing

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

## Dependencies

- github.com/hashicorp/memberlist - Cluster membership and failure detection
- github.com/gorilla/websocket - WebSocket support
- Standard Go libraries

## Development Environment

### Multipass Setup

[Multipass](https://multipass.run/) is used to create and manage Ubuntu VM instances for development and testing. It provides a quick way to spin up consistent Ubuntu environments across different platforms.

#### Installation

1. **Ubuntu**
```bash
sudo snap install multipass
```

2. **macOS**
```bash
brew install --cask multipass
```

3. **Windows**
- Download the installer from [Multipass website](https://multipass.run/download/windows)

#### Basic Commands

1. **Create a new instance with cloud-config**
```bash
multipass launch --name fusion-1 --cloud-init cloud-config.yaml
```

2. **List instances**
```bash
multipass list
```

3. **Start/Stop instances**
```bash
multipass stop fusion-1
multipass start fusion-1
```

4. **Access instance shell**
```bash
multipass shell fusion-1
```

5. **Get instance information**
```bash
multipass info fusion-1
```

6. **Mount local directory**
```bash
multipass mount /local/path fusion-1:/home/ubuntu/mounted
```

7. **Delete instance**
```bash
multipass delete fusion-1
multipass purge  # Remove deleted instances completely
```

#### Creating Multiple Nodes

For a three-node cluster setup:

```bash
# Create instances
multipass launch --name fusion-1 --cloud-init cloud-config.yaml
multipass launch --name fusion-2 --cloud-init cloud-config.yaml
multipass launch --name fusion-3 --cloud-init cloud-config.yaml

# Get IP addresses
multipass list

# Shell into instances
multipass shell fusion-1
```

#### Useful Tips

1. **Transfer files to instance**
```bash
multipass transfer /local/file.txt fusion-1:/home/ubuntu/
```

2. **Execute command in instance**
```bash
multipass exec fusion-1 -- command
```

3. **View instance logs**
```bash
multipass exec fusion-1 -- cat /var/log/cloud-init-output.log
```

4. **Resource allocation**
```bash
# Launch with specific resources
multipass launch --name fusion-1 --cpus 2 --mem 2G --disk 10G --cloud-init cloud-config.yaml
```

5. **Network configuration**
```bash
# Get instance IP address
multipass info fusion-1 | grep IPv4
```

#### Troubleshooting Multipass

1. **Instance fails to start**
   - Check cloud-init logs:
   ```bash
   multipass exec fusion-1 -- cat /var/log/cloud-init-output.log
   ```
   - Verify resource availability on host machine
   - Ensure cloud-config.yaml is valid

2. **Network connectivity issues**
   - Verify host network connectivity
   - Check instance network status:
   ```bash
   multipass exec fusion-1 -- ip addr
   ```

3. **Mount problems**
   - Ensure source path exists
   - Check permissions on host directory
   - Unmount and retry:
   ```bash
   multipass unmount fusion-1
   multipass mount /local/path fusion-1:/home/ubuntu/mounted
   ```

## Diagram

```mermaid
graph TB
    subgraph Client Layer
        C1[Client] 
        C2[Client]
        C3[Client]
    end

    subgraph Load Balancer Layer
        VIP[Virtual IP<br>192.168.64.100]
        HAP[HAProxy<br>Port 80]
        KA[Keepalived<br>VRRP]
    end

    subgraph Server Layer
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