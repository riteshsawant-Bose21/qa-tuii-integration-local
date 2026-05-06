# Fusion Config Replication Script

This folder contains a standalone script to replicate device identity fields and DSP configuration to a target Fusion device.

## Before you run

Place both source files in this folder before running the script:

- `devices.json`
- `config.json`

The script reads these files from its own directory and will fail if either file is missing.

## Files in this folder

- `fusion_replicate_config.sh`: Main replication script
- `devices.json`: Source device metadata (must be a JSON array) (ignored in git)
- `config.json`: Source configuration payload for `/value` (ignored in git)
- `visualizer.py`: Optional visualization generator

## What the script does

Given a target VIP:

1. Validates required tools (`curl`, `jq`) and source files.
2. Calls `GET http://<ip>:8080/devices`.
3. Verifies source and target device counts match exactly.
4. Shows a confirmation summary (index, id, location, name for source and target).
5. On confirmation, patches each target device by array order with:
   - `id`
   - `location`
   - `name`
6. Posts full `config.json` to `POST http://<ip>:8080/value`.
7. Optionally asks whether to generate a visualization image from `config.json`.

## Mapping behavior

Device mapping is by array index only.

- Source device at index `i` in `devices.json`
- Target device at index `i` from `GET /devices`

## Prerequisites

Required:

- macOS/Linux shell
- `curl`
- `jq`
- Target API reachable on `http://<ip>:8080`

Optional for visualization:

- Graphviz binary (`dot`)
- Python 3

Install system tools on macOS:

```bash
brew install jq graphviz
```

## Usage

From this folder:

```bash
./fusion_replicate_config.sh <target_ip>
```

Example:

```bash
./fusion_replicate_config.sh 10.1.123.100
```

Help:

```bash
./fusion_replicate_config.sh --help
```

## Interactive prompts

You will see two prompts:

1. `Proceed with replication? [y/N]`
   - `y`/`yes` continues
   - anything else aborts with no changes

2. `Generate visualization output from config.json now? [y/N]`
   - `y`/`yes` attempts to generate `dsp_diagram_out.png`
   - anything else skips visualization

## Visualization behavior (automatic .venv handling)

If you choose visualization:

1. Script looks for `./.venv/bin/python`.
2. If missing, script creates `./.venv` automatically.
3. Script ensures Python package `graphviz` is installed in that `.venv`.
4. Script requires `dot` binary in PATH.
5. Script runs:
   - `python visualizer.py -o config.json -f dsp_diagram_out.png`

No manual `source .venv/bin/activate` is required.

## Output files

Replication:

- No new JSON output file is written by the script.
- Device/API changes are applied on target hardware.

Visualization (optional):

- `dsp_diagram_out.png` in this folder.

## Failure behavior

The script fails fast for core replication errors:

- Missing required tools/files
- Invalid JSON in source files
- `GET /devices` not returning JSON array
- Source/target device count mismatch
- PATCH/POST API errors

Visualization errors are non-fatal:

- Replication can still succeed even if image generation fails.

## Quick troubleshooting

Device count mismatch:

- Confirm `devices.json` corresponds to the same class of target hardware.

API unreachable:

- Check target IP, network route, and service on port 8080.

`dot` not found:

```bash
brew install graphviz
```

Permission denied running script:

```bash
chmod +x fusion_replicate_config.sh
```
