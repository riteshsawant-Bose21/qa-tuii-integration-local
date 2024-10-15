import argparse
import json
import zmq

def main(host, port):
    context = zmq.Context()
    socket = context.socket(zmq.SUB)
    socket.connect(f"tcp://{host}:{port}")
    socket.setsockopt_string(zmq.SUBSCRIBE, "fusion-server")

    print(f"Connected to fusion-server socket at tcp://{host}:{port}")
    print("Waiting for messages... (CTRL+C to exit)")

    try:
        while True:
            topic = socket.recv_string()
            message = socket.recv_json()
            #print(f"\nReceived message: {topic}")
            #print(f"Content: {json.dumps(message, indent=2)}")
            
            if message.get("key") == "volume" and isinstance(message.get("value"), (int, float)):
                print(f"Volume: {message['value']:.4f}")                
    except KeyboardInterrupt:
        print("\nSubscriber stopped.")
    finally:
        socket.close()
        context.term()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Message Subscriber for Fusion Server")
    parser.add_argument("--host", default="localhost", help="Message publisher host")
    parser.add_argument("--port", default="5555", help="Message publisher port")
    args = parser.parse_args()

    main(args.host, args.port)

