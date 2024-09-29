rm fusion-gossip
make build-linux-arm64
mv fusion-gossip_linux_arm64 fusion-gossip
docker build -t fusion-gossip .

