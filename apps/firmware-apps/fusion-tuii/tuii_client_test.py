#!/usr/bin/env python3
"""TUII client test harness for fusion-tuii (Windows-friendly).

Implements the same serial framing as fusion-tuii's SerialManager:
  SOF(4 LE) | CRC16(2 LE) | LEN(1) | PAYLOAD(LEN)
Where:
  - SOF on wire is bytes: D5 C5 B5 A5 (0xA5B5C5D5 little-endian)
  - CRC is CRC-16/CCITT-FALSE over [LEN byte, then PAYLOAD]
  - LEN is 1..255

Behavior:
  - Prints every received JSON payload from the fusion-tuii server.
  - Replies:
      ready    -> readyAck
            zoneEnd  -> zoneEndAck (or zoneEndNack with --zoneend-nack)
  - Optional: after init, send a small demo sequence of setGain/setMute/setSource.

Usage:
  python tuii_client_test.py COM7
  python tuii_client_test.py COM7 --demo

Requires:
  pip install pyserial
"""

from __future__ import annotations

import argparse
import json
import sys
import time
import threading
from dataclasses import dataclass

try:
    import serial  # pyserial
except ImportError as exc:  # pragma: no cover
    raise SystemExit(
        "Missing dependency: pyserial\n\n"
        "Install with: pip install pyserial\n"
    ) from exc


SOF_WIRE = b"\xD5\xC5\xB5\xA5"  # 0xA5B5C5D5 little-endian
HEADER_SIZE = 7
MAX_LEN = 255


def crc16_ccitt_false(data: bytes, crc: int = 0xFFFF) -> int:
    """CRC-16/CCITT-FALSE (poly=0x1021, init=0xFFFF, no reflection, xorout=0)."""
    for byte in data:
        crc ^= byte << 8
        for _ in range(8):
            if crc & 0x8000:
                crc = ((crc << 1) ^ 0x1021) & 0xFFFF
            else:
                crc = (crc << 1) & 0xFFFF
    return crc & 0xFFFF


@dataclass
class ParsedFrame:
    payload: bytes
    expected_crc: int
    computed_crc: int


class FrameParser:
    """Incremental parser for fusion-tuii framed serial packets."""

    def __init__(self) -> None:
        self._buf = bytearray()

    def feed(self, data: bytes) -> list[ParsedFrame]:
        if data:
            self._buf.extend(data)

        frames: list[ParsedFrame] = []

        while True:
            sof_index = self._buf.find(SOF_WIRE)
            if sof_index < 0:
                # Keep a small tail in case it contains a partial SOF.
                if len(self._buf) > 3:
                    del self._buf[:-3]
                break

            if sof_index > 0:
                del self._buf[:sof_index]

            if len(self._buf) < HEADER_SIZE:
                break

            expected_crc = int(self._buf[4]) | (int(self._buf[5]) << 8)
            length = int(self._buf[6])

            if length <= 0 or length > MAX_LEN:
                # Invalid length; drop one byte and resync.
                del self._buf[0:1]
                continue

            total = HEADER_SIZE + length
            if len(self._buf) < total:
                break

            payload = bytes(self._buf[HEADER_SIZE:total])
            computed_crc = crc16_ccitt_false(bytes([length]) + payload)

            if computed_crc != expected_crc:
                # CRC mismatch; drop one byte and resync.
                del self._buf[0:1]
                continue

            frames.append(ParsedFrame(payload=payload, expected_crc=expected_crc, computed_crc=computed_crc))
            del self._buf[:total]

        return frames


