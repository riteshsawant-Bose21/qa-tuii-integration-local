#!/usr/bin/env python3
"""
Convert Speakers.xml (old format) to speakers.json (new format).

Usage:
    python convert_speakers.py [input.xml] [output.json]

Defaults to Speakers.xml -> speakers.json in the current directory.
"""

import xml.etree.ElementTree as ET
import xml.parsers.expat as expat
import json
import math
import sys
import argparse
from pathlib import Path


# ── Helpers ───────────────────────────────────────────────────────────────────

def bandwidth_to_q(bw: float) -> float:
    """Convert bandwidth (octaves) to Q: Q = 1 / (2 * sinh(ln(2)/2 * bw))."""
    return 1.0 / (2.0 * math.sinh((math.log(2) / 2.0) * bw))


def parse_filter_type(filter_type: str, desc: str, line: int):
    """
    Parse a filterType attribute like "BW(24)" or "LR(48)".
    Returns (type_string, order).
    Warns to stdout for unrecognised prefixes.
    """
    if filter_type.startswith("BW"):
        try:
            slope = int(filter_type[3:-1])   # "BW(24)" -> 24
            order = slope // 6
            return "butterworth", order
        except (ValueError, IndexError):
            print(f"WARNING: Could not parse filterType '{filter_type}' "
                  f"for speaker '{desc}' at line {line}")
            return "butterworth", 4
    elif filter_type.startswith("LR"):
        try:
            slope = int(filter_type[3:-1])   # "LR(48)" -> 48
            order = slope // 6
            return "linkwitz_riley", order
        except (ValueError, IndexError):
            print(f"WARNING: Could not parse filterType '{filter_type}' "
                  f"for speaker '{desc}' at line {line}")
            return "linkwitz_riley", 4
    else:
        print(f"WARNING: Unexpected filterType '{filter_type}' "
              f"for speaker '{desc}' at line {line}")
        return filter_type, 4


def build_lineno_map(xml_path: str) -> list:
    """
    Two-pass approach: use expat to record the source line of every element
    start tag in document order, then match that list to ET's iteration order.
    Returns a list of ints (one per element in document order).
    """
    lines = []

    def start_handler(name, attrs):
        lines.append(p.CurrentLineNumber)

    p = expat.ParserCreate()
    p.StartElementHandler = start_handler
    with open(xml_path, "rb") as f:
        p.ParseFile(f)
    return lines


# ── Core conversion ───────────────────────────────────────────────────────────

