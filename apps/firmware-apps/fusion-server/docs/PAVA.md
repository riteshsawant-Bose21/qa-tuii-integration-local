# Launching Fusion Server

You can launch **fusion-server** from any location:

```bash
./fusion-server_darwin_arm64 --local
```

The `--local` flag disables features that aren’t available when running on macOS.

---

## Console Output

When you launch the server, you’ll likely see:

```
2025/10/29 13:26:57 Failed to create log directory: mkdir /var/log/fusion: permission denied
```

If you really want written logs, you can run using `sudo`.  
Otherwise, you can safely ignore this message.

---

## Verbose Mode

Use the `--verbose` flag for more detailed console output:

```bash
./fusion-server_darwin_arm64 --local --verbose
```

This is generally not necessary for audio testing.

---

## Verifying the REST Service

You can verify that the REST service is up and running using `curl`:

```bash
curl localhost:8080
```

Example output:

```json
{
  "build_time": "2025-10-29T20:19:45Z",
  "cluster_size": 1,
  "commit": "3826417d",
  "endpoints": [
    "GET /cluster/latency/network",
    "GET /cluster/latency/network/failures",
    "GET /cluster/latency/status",
    "GET /cluster/latency/sync",
    "GET /cluster/latency/sync/averages",
    "GET /cluster/members",
    "GET /cluster/ntp-skew",
    "GET /cluster/status",
    "GET /devices",
    "GET /devices/vip",
    "POST /devices/vip/{vip}",
    "POST /device/reload/vip",
    "PATCH /devices/{id}",
    "GET /endpoints",
    "GET /health",
    "GET /metadata",
    "GET /metrics",
    "POST /pava/messages",
    "GET /pava/messages/tags",
    "GET /pava/messages/{id}",
    "DELETE /pava/messages/{id}",
    "GET /pava/messages",
    "GET /pava/messages/{id}/stream",
    "GET /pava/schedule",
    "POST /pava/schedule",
    "GET /",
    "GET /sessions",
    "GET /sessions/{id}",
    "GET /snapshots",
    "POST /snapshots/{name}",
    "GET /snapshots/{name}",
    "DELETE /snapshots/{name}",
    "POST /snapshots/{name}/activate",
    "POST /snapshots/{name}/save",
    "GET /tasks/history",
    "DELETE /tasks/history",
    "GET /tasks",
    "POST /tasks",
    "GET /tasks/{id}",
    "POST /tasks/{id}",
    "DELETE /tasks/{id}",
    "POST /tasks/{id}/enable",
    "POST /tasks/{id}/enable",
    "GET /value",
    "POST /value",
    "PATCH /value",
    "DELETE /value",
    "GET /version",
    "POST /version",
    "PUT /version",
    "GET /ws"
  ],
  "name": "Fusion Server",
  "node_id": "fusion_ddv4p0c4pi3c_7h2j",
  "update_in_progress": false,
  "version": "1.0.0-proto.2"
}
```

The root (`/`) endpoint lists all available endpoints.

---

## Using `curl` or Bruno

You can interact with all REST endpoints using `curl`.  

If you prefer a graphical tool, a configuration file is available for the **[Bruno](https://www.usebruno.com/)** API client.  
Let me know if you want to use Bruno, and I can help you set it up.  
For most audio testing, `curl` will be sufficient.

---

## Uploading Audio Files

You can upload an audio file (e.g., a WAV file) with metadata using:

```bash
curl --request POST \
  --url http://localhost:8080/pava/messages \
  --header 'content-type: multipart/form-data' \
  --form display_name="Fire Drill" \
  --form binary=@/Users/gragan/Desktop/origin.wav \
  --form 'tags=Fire Drill' \
  --form tags=Emergencies
```

Example response:

```json
{
  "id": "01K8S28QM96R9RHRVVC8C83ABV",
  "orig_name": "origin.wav",
  "display_name": "Fire Drill",
  "filename": "01K8S28QM96R9RHRVVC8C83ABV.wav",
  "mime_type": "audio/wave",
  "uploaded": "2025-10-29T22:43:55.669358Z",
  "size_bytes": 480078,
  "tags": [
    "Fire Drill",
    "Emergencies"
  ]
}
```

Uploaded files are stored in:

```
/var/lib/fusion/audio
```

They are renamed with a UUID.

fusion-server only knows about files that are uploaded and added to an internal 
database. If a file is copied into the directory, fusion-server won't know about 
it. It is possible to modify the internal database if we needed to go around
using the REST API.

---

## Listing Uploaded Files

To list all uploaded audio files:

```bash
curl --request GET \
  --url http://localhost:8080/pava/messages
```

Example output:

```json
[
  {
    "id": "01K8S28QM96R9RHRVVC8C83ABV",
    "orig_name": "origin.wav",
    "display_name": "Fire Drill",
    "filename": "01K8S28QM96R9RHRVVC8C83ABV.wav",
    "mime_type": "audio/wave",
    "uploaded": "2025-10-29T22:43:55.669358Z",
    "size_bytes": 480078,
    "tags": [
      "Fire Drill",
      "Emergencies"
    ]
  }
]
```

## Triggering a message

Replace :id with the id of an uploaded file in this curl command to trigger the
playback notificaion.

```bash
curl --request PUT \
  --url http://localhost:8080/pava/messages/:id/trigger \
  --header 'content-type: application/json' \
  --data '{
  "zones": "all",
  "priority": 100
}'
```
You should see this console output from fusion-server:
```bash
2025/10/30 10:38:14 [fusion_ddvu8slksi28_an31] [INFO] Triggered message "01K8TYPMWW9HSK2QS5Y5W10ABS" at path "/var/lib/fusion/audio/01K8TYPMWW9HSK2QS5Y5W10ABS.wav" (priority 100)
```

## Monitoring triggered messages

Run the nc command in a terminal to monitor trigger message.
```
nc -u -l 7949
```

A triggered message will display this output:

```json
{
    "id": "01K8TYPMWW9HSK2QS5Y5W10ABS",
    "path": "/var/lib/fusion/audio/01K8TYPMWW9HSK2QS5Y5W10ABS.wav",
    "priority": 100,
    "zones": "all",
    "timestamp": 1761844571
}
```

Priority will be interpreted by the playback mechanism.

Zones aren't yet implimented. The thinking is that the value will be all or
a comma seperated string of zones. I am not sure how zones will work, as each
fusion-server instance is broadcasting only within the machine.