class TuiiClient:
    def __init__(
        self,
        port: str,
        baud: int = 115200,
        read_timeout_s: float = 0.05,
        zoneend_nack: bool = False,
        demo: bool = False,
        demo_zone: int = 0,
        demo_delay_s: float = 0.25,
    ) -> None:
        self._port = port
        self._baud = baud
        self._read_timeout_s = read_timeout_s

        self._zoneend_nack = zoneend_nack

        self._demo = demo
        self._demo_zone = demo_zone
        self._demo_delay_s = demo_delay_s

        self._ser: serial.Serial | None = None
        self._parser = FrameParser()

        self._init_lock = threading.Lock()
        self._zones_received = 0
        self._expected_zones: int | None = None
        self._demo_started = False

    def open(self) -> None:
        self._ser = serial.Serial(
            port=self._port,
            baudrate=self._baud,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            timeout=self._read_timeout_s,
        )

    def close(self) -> None:
        if self._ser is not None:
            try:
                self._ser.close()
            finally:
                self._ser = None

    def _send_frame(self, payload_bytes: bytes) -> None:
        if self._ser is None:
            raise RuntimeError("Serial port not open")

        if not payload_bytes:
            raise ValueError("Refusing to send empty payload")

        if len(payload_bytes) > MAX_LEN:
            raise ValueError(f"Payload too large: {len(payload_bytes)} > {MAX_LEN}")

        length = len(payload_bytes)
        crc = crc16_ccitt_false(bytes([length]) + payload_bytes)

        header = bytearray()
        header.extend(SOF_WIRE)
        header.append(crc & 0xFF)
        header.append((crc >> 8) & 0xFF)
        header.append(length & 0xFF)

        self._ser.write(bytes(header) + payload_bytes)

    def send_json(self, obj: dict) -> None:
        payload_str = json.dumps(obj, separators=(",", ":"))
        self._send_frame(payload_str.encode("utf-8"))
        self._log(f"TX {payload_str}")

    def _log(self, msg: str) -> None:
        ts = time.strftime("%H:%M:%S")
        print(f"[{ts}] {msg}", flush=True)

    def _handle_message(self, msg: dict, raw: str) -> None:
        action = msg.get("action")

        if action == "ready":
            with self._init_lock:
                self._zones_received = 0
                self._expected_zones = None
                self._demo_started = False
            self.send_json({"action": "readyAck"})
            return

        if action == "zone":
            with self._init_lock:
                self._zones_received += 1
            return

        if action == "zoneEnd":
            expected = None
            try:
                payload = msg.get("payload")
                if isinstance(payload, dict) and isinstance(payload.get("zones"), int):
                    expected = int(payload["zones"])
            except Exception:
                expected = None

            with self._init_lock:
                self._expected_zones = expected
                zones_received = self._zones_received

            self._log(f"Init summary: zones_received={zones_received}, zoneEnd.payload.zones={expected}")

            if self._zoneend_nack:
                self._log("Replying zoneEndNack (forced via --zoneend-nack)")
                self.send_json({"action": "zoneEndNack"})
                return

            self.send_json({"action": "zoneEndAck"})

            if self._demo and not self._demo_started:
                self._demo_started = True
                threading.Thread(target=self._run_demo_sequence, daemon=True).start()
            return

        # No other actions require immediate client responses for the init flow.
        if action in ("identity", "setGain", "setMute", "setSource", "nack", "readyAck", "zoneEndAck", "zoneEndNack"):
            return

        # Unknown action: keep quiet (server side will nack unknown actions it receives).
        _ = raw

    def _run_demo_sequence(self) -> None:
        # Give fusion-tuii a moment after init.
        time.sleep(self._demo_delay_s)

        zone = int(self._demo_zone)

        # These exercise fusion-tuii's client->server forwarding path.
        try:
            self.send_json({"action": "setGain", "payload": {"zone": zone, "norm": 25.0}})
            time.sleep(self._demo_delay_s)

            self.send_json({"action": "setMute", "payload": {"zone": zone, "state": True}})
            time.sleep(self._demo_delay_s)

            self.send_json({"action": "setSource", "payload": {"zone": zone, "index": 0}})
            time.sleep(self._demo_delay_s)

            self.send_json({"action": "setMute", "payload": {"zone": zone, "state": False}})
            time.sleep(self._demo_delay_s)

            self.send_json({"action": "setGain", "payload": {"zone": zone, "norm": 75.0}})
        except Exception as e:
            self._log(f"Demo sequence error: {e}")

    def run_forever(self) -> int:
        if self._ser is None:
            self.open()

        assert self._ser is not None
        self._log(f"Opened {self._port} @ {self._baud} baud")
        self._log("Waiting for frames... (Ctrl+C to exit)")

        try:
            while True:
                chunk = self._ser.read(4096)
                frames = self._parser.feed(chunk)

                for frame in frames:
                    raw = frame.payload.decode("utf-8", errors="replace")
                    self._log(f"RX {raw}")

                    try:
                        msg = json.loads(raw)
                    except json.JSONDecodeError as e:
                        self._log(f"RX JSON parse error: {e}")
                        continue

                    if not isinstance(msg, dict):
                        continue

                    self._handle_message(msg, raw)

        except KeyboardInterrupt:
            self._log("Exiting...")
            return 0
        finally:
            self.close()


def _parse_args(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(description="TUII client test harness for fusion-tuii")
    p.add_argument("port", help="COM port (e.g., COM7)")
    p.add_argument("--baud", type=int, default=115200, help="Baud rate (default: 115200)")
    p.add_argument(
        "--zoneend-nack",
        action="store_true",
        help="Reply to zoneEnd with zoneEndNack (exercise fusion-tuii init retry)",
    )
    p.add_argument("--demo", action="store_true", help="Send a small setGain/setMute/setSource sequence after init")
    p.add_argument("--demo-zone", type=int, default=0, help="Zone index for demo commands (default: 0)")
    p.add_argument("--demo-delay", type=float, default=0.25, help="Delay between demo commands in seconds")
    p.add_argument("--timeout", type=float, default=0.05, help="Serial read timeout in seconds")
    return p.parse_args(argv)


def main(argv: list[str]) -> int:
    args = _parse_args(argv)

    client = TuiiClient(
        port=args.port,
        baud=args.baud,
        read_timeout_s=args.timeout,
        zoneend_nack=bool(args.zoneend_nack),
        demo=bool(args.demo),
        demo_zone=int(args.demo_zone),
        demo_delay_s=float(args.demo_delay),
    )

    return client.run_forever()


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
