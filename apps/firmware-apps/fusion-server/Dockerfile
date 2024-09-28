FROM alpine:latest

RUN apk --no-cache add ca-certificates curl iputils

WORKDIR /app

COPY fusion-gossip .

RUN chmod +x /app/fusion-gossip

CMD ["./fusion-gossip"]
