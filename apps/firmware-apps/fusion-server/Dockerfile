FROM alpine:latest

RUN apk --no-cache add \
    curl \
    haproxy \
    keepalived \

    RUN mkdir -p /etc/haproxy /run/haproxy && \
    mkdir -p /etc/keepalived

WORKDIR /app

COPY fusion-server .
RUN chmod +x /app/fusion-server

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

COPY haproxy.cfg /etc/haproxy/haproxy.cfg

COPY keepalived-primary.conf /etc/keepalived/
COPY keepalived-backup1.conf /etc/keepalived/
COPY keepalived-backup2.conf /etc/keepalived/
COPY keepalived-backup3.conf /etc/keepalived/

RUN chmod 644 /etc/haproxy/haproxy.cfg && \
    chmod 644 /etc/keepalived/*.conf && \
    chown root:root /etc/haproxy/haproxy.cfg /etc/keepalived/*.conf

ENTRYPOINT ["/app/entrypoint.sh"]
