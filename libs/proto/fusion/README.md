Fusion Protocol Buffers
=======================

This directory is the draft home for shared Fusion protobuf contracts.

The first target is the deployment package boundary used between producers of
conditioned DSP configuration and `fusion-server`. This is intentionally not a
model of internal replicated state and it is not a replacement for the
runtime-oriented `/settings/audio/...` patch API.

Current scope:

- `device_config.proto`: first-pass typed model for the `PUT /device`
  deployment package

Out of scope for the first pass:

- internal `/state` persistence format
- websocket notification payloads
- runtime sparse/indexed patch operations for live audio settings

