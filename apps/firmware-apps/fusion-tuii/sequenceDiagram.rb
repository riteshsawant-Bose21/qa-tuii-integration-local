---
title: Initialization Sequence
---
sequenceDiagram
  autonumber
  participant TS as TUII Server
  participant TC as TUII Client

  rect rgb(235, 245, 255)
    Note over TS,TC: Handshake
    loop Initialization attempt (retry until success)
      loop ready retry until ACK
        TS->>TC: ready
        alt readyAck received
          TC-->>TS: readyAck
        else TIMEOUT
          Note over TS: Timeout waiting for readyAck
          TS->>TS: Retry ready
        end
      end
    end
  end

  rect rgb(236, 252, 241)
    Note over TS,TC: Config Sync
    Note over TS: Triggered by <br>touchui_device_config.json
    TS->>TC: identity (payload)
    Note over TC: Process event

    Note over TS: Triggered by <br>touchui_zone_config.json
    loop For all Zones
      TS->>TC: zone (payload)
      Note over TC: Process event
    end

    TS->>TC: zoneEnd (Zone count)
    alt SUCCESS
      TC-->>TS: zoneEndAck
      Note over TC: Start Normal Operation
    else FAILURE
      TC-->>TS: zoneEndNack
      Note over TS: Restart initialization from ready
    else TIMEOUT
      Note over TS: Timeout waiting for ACK/NACK
      TS->>TS: Restart initialization from ready
    end
  end

  rect rgb(255, 247, 237)
    Note over TS,TC: Runtime
    Note over TS: Triggered by <br>settings.audio.gainId
    TS->>TC: setGain (Gain value)
    Note over TC: Process event
    TS->>TC: setMute (Mute state)
    Note over TC: Process event

    Note over TS: Triggered by <br>settings.audio.zoneId
    TS->>TC: setSource (Active Source index)
    Note over TC: Process event

    Note over TC: Triggered by <br>User
    TC->>TS: setGain (norm, zone)
    alt Validation OK
      Note over TS: Convert norm to dB,<br>forward to Fusion
    else Validation Failure
      TS-->>TC: nack(setGain, zone)
    end

    Note over TC: Triggered by <br>User
    TC->>TS: setMute (state, zone)
    alt Validation OK
      Note over TS: Forward to Fusion
    else Validation Failure
      TS-->>TC: nack(setMute, zone)
    end

    Note over TC: Triggered by <br>User
    TC->>TS: setSource (index, zone)
    alt Validation OK
      Note over TS: Forward to Fusion
    else Validation Failure
      TS-->>TC: nack(setSource, zone)
    end
  end

  rect rgb(254, 242, 242)
    Note over TS,TC: Error Recovery
    alt NACK resend example (TC rejects TS command)
      TS->>TC: setGain (Gain value)
      TC-->>TS: nack(setGain, zone)
      TS->>TC: setGain (Gain value)
    end
    alt Unknown action from TC
      TC->>TS: unknownAction
      TS-->>TC: nack(unknownAction, -1)
    end
  end