def convert_speaker(speaker_elem, lineno_map: dict) -> dict | None:
    """Convert a single <Speaker> element to a composite_algorithm dict."""

    if speaker_elem.get("type") != "0":
        return None

    def ln(elem):
        return lineno_map.get(id(elem), "?")

    desc_elem    = speaker_elem.find("Description")
    eq_name_elem = speaker_elem.find("EQName")
    eq_name = eq_name_elem.text.strip() if eq_name_elem is not None else ""
    desc    = desc_elem.text.strip()    if desc_elem.text    is not None else eq_name

    # Name: lowercase, spaces/hyphens -> underscore, prefixed
    safe = eq_name.lower().replace(" ", "_").replace("-", "_")
    name = "loudspeaker_processor_" + safe

    parameter_settings = []
    has_excursion      = False
    excursion_bands    = 0
    peak_threshold_volts = 0
    rms_threshold_volts  = 0

    # ── Band-pass ─────────────────────────────────────────────────────────────
    max_hpf_order = 0
    max_lpf_order = 0
    bp = speaker_elem.find("Band-pass")
    if bp is not None:
        hp = bp.find("HighPass")
        if hp is not None and hp.get("bypass", "False").lower() != "true":
            freq = float(hp.get("freq", 20.0))
            ftype, order = parse_filter_type(hp.get("filterType", "BW(24)"), desc, ln(hp))
            max_hpf_order = order
            parameter_settings += [
                {"target": "hpf_lpf", "name": "hpf_freq",  "value": freq},
                {"target": "hpf_lpf", "name": "hpf_order", "value": order},
                {"target": "hpf_lpf", "name": "hpf_type",  "value": ftype},
            ]

        lp = bp.find("LowPass")
        if lp is not None and lp.get("bypass", "False").lower() != "true":
            freq = float(lp.get("freq", 20000.0))
            ftype, order = parse_filter_type(lp.get("filterType", "BW(24)"), desc, ln(lp))
            max_lpf_order = order
            parameter_settings += [
                {"target": "hpf_lpf", "name": "lpf_freq",  "value": freq},
                {"target": "hpf_lpf", "name": "lpf_order", "value": order},
                {"target": "hpf_lpf", "name": "lpf_type",  "value": ftype},
            ]

    # ── PEQ ───────────────────────────────────────────────────────────────────
    peq_elem = speaker_elem.find("PEQ")
    num_bands = 0
    if peq_elem is not None:
        using_bw   = peq_elem.get("UsingBandwidth", "False").lower() == "true"
        eq_gain    = float(peq_elem.get("EQGain", "0.0"))
        eq_polarity = peq_elem.get("EQPolarity", "False").lower() == "true"

        if eq_gain != 0.0:
            parameter_settings.append({
                "target": "peq",
                "name":   "out_gain",
                "index":  [1],
                "value":  eq_gain,
            })
        if eq_polarity:
            parameter_settings.append({
                "target": "hpf_lpf",
                "name":   "invert",
                "value":  True,
            })

        type_map = {"PEQ": "peq", "HighShelf": "high_shelf", "LowShelf": "low_shelf"}

        active_bands = [b for b in peq_elem.findall("Band")
                        if b.get("bypass", "False").lower() != "true"]
        num_bands = len(active_bands)
        if num_bands == 0:
            print(f"WARNING: PEQ has 0 active bands for speaker '{desc}'")

        out_idx = 1
        for band in active_bands:
            freq  = float(band.get("freq", 1000.0))
            gain  = float(band.get("gain", 0.0))
            btype = band.get("type", "PEQ")

            parameter_settings.append({"target": "peq", "name": "frequency",
                                        "index": [out_idx], "value": freq})
            parameter_settings.append({"target": "peq", "name": "gain",
                                        "index": [out_idx], "value": gain})

            if btype == "PEQ":
                raw_width = float(band.get("width", 1.0))
                q = bandwidth_to_q(raw_width) if using_bw else raw_width
                parameter_settings.append({"target": "peq", "name": "q",
                                            "index": [out_idx], "value": round(q, 6)})
            elif btype in ("HighShelf", "LowShelf"):
                parameter_settings.append({"target": "peq", "name": "type",
                                            "index": [out_idx], "value": type_map[btype]})
            else:
                print(f"WARNING: Unknown PEQ band type '{btype}' "
                      f"for speaker '{desc}' at line {ln(band)}")

            out_idx += 1

    # ── Delay ─────────────────────────────────────────────────────────────────
    alignment_delay = 0
    delay_elem = speaker_elem.find("Delay")
    if delay_elem is not None:
        ad = delay_elem.get("alignmentDelay", "0")
        if ad != "0":
            alignment_delay = int(ad)

    # ── Limiter ───────────────────────────────────────────────────────────────
    lim = speaker_elem.find("Limiter")
    if lim is not None:
        peak_threshold_volts = float(lim.get("peakThreshold", 0))
        rms_threshold_volts  = float(lim.get("rmsThreshold", 0))

        expected = {
            "peakAttack":  ("peak_attack",  1.5),
            "peakRelease": ("peak_release", 100.0),
            "rmsAttack":   ("rms_attack",   1000.0),
            "rmsRelease":  ("rms_release",  2000.0),
        }
        for attr, (param_name, exp_val) in expected.items():
            actual = lim.get(attr)
            if actual is not None and float(actual) != exp_val:
                parameter_settings.append({
                    "target": "limiter",
                    "name":   param_name,
                    "value":  float(actual),
                })

    # ── SmartBass ─────────────────────────────────────────────────────────────
    sb = speaker_elem.find("SmartBass")
    if sb is not None:
        t = sb.get("threshold", "103.0")
        if t != "103.0":
            print(f"WARNING: SmartBass threshold={t} (expected 103.0) "
                  f"for speaker '{desc}' at line {ln(sb)}")

    # ── DynamicEQ ─────────────────────────────────────────────────────────────
    deq = speaker_elem.find("DynamicEQ")
    if deq is not None:
        cal = deq.get("calibrateDefault", "-9.0")
        thr = deq.get("threshold", "75.0")
        if cal != "-9.0":
            print(f"WARNING: DynamicEQ calibrateDefault={cal} (expected -9.0) "
                  f"for speaker '{desc}' at line {ln(deq)}")
        if thr != "75.0":
            print(f"WARNING: DynamicEQ threshold={thr} (expected 75.0) "
                  f"for speaker '{desc}' at line {ln(deq)}")

    # ── ExcursionIIR ──────────────────────────────────────────────────────────
    exc_elems = speaker_elem.findall("ExcursionIIR")
    if exc_elems:
        has_excursion = True
        coeff_tags    = ["b0", "b1", "b2", "a1", "a2"]

        def is_active(e):
            for tag in ["b1", "b2", "a1", "a2"]:
                c = e.find(tag)
                if c is not None and float(c.text.strip()) != 0.0:
                    return True
            return False

        excursion_bands = sum(1 for e in exc_elems if is_active(e))
        if excursion_bands != 4:
            print(f"WARNING: ExcursionIIR has {excursion_bands} active bands "
                  f"(expected 4) for speaker '{desc}'")

        for bi, exc in enumerate(exc_elems, start=1):
            for ci, tag in enumerate(coeff_tags, start=1):
                child = exc.find(tag)
                val   = float(child.text.strip()) if child is not None else 0.0
                parameter_settings.append({
                    "target": "excursion_filter",
                    "name":   "coefficients",
                    "index":  [bi, ci],
                    "value":  val,
                })

    if alignment_delay:
        parameter_settings.append({
            "target": "hpf_lpf",
            "name":   "alignment_delay",
            "value":  alignment_delay,
        })

    # ── Build blocks ──────────────────────────────────────────────────────────
    def prop(n, v):
        return {"name": n, "value": v}

    def block(bname, algo, extra_props):
        return {
            "name": bname,
            "algorithm": algo,
            "property_settings": [
                prop("sample_rate", "$sample_rate"),
                prop("frame_size",  "$frame_size"),
            ] + extra_props,
        }

    hpf_lpf_extra = [
        prop("channels",      1),
        prop("max_hpf_order", max_hpf_order),
        prop("max_lpf_order", max_lpf_order),
    ]
    if alignment_delay:
        hpf_lpf_extra.append(prop("max_alignment_delay", alignment_delay))

    blocks = [block("hpf_lpf", "crossover", hpf_lpf_extra)]
    if num_bands > 0:
        blocks.append(block("peq", "peq", [prop("bands", num_bands), prop("channels", 1)]))
    if has_excursion:
        blocks.append(block("excursion_filter", "iir_filter",
                            [prop("bands", excursion_bands), prop("channels", 1)]))
    blocks.append(block("limiter", "limiter",
                        [prop("max_delay", 480), prop("channels", 1)]))
    blocks.append(block("delay",   "delay",
                        [prop("max_delay", 960), prop("channels", 1)]))

    # ── Build block_connections ───────────────────────────────────────────────
    def conn(sb, ot, och, db, it, ich):
        return {"source_block": sb, "output_terminal": ot, "output_channel": och,
                "destination_block": db, "input_terminal": it, "input_channel": ich}

    # The block upstream of the limiter's "in" and excursion/peak_in inputs
    # is "peq" when bands > 0, otherwise "hpf_lpf".
    pre_lim = "peq" if num_bands > 0 else "hpf_lpf"

    bconns = [conn("$in", "$in", 1, "hpf_lpf", "in", 1)]
    if num_bands > 0:
        bconns.append(conn("hpf_lpf", "out", 1, "peq", "in", 1))
    if has_excursion:
        bconns += [
            conn(pre_lim,            "out", 1, "limiter",          "in",      1),
            conn(pre_lim,            "out", 1, "excursion_filter",  "in",      1),
            conn("excursion_filter", "out", 1, "limiter",           "peak_in", 1),
        ]
    else:
        bconns += [
            conn(pre_lim, "out", 1, "limiter", "in",      1),
            conn(pre_lim, "out", 1, "limiter", "peak_in", 1),
        ]
    bconns += [
        conn("limiter", "out", 1, "delay", "in",  1),
        conn("delay",   "out", 1, "$out",  "out", 1),
    ]

    # ── Assemble ──────────────────────────────────────────────────────────────
    return {
        "name":        name,
        "description": desc,
        "is_opaque":   True,
        "loudspeaker_properties": {
            "peak_threshold_volts": peak_threshold_volts,
            "rms_threshold_volts":  rms_threshold_volts,
        },
        "terminals": [
            {"name": "in",  "signal_type": "audio", "direction": "input",  "channels": 1},
            {"name": "out", "signal_type": "audio", "direction": "output", "channels": 1},
        ],
        "parameters": [
            {"name": "peak_threshold", "value_type": "float",
             "default_value": 0.0, "minimum_value": -40.0, "maximum_value": 0.0},
            {"name": "rms_threshold",  "value_type": "float",
             "default_value": 0.0, "minimum_value": -40.0, "maximum_value": 0.0},
            {"name": "delay", "value_type": "integer", "dimensions": [1],
             "default_value": 0, "minimum_value": 0, "maximum_value": 960},
        ],
        "telemetry": [
            {"name": "out_meter", "dimensions": [1], "value_type": "float",
             "default_value": -60.0, "minimum_value": -60.0, "maximum_value": 24.0,
             "telemetry_type": "meter", "period_type": "HI"},
        ],
        "implementation": {
            "blocks":             blocks,
            "block_connections":  bconns,
            "parameter_settings": parameter_settings,
            "parameter_map": [
                {"composite_parameter": "peak_threshold",
                 "block_name": "limiter", "block_parameter": "peak_threshold"},
                {"composite_parameter": "rms_threshold",
                 "block_name": "limiter", "block_parameter": "rms_threshold"},
                {"composite_parameter": "delay",
                 "block_name": "delay",   "block_parameter": "delay"},
            ],
            "telemetry_map": [
                {"composite_telemetry": "out_meter",
                 "block_name": "delay", "block_telemetry": "out_meter"},
            ],
        },
    }


