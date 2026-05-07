# `/value` Migration Table

| Old `/value` usage | Old example | New API | Notes |
|---|---|---|---|
| Read full generic state | `GET /value` | `GET /state` | Internal/admin only. |
| Read one generic key | `GET /value?key=settings` | `GET /state?key=settings` | Internal/admin only. |
| Snapshot definition upsert | `PATCH /value` with `{"snapshots": {...}}` | `POST /snapshots` or `PUT /snapshots/{id}` | Public typed endpoint. |
| Scene-set upsert | `PATCH /value` with `{"scene_sets": {...}}` | `POST /scene-sets` or `PUT /scene-sets/{id}` | Public typed endpoint. |
| Activate snapshot | indirect config-style flow or old mixed state mutation | `POST /snapshots/activate/{id}` | Public typed endpoint. |
| Devices list | `GET /value?key=devices` or parsing generic state | `GET /devices` | Public typed endpoint returning `DeviceListResponse`. |
| Device update | generic config mutation of device fields | `PATCH /device/{id}` or `PUT /device` | Public typed device APIs. Exact route depends on full replace vs patch flow. |
| Read full audio settings subtree | `GET /value?key=settings.audio` | `GET /settings/audio` | Public runtime settings read API. |
| Read one audio block settings object | `GET /value?key=settings.audio.{blockId}` | `GET /settings/audio/{blockId}` | Public runtime settings read API for a single block. |
| Read one audio setting value | `GET /value?key=settings.audio.{blockId}.{param}` | `GET /settings/audio/{blockId}/{param}` | Returns `{ "value": ... }`. |
| Read one indexed audio setting value | `GET /value?key=settings.audio.{blockId}.{param}[{index}]` | `GET /settings/audio/{blockId}/{param}/{index}` | Returns `{ "value": ... }`. |
| Audio/settings clear | `DELETE /value` or patching generic state | `DELETE /settings/audio` | Public typed settings endpoint. |
| Audio/settings scalar update | `PATCH /value` with settings subtree | `PATCH /settings/audio/{blockId}/{param}` | Request body: `{ "value": ... }`. |
| Audio/settings indexed update | `PATCH /value` with settings subtree | `PATCH /settings/audio/{blockId}/{param}/{index}` | Request body: `{ "value": ... }`. |
| Dynamic config/test fixture writes | `PATCH /value` with nested audio/config blobs | `PATCH /state` | Internal/admin only. This is what launcher/test tooling now uses instead of public `/value`. |
| WebSocket generic config patch | raw JSON `patch_config` payloads | protobuf `WebSocketRequest` / `WebSocketResponse` with `patch_config` | Transport is now protobuf-typed even if payload content may still be config-shaped. |

## Examples

### Old
```http
GET /value?key=settings.audio
```

### New
```http
GET /settings/audio
```

### Old
```http
GET /value?key=settings.audio.PEQ4385417.frequency
```

### New
```http
GET /settings/audio/PEQ4385417/frequency
```

### Old
```http
PATCH /value
{"settings":{"audio":{"GAIN528578446":{"gain":-12.0}}}}
```

### New
```http
PATCH /settings/audio/GAIN528578446/gain
{"value":-12.0}
```

### Old
```http
PATCH /value
{"snapshots":{"snap1":{"name":"My Snapshot"}}}
```

### New
```http
PUT /snapshots/snap1
```

### Old
```http
PATCH /value
{"scene_sets":{"set1":{"name":"Lobby"}}}
```

### New
```http
PUT /scene-sets/set1
```

### Old
```http
GET /value?key=devices
```

### New
```http
GET /devices
```
