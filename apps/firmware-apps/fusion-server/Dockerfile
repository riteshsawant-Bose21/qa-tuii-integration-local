FROM alpine:latest

# Install necessary packages including ZeroMQ
RUN apk --no-cache add \
    ca-certificates \
    curl \
    iputils \
    haproxy \
    keepalived \
    zeromq

# Create necessary directories
RUN mkdir -p /etc/haproxy /run/haproxy && \
    mkdir -p /etc/keepalived

WORKDIR /app

# Copy the fusion-gossip binary
COPY fusion-gossip .
RUN chmod +x /app/fusion-gossip

# Copy the entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Copy HAProxy configuration
COPY haproxy.cfg /etc/haproxy/haproxy.cfg

# Copy all Keepalived configuration files
COPY keepalived-primary.conf /etc/keepalived/
COPY keepalived-backup1.conf /etc/keepalived/
COPY keepalived-backup2.conf /etc/keepalived/
COPY keepalived-backup3.conf /etc/keepalived/

# Set appropriate permissions
RUN chmod 644 /etc/haproxy/haproxy.cfg && \
    chmod 644 /etc/keepalived/*.conf && \
    chown root:root /etc/haproxy/haproxy.cfg /etc/keepalived/*.conf

# Set the entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
