"""
ZMQ WebSocket Telemetry Subscriber
==================================
A Python client to subscribe to ZeroMQ telemetry streams over WebSockets (ws://).
Ideal for validating network device streams alongside Flutter/Dart applications.

TROUBLESHOOTING & ENVIRONMENT SETUP:
------------------------------------
Standard PyZMQ installations (pre-compiled wheels) do not support the 'ws://' 
protocol because WebSocket transport is currently classified as a "Draft API" 
in the libzmq core. 

If you receive a "Protocol not supported" error, you must compile pyzmq from 
source with draft features enabled.

Run these exact commands in your terminal/virtual environment:

0. (Recommended) Create and activate a virtual environment:
    $ python3 -m venv .venv
    $ source .venv/bin/activate

1. Install pyzmq first (if needed):
    $ pip install --upgrade pip
    $ pip install pyzmq

2. Uninstall the default pre-compiled wheel:
   $ pip uninstall -y pyzmq
   
3. Ensure CMake is installed (required for C++ compilation):
   $ pip install cmake
   
4. Recompile pyzmq with Draft APIs explicitly enabled:
   $ export ZMQ_PREFIX=bundled
   $ export ZMQ_DRAFT_API=1
   $ pip install --no-binary=pyzmq pyzmq

Run with default IP:
    $ python3 zmq_subscriber.py

Run with a custom IP:
    $ python3 zmq_subscriber.py 10.1.123.202
"""

import zmq
import json
import sys

def run_subscriber(ip_address="10.1.123.202"):
    endpoints = [
        f"ws://{ip_address}:5678"
    ]

    # Initialize ZMQ context and socket
    context = zmq.Context()
    subscriber_socket = context.socket(zmq.SUB)

    # CRITICAL FIX: Always subscribe *before* connecting to avoid Slow Joiner Syndrome
    print("Setting subscription filter...")
    subscriber_socket.setsockopt_string(zmq.SUBSCRIBE, "")

    # Connect to each endpoint
    for url in endpoints:
        try:
            subscriber_socket.connect(url)
            print(f"ZMQ Subscriber Connected to {url}!!!")
        except zmq.ZMQError as e:
            print(f"Failed to connect to {url}: {e}")

    print("Waiting for JSON data... (Press Ctrl+C to stop)\n")

    try:
        # Continuous loop matching Dart's 'await for (final ZFrame frame in subscriberSocket!.frames)'
        while True:
            # Receive a single frame 
            frame = subscriber_socket.recv()
            
            try:
                # Decode UTF-8 and parse JSON just like the Flutter code
                decoded_str = frame.decode('utf-8', errors='replace')
                json_data = json.loads(decoded_str)
                print(f"New data received: {json.dumps(json_data, indent=2)}")
                
            except json.JSONDecodeError:
                # Fallback if the payload isn't strictly JSON
                print(f"Received raw data: {decoded_str}")
                
    except KeyboardInterrupt:
        print("\nKeyboard interrupt detected. Shutting down subscriber...")
    finally:
        # Clean up resources
        subscriber_socket.close()
        context.term()

if __name__ == "__main__":
    ip_address = sys.argv[1] if len(sys.argv) > 1 else "10.1.123.202"
    run_subscriber(ip_address)