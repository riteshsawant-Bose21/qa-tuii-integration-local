**Purpose**
This note defines the first protobuf boundary for Fusion device deployment.

The goal is to type the device-ready deployment package exchanged with
`fusion-server`, not to model internal replicated state and not to replace the
runtime `/settings/audio/...` patch API.

**Boundary**
- Input to this contract:
  - conditioned DSP output produced by DSP tooling
  - deployment metadata assembled by launcher or another orchestrator
- Output of this contract:
  - `PUT /device` request body
  - typed Go and Dart models for packaging and validation
- Out of scope:
  - design-time project authoring input
  - private `/state` representation
  - sparse/indexed runtime patch operations

**Observed Conditioned Output**
The configurator outputs in
[../fusion-dsp-configurator-prototype/outputs](../fusion-dsp-configurator-prototype/outputs)
are response envelopes with this top-level shape:

- `request_id`
- `response_id`
- `status_code`
- `status_message`
- `version`
- `result`

Inside `result`, the currently observed sections are:

- `devices`
- `aes67_streams`
- `device_connections`
- `io_ports`
- `latencies`
- `total_cost`

The key structural observation is that deployable DSP configuration is stored
per device under `result.devices[*].dsp_static_config`, not as a single
top-level static configuration object.

**Current Deployment Package Sections**
The current first-pass `PUT /device` contract is based on the existing
launcher/server sections already used in the repo:

- `devices`
- `audio_streams`
- `settings`
- conditioned output from DSP tooling

This means the protobuf work should be a typing pass over the existing
deployment package rather than a new persistence model.

From launcher code inspection, the currently observed packaging behavior is:

- `devices`
  - taken directly from `droResponse["result"]["devices"]`
  - this is DRO-owned data, not a Fusion Connect addition
- `audio_streams`
  - derived in launcher from DRO `aes67_streams` and `device_connections`
- `settings.audio`
  - explicitly initialized as an empty object for deployment

**Recommended Mapping**
- configurator response envelope
  - `DroConditionedOutputEnvelope`
  - useful when integrating directly with configurator output files
- configurator `result`
  - `DroConditionedOutput`
  - the stable conditioned-output payload
- `result.devices[*]`
  - `DroConditionedDevice`
  - owns `dsp_static_config` for each device
- Fusion Connect / launcher additions
  - `FusionConnectAdditions`
  - wrapper for sections added outside raw DRO output
- `audio_streams`
  - `FusionConnectAudioStream`
  - use typed stream properties where the current model is already stable
- `settings.audio`
  - `FusionConnectAudioSettings`
  - `map<string, AudioBlockSettings>`
  - block id -> parameter name -> value
- `result.devices[*].dsp_static_config`
  - `StaticConfiguration`
  - this follows the shape of
    [static-configuration.json](/Users/gragan/inprogress/bose/fusion-monorepo/libs/schemas/fusion-dsp/static-configuration.json)

**Why This Boundary**
- It matches the real integration seam between launcher/tooling and
  `fusion-server`.
- It avoids forcing protobuf onto internal state too early.
- It lets runtime settings remain a focused JSON patch API until that surface is
  redesigned separately.
- It makes the separation between DRO-owned output and Fusion Connect-owned
  additions explicit in the type system.

**Known Gaps In The First Pass**
- `ParameterValue` currently supports scalar values and arrays only.
- No null/sparse array semantics are modeled.
- `Latency` is provisional because the inspected output samples did not include
  non-empty latency entries.
- if Fusion Connect later adds deployment metadata beyond `audio_streams` and
  `settings`, the wrapper will need to expand again

**Current Mapping Findings**
Mapping the draft against
[board1_1.json](../fusion-dsp-configurator-prototype/outputs/board1_1.json)
and
[demo3_3board_aes67.json](../fusion-dsp-configurator-prototype/outputs/demo3_3board_aes67.json)
and spot-checking
[board1_2.json](../fusion-dsp-configurator-prototype/outputs/board1_2.json),
[demo3_2board.json](../fusion-dsp-configurator-prototype/outputs/demo3_2board.json),
and
[gym_sample_composite_2.json](../fusion-dsp-configurator-prototype/outputs/gym_sample_composite_2.json)
surfaced these concrete points:

- `result.devices[*].dsp_static_config` maps well to `StaticConfiguration`
  for `session`, `audio_tasks`, `blocks`, `block_connections`, and
  `parameter_settings`
- `result.devices[*].cores` is an array of structured utilization objects, not
  a scalar count
- `dsp_static_config.task_connections[*]` uses `output_block` and `input_block`
  fields in observed samples
- `connections_device_in` and `connections_device_out` are arrays of string
  tuples and remain modeled conservatively as repeated string lists
- `aes67_streams` maps cleanly for the inspected AES67 sample
- launcher’s old `sendToDSP()` packaging reuses DRO `result.devices` directly
  and only adds:
  - derived `audio_streams`
  - empty `settings.audio`
- the top-level `result` keys and per-device keys were consistent across the
  additional sampled output files
- `parameter_settings` was observed with scalar numeric values and no index in
  the sampled output files

**Suggested Next Steps**
1. Map 2-3 real conditioned output JSON files into the revised proto.
2. Decide whether `PUT /device` should accept the full conditioned output
   envelope, the `result` payload, or a launcher-composed deployment package
   that embeds `conditioned_output`.
3. Refine message fields where the draft is too generic or too narrow.
4. Add code generation for Go and Dart.
5. Add round-trip golden tests from real deployment package examples.
