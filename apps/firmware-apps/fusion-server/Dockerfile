FROM alpine:latest

# Install necessary packages
RUN apk --no-cache add \
    ca-certificates \
    curl \
    iputils \
    haproxy \
    keepalived

# Create necessary directories
RUN mkdir -p /etc/haproxy /run/haproxy && \
    mkdir -p /etc/keepalived && \
    touch /etc/keepalived/keepalived.conf && \
    chmod 644 /etc/keepalived/keepalived.conf

WORKDIR /app

# Copy the fusion-gossip binary
COPY fusion-gossip .
RUN chmod +x /app/fusion-gossip

# Copy the HAProxy wrapper script
COPY haproxy-wrapper.sh /usr/local/bin/haproxy-wrapper
RUN chmod +x /usr/local/bin/haproxy-wrapper

# Copy the entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Copy HAProxy configuration
COPY haproxy.cfg /etc/haproxy/haproxy.cfg

# Set appropriate permissions
RUN chmod 644 /etc/haproxy/haproxy.cfg && \
    chown root:root /etc/haproxy/haproxy.cfg /etc/keepalived/keepalived.conf

# Set the entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]

# Set PATH to include the wrapper script
ENV PATH="/usr/local/bin:${PATH}"
