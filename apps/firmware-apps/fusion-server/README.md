# Fusion High-Availability Gossip-Based Distributed System

## Architecture Overview

This project implements a high-availability, gossip-based distributed system using Docker containers. The system consists of multiple Data Service Provider (DSP) nodes that communicate using a gossip protocol, with a fault-tolerant load balancing layer for external access.

## Components

### 1. DSP Nodes (dsp1, dsp2, dsp3, dsp4)

- Implemented using custom `fusion-server` image
- Communicate via gossip protocol for configuration sharing
- Each node listens on port 7946 for inter-node communication
- Nodes join the cluster by connecting to dsp1 (172.18.0.3:7946)

### 2. Load Balancers (loadbalancer1, loadbalancer2)

- Use NGINX for load balancing
- Two instances for high availability
- Both expose port 80 for incoming traffic
- Health checks ensure the load balancers are functioning correctly

### 3. Keepalived (keepalived1, keepalived2)

- Manages high availability for load balancers
- Uses Virtual Router Redundancy Protocol (VRRP)
- Maintains a Virtual IP (VIP) that floats between load balancer instances
- Automatic failover if the primary load balancer fails

## Network Configuration

- Custom Docker network `fusionnet` (172.18.0.0/16)
- Each component has a static IP within this network
- Virtual IP (172.18.0.10) managed by Keepalived

## High Availability Features

1. **Load Balancer Redundancy**: Dual NGINX instances with Keepalived ensure continuous service even if one load balancer fails.
2. **Automatic Failover**: Keepalived automatically moves the Virtual IP to the healthy load balancer instance.
3. **DSP Node Resilience**: The gossip protocol allows the cluster to function and update even if some nodes are temporarily unavailable.

## Scalability

- Additional DSP nodes can be easily added to the cluster
- New nodes automatically join the gossip network through dsp1

## Configuration Management

- Gossip protocol enables efficient propagation of configuration changes across all DSP nodes
- Changes made to any node are automatically disseminated to all other nodes in the cluster

## Monitoring and Health Checks

- Load balancers have built-in health checks
- Keepalived monitors the status of NGINX processes
- Consider implementing additional monitoring for DSP nodes and overall system health

## Getting Started

1. Ensure Docker and Docker Compose are installed on your system
2. Clone this repository
3. Set up the necessary configuration files (`nginx.conf`, `keepalived-master.conf`, `keepalived-backup.conf`)
4. Run `docker compose up -d` to start the system
5. Access the service via the Virtual IP (172.18.0.10) on port 80

## Testing Failover

To test the high availability setup:

1. Stop the primary load balancer: `docker compose stop loadbalancer1`
2. Observe that the Virtual IP moves to the secondary load balancer
3. Restart the primary: `docker compose start loadbalancer1`
4. Verify that the system continues to function throughout this process

## Future Improvements

- Implement secure communication between nodes
- Add a service discovery mechanism for dynamic scaling
- Integrate with external monitoring and alerting systems
- Implement automated backup and restore procedures for configuration data


# Build image
docker build -t fusion-server .

# Start images
docker compose up

# Stop single instance
docker compose stop dsp2

# Watch logs
docker compose ps

# Start single instance
docker compose start dsp2

# More drastic removal
docker compose rm -sf dsp2

# Recreate and start the service:
docker compose up -d dsp2

# Verify loadbalancer
docker compose exec loadbalancer1 ip addr show eth0

# Simulate balancer failure
docker compose stop loadbalancer1

# Check that the virtual IP has moved to the backup node
docker compose exec loadbalancer2 ip addr show eth0

# Restart the first load balancer and observe the IP moving back:
docker compose start loadbalancer1