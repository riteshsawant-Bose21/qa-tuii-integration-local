#!/usr/bin/env python3


"""
Test FIR Hybrid Algorithm with Impulse Response

Workflow:
  1. Generates 3 impulse WAV files (start/middle/end frame positions) -> test/impulse_*.wav
  2. Loads or generates 1024-tap FIR coefficients -> from test/fir_test_coefficients.json or scipy
  3. Builds DSP config with all 3 test tasks -> config/test_fir_hybrid.json
  4. Runs fusion_dsp -> generates test_results/output_impulse_*.wav
  5. Validates impulse response vs expected coefficients -> reports PASS/FAIL

Note: The framework applies smoothed gain ramping on output terminals.
The gain starts at 0.0 and ramps to 1.0 using:
    g = 0.999*g + 0.001*target
This takes ~216 frames (6905 samples) to reach 99.9% of the target gain.
Therefore, we use WARMUP_FRAMES=220 to ensure the gain is fully settled
before the impulse arrives.
"""

import numpy as np
import wave
import json
import subprocess
from pathlib import Path

SAMPLE_RATE = 48000
FRAME_SIZE = 32
NUM_TAPS = 1024
DIRECT_TAPS = 64
CHANNELS = 1

NUM_FRAMES = 10 
WARMUP_FRAMES = 220  # Frames before impulse to allow gain ramp to settle (216+ needed)
TAIL_FRAMES = 50  # Extra frames after impulse to capture full filter response
IMPULSE_POSITIONS = {
    'start': WARMUP_FRAMES * FRAME_SIZE + 0,     # First sample of frame (after warmup)
    'middle': WARMUP_FRAMES * FRAME_SIZE + 15,   # Middle of frame
    'end': WARMUP_FRAMES * FRAME_SIZE + 31       # Last sample of frame
}

def create_impulse_wav(filename, impulse_position, num_frames=NUM_FRAMES):
    total_samples = (WARMUP_FRAMES + num_frames + TAIL_FRAMES) * FRAME_SIZE
    audio_data = np.zeros(total_samples, dtype=np.float32)
    audio_data[impulse_position] = 1.0
    
    audio_int16 = (audio_data * 32767).astype(np.int16)
    
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(CHANNELS)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        wav_file.writeframes(audio_int16.tobytes())
    
    print(f"Created {filename}: impulse at sample {impulse_position}")

def load_fir_coefficients(coeffs_file='test/fir_test_coefficients.json'):
    coeffs_path = Path(coeffs_file)
    if coeffs_path.exists():
        with open(coeffs_file, 'r') as f:
            data = json.load(f)
            # Expect 'coefficients' field
            if 'coefficients' in data:
                coeffs = np.array(data['coefficients'])
                print(f"Loaded {len(coeffs)} FIR coefficients from {coeffs_file}")
            else:
                print(f"Error: 'coefficients' field not found in {coeffs_file}")
                return None
            
            if len(coeffs) == NUM_TAPS:
                return coeffs
            else:
                print(f"Warning: Loaded {len(coeffs)} coeffs but need {NUM_TAPS}. Regenerating...")
    
    print(f"Generating {NUM_TAPS}-tap lowpass filter (cutoff=12kHz @ 48kHz)")
    try:
        from scipy import signal
        cutoff_normalized = 12000.0 / (SAMPLE_RATE / 2)
        coeffs = signal.firwin(NUM_TAPS, cutoff_normalized, window='hamming')
        print(f"Generated {len(coeffs)} FIR coefficients using scipy")
        return coeffs
    except ImportError:
        print("ERROR: scipy not available, cannot generate coefficients")
        return None

def read_wav_file(filename):
    with wave.open(filename, 'r') as wav_file:
        n_channels = wav_file.getnchannels()
        sample_width = wav_file.getsampwidth()
        framerate = wav_file.getframerate()
        n_frames = wav_file.getnframes()
        
        audio_bytes = wav_file.readframes(n_frames)
        
        if sample_width == 2:  # 16-bit
            audio_int16 = np.frombuffer(audio_bytes, dtype=np.int16)
            audio_float = audio_int16.astype(np.float32) / 32768.0
        elif sample_width == 4:  # 32-bit
            audio_int32 = np.frombuffer(audio_bytes, dtype=np.int32)
            audio_float = audio_int32.astype(np.float32) / 2147483648.0
        else:
            raise ValueError(f"Unsupported sample width: {sample_width}")
        
        return audio_float, framerate

