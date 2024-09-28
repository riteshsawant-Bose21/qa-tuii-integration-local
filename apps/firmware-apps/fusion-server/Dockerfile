FROM alpine:latest

RUN apk --no-cache add ca-certificates curl iputils

WORKDIR /app

COPY fusion-gossip .

RUN chmod +x /app/fusion-gossip

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

CMD ["./fusion-gossip"]
