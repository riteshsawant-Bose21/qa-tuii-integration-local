# Fusion Debug Toolkit (Device SSH)

This folder contains two scripts for QA and engineering diagnostics on deployed Fusion devices over SSH.

## Scripts

- `fusion_debug_logging.sh`: Enable or disable verbose logging for selected services.
- `fusion_collect_logs.sh`: Collect diagnostic bundles from one or more devices.

## Requirements

- Run from a local machine with SSH access to devices.
- Device targets are passed as `root@<device_ip>`.
- Local tools required: `ssh`, `curl`, `awk`, `sed`, `grep`.

## Usage

```bash
./fusion_debug_logging.sh root@192.168.1.10 root@192.168.1.11
./fusion_collect_logs.sh root@192.168.1.10 root@192.168.1.11
```

## fusion_debug_logging.sh behavior

- Prompts for action:
  - Enable verbose logging
  - Disable verbose logging
- Prompts for service (v1):
  - fusion-dsp (`-vv`)
  - fusion-system-monitor (`-vv`)
  - fusion-server (`-verbose`, kept as final argument when enabled)
- For each device (sequential):
  - Checks SSH connectivity
  - Resolves unit file path (`/usr/lib/systemd/system` then `/lib/systemd/system`)
  - Creates backup: `<unit>.backup_YYYY-MM-DD_HH-MM-SS`
  - Applies idempotent update to `ExecStart`
  - Runs `systemctl daemon-reload`
  - Restarts only the modified service
  - Prints resulting `ExecStart`

## fusion_collect_logs.sh behavior

- Uses a single capture mode: collect all logs and diagnostics.
- For each device (sequential), stores logs under:

```text
debug_logs/
  log_<timestamp>/
    device_<ip>/
    fusion-dsp.log
    fusion-server.log
    fusion-system-monitor.log
    jackd.log
    ptp4l.log
    phc2sys.log
    ptp4l_time_status.txt
    dmesg.log
    journalctl-full.log
    devices.json
    config.json
    system/
      ip_addr.txt
      ip_route.txt
      df.txt
      ps.txt
      lsmod.txt
      cpu_usage.txt
      memory_usage.txt
```

- On command/API/service failures, writes error details into the corresponding output file.
- At completion, prints processed/failure counts and output path.
- Collection always includes service logs, full journalctl logs, kernel log, API data, and system diagnostics.
- Each script run creates a new timestamp directory so previous dumps are retained.

## Notes

- Device processing is sequential and prints each step as it runs.
- `fusion-connect` is intentionally not included in this first iteration.