def validate_impulse_response(output_file, expected_coeffs, impulse_position, tolerance=1e-3):
    print(f"\nValidating {output_file}...")
    
    output_path = Path(output_file)
    if not output_path.exists():
        print(f"ERROR: Output file not found: {output_file}")
        return False
    
    output_audio, sr = read_wav_file(output_file)
    
    print(f"  Output samples: {len(output_audio)}")
    print(f"  Impulse position: {impulse_position}")
    print(f"  Expected filter length: {len(expected_coeffs)}")
    
    non_zero_indices = np.where(np.abs(output_audio) > tolerance)[0]
    print(f"  Non-zero samples: {len(non_zero_indices)}")
    
    if len(non_zero_indices) == 0:
        print("  ERROR: No non-zero samples in output!")
        return False
    
    expected_start = impulse_position
    expected_end = impulse_position + len(expected_coeffs)
    
    print(f"  Expected response from sample {expected_start} to {expected_end}")
    
    actual_response = output_audio[expected_start:expected_end]
    
    if len(actual_response) < len(expected_coeffs):
        print(f"  ERROR: Output too short ({len(actual_response)} vs {len(expected_coeffs)})")
        return False
    
    actual_sum = np.sum(actual_response)
    expected_sum = np.sum(expected_coeffs)
    gain_ratio = actual_sum / expected_sum if expected_sum != 0 else 0
    print(f"  DC gain check: actual_sum={actual_sum:.6f}, expected_sum={expected_sum:.6f}, ratio={gain_ratio:.6f}")
    
    if gain_ratio < 0.995:
        print(f"  WARNING: Gain appears to still be ramping (ratio={gain_ratio:.4f} < 0.995)")
        print(f"           Consider increasing WARMUP_FRAMES for better accuracy")
    
    actual_response_scaled = actual_response
    
    max_error = np.max(np.abs(actual_response_scaled - expected_coeffs))
    rms_error = np.sqrt(np.mean((actual_response_scaled - expected_coeffs) ** 2))
    
    print(f"  Max error: {max_error:.6f}")
    print(f"  RMS error: {rms_error:.6f}")
    
    print(f"  First 5 expected: {expected_coeffs[:5]}")
    print(f"  First 5 actual: {actual_response_scaled[:5]}")
    
    if max_error > tolerance:
        print(f"  FAIL: Max error {max_error} exceeds tolerance {tolerance}")
        errors = np.abs(actual_response_scaled - expected_coeffs)
        largest_error_idx = np.argmax(errors)
        print(f"  Largest error at tap {largest_error_idx}: expected {expected_coeffs[largest_error_idx]:.6f}, got {actual_response_scaled[largest_error_idx]:.6f}")
        return False
    
    print(f"  PASS: Output matches expected FIR coefficients within tolerance")
    return True

def generate_test_config(coefficients, output_file):
    config = {
        "session": {
            "name": "fusion_dsp",
            "property_settings": [
                { "name": "frame_size", "value": FRAME_SIZE},
                { "name": "sample_rate", "value": SAMPLE_RATE }
            ]
        },
        "audio_tasks": []
    }
    
    # Generate 3 tasks for start, middle, end impulse positions (not using jinja since it's simpler here)
    for name, position in IMPULSE_POSITIONS.items():
        task = {
            "name": f"fir_hybrid_impulse_{name}",
            "property_settings": [
                { "name": "is_jack_client", "value": False },
                { "name": "frame_size", "value": FRAME_SIZE},
                { "name": "sample_rate", "value": SAMPLE_RATE }
            ],
            "blocks": [
                {
                    "name": "infile",
                    "algorithm": "wav_read",
                    "property_settings": [
                        { "name": "frame_size", "value": FRAME_SIZE},
                        { "name": "sample_rate", "value": SAMPLE_RATE },
                        { "name": "filename", "value": f"test/impulse_{name}.wav" }
                    ],
                    "terminal_channels": [
                        { "name": "out", "channels": CHANNELS }
                    ]
                },
                {
                    "name": f"fir_filter_{name}",
                    "algorithm": "fir_hybrid",
                    "property_settings": [
                        { "name": "channels", "value": CHANNELS },
                        { "name": "num_taps", "value": NUM_TAPS },
                        { "name": "direct_taps", "value": DIRECT_TAPS },
                        { "name": "frame_size", "value": FRAME_SIZE },
                        { "name": "sample_rate", "value": SAMPLE_RATE }
                    ]
                },
                {
                    "name": "outfile",
                    "algorithm": "wav_write",
                    "property_settings": [
                        { "name": "frame_size", "value": FRAME_SIZE },
                        { "name": "sample_rate", "value": SAMPLE_RATE },
                        { "name": "filename", "value": f"test_results/output_impulse_{name}.wav" }
                    ],
                    "terminal_channels": [
                        { "name": "in", "channels": CHANNELS }
                    ]
                }
            ],
            "block_connections": [
                {
                    "source_block": "infile",
                    "output_terminal": "out",
                    "output_channel": 1,
                    "destination_block": f"fir_filter_{name}",
                    "input_terminal": "in",
                    "input_channel": 1
                },
                {
                    "source_block": f"fir_filter_{name}",
                    "output_terminal": "out",
                    "output_channel": 1,
                    "destination_block": "outfile",
                    "input_terminal": "in",
                    "input_channel": 1
                }
            ]
        }
        config["audio_tasks"].append(task)
    
    config["parameter_settings"] = []
    coeffs_list = coefficients if isinstance(coefficients, list) else coefficients.tolist()
    
    for task_name in ["start", "middle", "end"]:
        for i, coeff in enumerate(coeffs_list):
            config["parameter_settings"].append({
                "target": f"fir_filter_{task_name}",
                "name": "coefficients",
                "index": [i + 1],  # 1-indexing
                "value": float(coeff)
            })
    
    # Write config file
    with open(output_file, 'w') as f:
        json.dump(config, f, indent=4)


