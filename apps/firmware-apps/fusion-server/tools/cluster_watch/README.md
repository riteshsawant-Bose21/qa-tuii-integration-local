# Cluster Watch

Standalone control-plane watcher for reproducing and diagnosing cluster disruption cases where one device joins and the VIP or memberlist view collapses.

It polls:

- `GET /devices` on the VIP
- `GET /cluster/members` on the VIP
- `GET /devices` on each direct node
- `GET /cluster/members` on each direct node

It reports:

- mismatched device sets across nodes
- primary count drift (`is_primary`)
- mismatched alive-member views
- unreachable endpoints
- transitions between `OK` and `DIVERGED`
- recovery duration after divergence or VIP timeout windows
- inferred VIP outage episodes with start, end, and duration

## Build

```bash
make cluster-watch
```

## Example

```bash
./build/cluster_watch \
  -vip http://192.168.2.100:8080 \
  -interval 1s \
  -fail-after 10s
```

By default, `cluster_watch` auto-discovers direct node URLs from the VIP `GET /devices` response.
It also writes a timestamped log file under `build/`, for example:

```text
build/cluster_watch_20260522_083000.log
```

To override the log destination:

```bash
./build/cluster_watch \
  -vip http://192.168.2.100:8080 \
  -log-file build/my_long_soak.log
```

If you want to override that and force a specific node list:

```bash
./build/cluster_watch \
  -vip http://192.168.2.100:8080 \
  -discover-nodes=false \
  -nodes http://192.168.2.2:8080,http://192.168.2.3:8080,http://192.168.2.4:8080
```

## Recommended Repro Flow

1. Start the watcher against the VIP.
2. Power on only the DSP nodes and wait until the watcher reports `OK`.
3. Begin your normal `GET /devices` polling workload against the VIP.
4. Power on Blue Pal.
5. Watch for:
   - VIP `devices` count dropping
   - one node seeing a smaller device set than the others
   - Blue Pal becoming the sole primary
   - `alive_members` disagreement across endpoints

## Exit Behavior

- Healthy state: exits `0` on timeout or Ctrl-C.
- Persistent divergence: exits non-zero once the same unhealthy state lasts for `-fail-after`.
- Set `-fail-after 0` if you want watch-only mode with no fail-fast exit.

## Notes

- If you pass `-nodes`, those URLs must be reachable from the machine running `cluster_watch`.
- The watcher accepts both string and numeric memberlist `state` values from `GET /cluster/members`.
- The watcher accepts member addresses encoded as either `address` or `Addr`.
