#!/usr/bin/env python3
import argparse
import json
import socket
import uuid
from typing import Any, Dict


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


def send_qa_invoke(
    host: str,
    port: int,
    api: str,
    params: Dict[str, Any],
    req_id: str,
    timeout_s: float,
) -> Dict[str, Any]:
    req = {
        "action": "qa_invoke",
        "id": req_id,
        "api": api,
        "params": params,
    }

    payload = json.dumps(req, separators=(",", ":")) + "\n"

    with socket.create_connection((host, port), timeout=timeout_s) as sock:
        sock.sendall(payload.encode("utf-8"))
        line = recv_line(sock, timeout_s=timeout_s)

    return json.loads(line)


def main() -> int:
    parser = argparse.ArgumentParser(description="QA TCP client for fusion-tuii")
    parser.add_argument("--host", required=True, help="DSP IP or hostname")
    parser.add_argument("--port", type=int, default=9000, help="QA TCP port (default: 9000)")
    parser.add_argument("--api", default="", help="QA API name to invoke on STM32")
    parser.add_argument(
        "--params",
        default="{}",
        help='JSON object string for params, e.g. \'{"zone":1}\'',
    )
    parser.add_argument(
        "--brightness-value",
        type=int,
        help='Shortcut: send setBrightness via qa_invoke with params {"value":N}',
    )
    parser.add_argument("--id", default="", help="Request id (auto-generated if empty)")
    parser.add_argument("--timeout", type=float, default=30.0, help="Socket timeout seconds")
    args = parser.parse_args()

    if args.brightness_value is not None:
        if args.brightness_value < 0:
            raise SystemExit("--brightness-value must be >= 0")
        api_name = "setBrightness"
        params_obj = {"value": args.brightness_value}
    else:
        if not args.api:
            raise SystemExit("Either provide --api, or use --brightness-value")
        api_name = args.api
        try:
            params_obj = json.loads(args.params)
        except json.JSONDecodeError as e:
            raise SystemExit(f"Invalid --params JSON: {e}")

        if not isinstance(params_obj, dict):
            raise SystemExit("--params must decode to a JSON object")

    req_id = args.id if args.id else f"req-{uuid.uuid4()}"

    print(f"[INFO] Connecting to {args.host}:{args.port}")
    print(f"[INFO] Sending qa_invoke id={req_id} api={api_name}")

    try:
        resp = send_qa_invoke(
            host=args.host,
            port=args.port,
            api=api_name,
            params=params_obj,
            req_id=req_id,
            timeout_s=args.timeout,
        )
    except Exception as e:
        raise SystemExit(f"[ERROR] Request failed: {e}")

    print("[INFO] Response:")
    print(json.dumps(resp, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())