def main():
    print("=" * 70)
    print("FIR Hybrid Impulse Response Test")
    print("=" * 70)
    
    test_dir = Path('test')
    test_dir.mkdir(exist_ok=True)
    
    results_dir = Path('test_results')
    results_dir.mkdir(exist_ok=True)
    
    print("\n[1] Generating impulse WAV files...")
    for name, position in IMPULSE_POSITIONS.items():
        filename = test_dir / f'impulse_{name}.wav'
        create_impulse_wav(str(filename), position)
    
    print("\n[2] Loading FIR coefficients...")
    fir_coeffs = load_fir_coefficients()
    if fir_coeffs is None:
        print("ERROR: Could not load or generate FIR coefficients")
        return False
    
    if len(fir_coeffs) != NUM_TAPS:
        print(f"ERROR: Expected exactly {NUM_TAPS} taps, got {len(fir_coeffs)}")
        print("Coefficient generation failed!")
        return False
    
    print(f"  Using {len(fir_coeffs)} FIR coefficients")
    print(f"  Coefficient sum: {np.sum(fir_coeffs):.6f}")
    print(f"  First 5 coeffs: {fir_coeffs[:5]}")
    print(f"  Last 5 coeffs: {fir_coeffs[-5:]}")
    
    print("\n[2.5] Generating test config with coefficients...")
    config_file = 'config/test_fir_hybrid.json'
    generate_test_config(fir_coeffs.tolist(), config_file)
    print(f"  Updated {config_file} with test coefficients")
    
    print("\n[3] Running the FIR Hybrid test...")
    
    try:
        result = subprocess.run(
            ['./build/fusion_dsp', '-c', config_file],
            capture_output=True,
            text=True,
            timeout=30
        )
        if result.returncode != 0:
            print(f"  ERROR: DSP failed with return code {result.returncode}")
            print(f"  stderr: {result.stderr}")
            return False
        print("  ✓ DSP processing complete")
    except subprocess.TimeoutExpired:
        print("  ERROR: DSP timed out after 30 seconds")
        return False
    except FileNotFoundError:
        print("  ERROR: ./build/fusion_dsp not found. Run './waf build' first.")
        return False
    
    print("\n[4] Validating results...")
    all_passed = True
    
    for name, position in IMPULSE_POSITIONS.items():
        output_file = results_dir / f'output_impulse_{name}.wav'
        if output_file.exists():
            passed = validate_impulse_response(str(output_file), fir_coeffs, position)
            all_passed = all_passed and passed
        else:
            print(f"\nSkipping validation for {name}: output file not found")
            print(f"  Run fusion_dsp first to generate output files")
    
    print("\n" + "=" * 70)
    if all_passed:
        print("✓ ALL TESTS PASSED")
        print("=" * 70)
        return True
    else:
        print("✗ SOME TESTS FAILED")
        print("=" * 70)
        return False

if __name__ == '__main__':
    success = main()
    exit(0 if success else 1)
