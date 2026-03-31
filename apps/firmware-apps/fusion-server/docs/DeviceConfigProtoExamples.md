**Example Mapping**

This note records how the current draft protobuf boundary maps to real
conditioned output examples from
[../fusion-dsp-configurator-prototype/outputs](../fusion-dsp-configurator-prototype/outputs).

**Example 1**
[board1_1.json](../fusion-dsp-configurator-prototype/outputs/board1_1.json)

Observed:
- response envelope with `request_id`, `response_id`, `status_code`,
  `status_message`, `version`, `result`
- `result.devices[0]` contains:
  - `id`
  - `label`
  - `device_type`
  - `location`
  - `cost`
  - `connections_device_in`
  - `connections_device_out`
  - `dsp_static_config`
- `dsp_static_config` contains:
  - `session.property_settings`
  - `audio_tasks[*].property_settings`
  - `audio_tasks[*].blocks[*].property_settings`
  - `audio_tasks[*].blocks[*].terminal_channels`
  - `audio_tasks[*].block_connections`

Proto fit:
- `DroConditionedOutputEnvelope`: good fit
- `DroConditionedOutput`: good fit
- `DroConditionedDevice`: good fit for the observed fields
- `StaticConfiguration`: good fit for the observed nested DSP config

**Example 2**
[demo3_3board_aes67.json](../fusion-dsp-configurator-prototype/outputs/demo3_3board_aes67.json)

Observed additions beyond the first sample:
- `result.aes67_streams[*]`
- `result.devices[*].cores[*]`
- `dsp_static_config.task_connections[*]`

Important concrete findings:
- `cores` is not a number; it is a repeated object with utilization fields and
  `block_ids`
- `task_connections` uses:
  - `source_task`
  - `output_block`
  - `output_channel`
  - `destination_task`
  - `input_block`
  - `input_channel`
- AES67 streams contain:
  - `stream_id`
  - `stream_name`
  - `direction`
  - `multicast_destination_ip`
  - `source_device`
  - `channels`
  - `description`
  - `destination_device`

Proto changes made from this mapping:
- added `DroCore`
- changed `TaskConnection` to use `output_block` / `input_block`

**Additional Spot Checks**
[board1_2.json](../fusion-dsp-configurator-prototype/outputs/board1_2.json),
[demo3_2board.json](../fusion-dsp-configurator-prototype/outputs/demo3_2board.json),
and
[gym_sample_composite_2.json](../fusion-dsp-configurator-prototype/outputs/gym_sample_composite_2.json)
were checked for shape consistency.

Observed:
- same `result` top-level keys
- same `result.devices[*]` key set
- same `dsp_static_config` key set

Additional note:
- sampled `parameter_settings` entries were scalar values with no `index`
  field, which fits the current draft but does not prove indexed parameter
  settings never occur

**Remaining Unresolved Areas**
- `latencies` has not yet been observed with real entries
- Fusion Connect additions are currently confirmed only as:
  - derived `audio_streams`
  - `settings.audio`, initialized empty in the old launcher flow
- no real launcher-built `PUT /device` payload sample is checked in yet
