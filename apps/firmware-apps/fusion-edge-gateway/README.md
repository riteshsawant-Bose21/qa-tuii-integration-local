# fusion-edge-gateway
This builds a client for Fusion devices to connect to a cloud(Xyte for now) and do analytics and monitoring.

1. Registers the device using hardware key and cloud id.
2. Saves the response in a file to use it to send telemetry.
3. Sends telemetry in a while loop with an interval.
4. Receives commands from cloud and performs it.