# ── Entry point ───────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Convert Speakers.xml to speakers.json"
    )
    parser.add_argument("input",  nargs="?", default="Speakers.xml",
                        help="Input XML file  (default: Speakers.xml)")
    parser.add_argument("output", nargs="?", default="speakers.json",
                        help="Output JSON file (default: speakers.json)")
    args = parser.parse_args()

    xml_path  = Path(args.input)
    json_path = Path(args.output)

    if not xml_path.exists():
        print(f"ERROR: Input file '{xml_path}' not found.", file=sys.stderr)
        sys.exit(1)

    # Build expat line-number list (document order)
    expat_lines = build_lineno_map(str(xml_path))

    try:
        tree = ET.parse(str(xml_path))
    except ET.ParseError as e:
        print(f"ERROR: Failed to parse XML: {e}", file=sys.stderr)
        sys.exit(1)

    root = tree.getroot()

    # Map element id() -> line number
    lineno_map = {id(elem): expat_lines[idx]
                  for idx, elem in enumerate(root.iter())
                  if idx < len(expat_lines)}

    composite_algorithms = []
    total = converted = 0

    for speaker in root.findall("Speaker"):
        total += 1
        algo = convert_speaker(speaker, lineno_map)
        if algo is not None:
            composite_algorithms.append(algo)
            converted += 1

    output = {"composite_algorithms": composite_algorithms}
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(output, f, indent=4)

    # ── Summary stats ─────────────────────────────────────────────────────────
    def block_prop(algo, block_name, prop_name):
        """Return the value of a property_setting for a named block, or None."""
        for blk in algo["implementation"]["blocks"]:
            if blk["name"] == block_name:
                for ps in blk["property_settings"]:
                    if ps["name"] == prop_name:
                        return ps["value"]
        return None

    def param_setting_sum(algo, target, names):
        """Sum all parameter_settings values for a target whose name is in names."""
        return sum(
            ps["value"]
            for ps in algo["implementation"]["parameter_settings"]
            if ps["target"] == target and ps["name"] in names
        )

    def mean(values):
        return sum(values) / len(values) if values else float("nan")

    peq_bands     = [block_prop(a, "peq",              "bands") for a in composite_algorithms]
    exc_bands     = [block_prop(a, "excursion_filter", "bands") for a in composite_algorithms]
    filter_orders = [param_setting_sum(a, "hpf_lpf", {"hpf_order", "lpf_order"})
                     for a in composite_algorithms]

    peq_bands_present = [v for v in peq_bands if v is not None]
    exc_bands_present = [v for v in exc_bands if v is not None]

    sep = "─" * 52
    print("\n" + sep)
    print("  Conversion summary")
    print(sep)
    print(f"  Total speakers in file   : {total}")
    print(f"  Converted (type=0)       : {converted}")
    print(f"  Mean PEQ bands           : {mean(peq_bands_present):.2f}"
          f"  ({len(peq_bands_present)} of {converted} speakers have PEQ)")
    print(f"  Mean excursion bands     : {mean(exc_bands_present):.2f}"
          f"  ({len(exc_bands_present)} of {converted} speakers have excursion filter)")
    print(f"  Mean HPF+LPF order total : {mean(filter_orders):.2f}")
    print(sep)
    print(f"  Output written to '{json_path}'")


if __name__ == "__main__":
    main()
