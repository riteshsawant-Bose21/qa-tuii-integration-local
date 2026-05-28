#!/usr/bin/env python3
import argparse
import json
import socket
import uuid
from typing import Any, Dict, List


def recv_line(sock: socket.socket, timeout_s: float) -> str:
    sock.settimeout(timeout_s)
    chunks = []
    while True:
        b = sock.recv(1)
        if not b:
            raise ConnectionError("Socket closed before newline")
        if b == b"\n":
            return b"".join(chunks).decode("utf-8")
        chunks.append(b)


def send_json_request(host: str, port: int, req: Dict[str, Any], timeout_s: float) -> Dict[str, Any]:
    payload = json.dumps(req, separators=(",", ":")) + "\n"
    with socket.create_connection((host, port), timeout=timeout_s) as sock:
        sock.sendall(payload.encode("utf-8"))
        line = recv_line(sock, timeout_s=timeout_s)
    return json.loads(line)


def parse_bool_str(value: str) -> bool:
    v = value.strip().lower()
    if v in ("true", "1", "yes", "y"):
        return True
    if v in ("false", "0", "no", "n"):
        return False
    raise argparse.ArgumentTypeError("Expected true/false")


def parse_sources(value: str) -> List[str]:
    try:
        arr = json.loads(value)
    except json.JSONDecodeError as e:
        raise argparse.ArgumentTypeError(f"Invalid --sources JSON: {e}") from e
    if not isinstance(arr, list) or not all(isinstance(x, str) for x in arr):
        raise argparse.ArgumentTypeError("--sources must be a JSON array of strings")
    return arr


def build_zone_payload(
    index: int,
    name: str,
    audio_mode: str,
    def_gain: int,
    def_mute: bool,
    sources: List[str],
) -> Dict[str, Any]:
    return {
        "Index": index,
        "Name": name,
        "AudioMode": audio_mode,
        "Gain": {
            "DefGain": def_gain,
            "DefMute": def_mute,
        },
        "sources/mixPresets": sources,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="QA TCP client for fusion-tuii (zone command test)")
    parser.add_argument("--host", required=True, help="DSP IP or hostname")
    parser.add_argument("--port", type=int, default=9000, help="QA TCP port (default: 9000)")
    parser.add_argument("--timeout", type=float, default=30.0, help="Socket timeout seconds")
    parser.add_argument("--id", default="", help="Request id (auto-generated if empty)")
    parser.add_argument(
        "--as-qa-invoke",
        action="store_true",
        help="Wrap zone payload as qa_invoke (api=zone, params=<payload>)",
    )

    parser.add_argument("--index", type=int, default=0, help="Zone Index (default: 0)")
    parser.add_argument("--name", default="Living Room", help='Zone Name (default: "Living Room")')
    parser.add_argument("--audio-mode", default="Stereo/mono", help='AudioMode (default: "Stereo/mono")')
    parser.add_argument("--def-gain", type=int, default=50, help="Gain.DefGain (default: 50)")
    parser.add_argument("--def-mute", type=parse_bool_str, default=False, help="Gain.DefMute true/false (default: false)")
    parser.add_argument(
        "--sources",
        type=parse_sources,
        default=["HDMI 1", "HDMI 2", "Bluetooth"],
        help='JSON array string for sources/mixPresets (default: ["HDMI 1","HDMI 2","Bluetooth"])',
    )

    args = parser.parse_args()

    zone_payload = build_zone_payload(
        index=args.index,
        name=args.name,
        audio_mode=args.audio_mode,
        def_gain=args.def_gain,
        def_mute=args.def_mute,
        sources=args.sources,
    )

    req_id = args.id if args.id else f"req-{uuid.uuid4()}"

    if args.as_qa_invoke:
        req = {
            "action": "qa_invoke",
            "id": req_id,
            "api": "zone",
            "params": zone_payload,
        }
        print(f"[INFO] Sending qa_invoke id={req_id} api=zone")
    else:
        req = {
            "action": "zone",
            "payload": zone_payload,
        }
        print("[INFO] Sending raw zone action")

    print(f"[INFO] Connecting to {args.host}:{args.port}")
    print("[INFO] Request:")
    print(json.dumps(req, indent=2))

    try:
        resp = send_json_request(
            host=args.host,
            port=args.port,
            req=req,
            timeout_s=args.timeout,
        )
    except Exception as e:
        raise SystemExit(f"[ERROR] Request failed: {e}")

    print("[INFO] Response:")
    print(json.dumps(resp, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())