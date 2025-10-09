# profile_block.py Fusion-DSP Performance Profiler

## Overview

This tool profiles the performance of various DSP algorithms on Fusion by measuring their execution time under different configurations and creating linear regression models to predict computational cost.

## Requirements

- Python 3.x
- Required Python packages:
  - pandas
  - jinja2
  - scikit-learn
  - pickle
- Compiled `fusion_dsp` binary

## Installation

1. Create a venv
    ```bash
    python3 -m venv venv
    ```

2. Activate venv and install Python dependencies:
   ```bash
   source venv/bin/activate
   pip install pandas jinja2 scikit-learn
   ```

## Setup

### For Remote Execution (Fusion binary on Variscite board)

3. Network Setup
   -  Ensure board and host machine are on the same network
   - update board_ip in script (default: 192.168.1.7)
   - Copy test WAV files to board: `scp *.wav root@[board-ip]:/home/root/` 
   - Disable board services (run only once):
   ``` bash
      ssh root@[board-ip]
      systemctl disable fusion-system-monitor fusion-telemetry-core fusion-dsp fusion-server jackd
   ```
4. WAV files

These files can be found here: *Link* (INSERT LINK)

Have these in the root project directory for local testing, or copy them to the board you are testing with. 

#### `in.wav`
* Tone based music simulation with noise and amplitude jumps. Designed to trigger most algorithms, including heuristic-based implementations.

#### `in_ducker_2.wav`
* Real wide-range music track with speech sidechain

#### `in_feedback.wav`
* Feedback simulation with high frequency sounds and sweeps, designed to trigger the feedback_suppression algorithm.

### Running on host machine

5. Ensure `fusion_dsp` binary is compiled and located at `./build/fusion_dsp`

## Usage

### Choose platform

```bash
python3 profile_block.py --local
```

This will:
- Run profiling locally with host machine's compute


```bash
python3 profile_block.py --remote
# or leave blank (remote is default)
python3 profile_block.py
```

This will:
- Run profiling remotely on connected board and send results back to host machine.

### Checkpoints
Matrix Mixer and PEQ profile with checkpoints. Timing files will output in `profiling_results/{configname}_checkpoints/` and get accessed if profiling is interrupted then re-initialized.

- Checkpoint files are automatically deleted upon profiling completion
- If you interrupt the profiling process and change parameters for the current algorithm, you must delete the timing files in `profiling_results/{configname}_checkpoints/` including `processed_params.csv` to avoid mixed timings in results.
- There are no checkpoints for any other DSP algorithm.

### Profile All Algorithms
```bash
python3 profile_block.py
```

This will:
- Profile all configured algorithms
- Generate `results.pkl` (machine-readable model data) in `/profiling_results`
- Generate `results.txt` (human-readable performance formulas) in `/profiling_results`
- Generate `algorithm_regression_plots.png` (plotted graph of timings vs feature datapoints and regression line)

### Profile Specific Algorithm
```bash
python3 profile_block.py matrix_mixer --ip 192.168.1.6 --clock 1500.0
```

This will:
- Profile only the specified algorithm using provided ip and clock speed (remote only)
- `ip=192.168.1.5` and `clock=1500.0` are the default values. 
- Generate `results_matrix_mixer.pkl`, `results_matrix_mixer.txt` and `matrix_mixer_regression_plots.png` in `/profiling_results`

## Supported Algorithms

- **agc** - Automatic Gain Control
- **compressor** - Dynamic range compressor
- **ducker** - Ducking/sidechain processor
- **feedback_suppression** - Feedback elimination
- **gain** - Simple gain adjustment
- **gate** - Noise gate
- **graphic_eq** - Graphic equalizer
- **limiter** - Peak limiter
- **matrix_mixer** - Input/output routing matrix
- **peq** - Parametric equalizer
- **tone** - Tone control
- **wav_read** - WAV file reading
- **wav_write** - WAV file writing

## Output Format

Output will be in the `profiling_results/{config_name}/` directory, outputted formats are:

### Human-Readable (results.txt)
Example:
```
agc : T = 1523 + 47.2*channels
matrix_mixer : T = 987 + 22.1*num_inputs*num_outputs
peq : T = 890 + 23.7*bands*channels
```

Where:
- T = execution time in seconds
- First number = base overhead (intercept)
- Second number = per-unit cost (slope)

### Machine-Readable (results.pkl)
Python pickle file containing sklearn LinearRegression model objects for each algorithm.

## Configuration

Each algorithm configuration in the script can specify:

- **path**: Jinja2 template file for JSON generation
- **algorithm**: Algorithm name to profile
- **parameters**: Dictionary of parameter ranges to test
- **features**: Feature engineering functions
- **wav_input**: Input WAV file to use
- **csv_dump**: Save raw timing data to CSV
- **block**: Specific block name to profile (if its different from algorithm name)
- **format_string**: Custom output format for results

## How It Works

1. Generates JSON configuration files using Jinja2 templates
2. Tests multiple parameter combinations
3. Runs fusion_dsp with each configuration
4. Cleans up files before and after runs to free diskspace
4. Reads timing data from CSV output
5. Removes outliers (Keeps values in range 99.9 - 99.99% to measure the worse case)
6. Uses linear regression to model performance
7. Plots and saves models, formulas, and final audio output (`out.wav`)

## Special Cases

### Feedback Suppression
Feedback suppression runs on two separate threads: Main thread + Frequency Analysis thread.

This script takes into account both threads in plotting and regression formulas. Timings from the Frequency Analysis thread are parsed from running fusion-dsp in 'verbose' (`-v`) mode.

### PEQ & Matrix Mixer
Both PEQ and Matrix Mixer have multi-feature regression models. 
```bash
# PEQ
'features': {
    'bands': lambda x: x['bands'],              # Linear term
    'channels': lambda x: x['channels'],        # Linear term
    'bandchannels': lambda x: x['bands']*x['channels']  # Interaction term
}

# Matrix Mixer
'features': {
    'num_inputs': lambda x: x['num_inputs'],              # Linear term
    'num_outputs': lambda x: x['num_outputs'],        # Linear term
    'num_crosspoints': lambda x: x['num_inputs']*x['num_outputs']  # Interaction term
}
```
#### Generated Plots:
After successful profiling, three plots are automatically generated:

**Individual Feature Plot A**: Shows timing vs. first feature (e.g., bands) with the second feature held at various fixed values (e.g., channels = 1, 4, 8, 16). Each fixed value is represented by a different color.

**Individual Feature Plot B**: Shows timing vs. second feature (e.g., channels) with the first feature held at various fixed values (e.g., bands = 2, 4, 8). Each fixed value is represented by a different color.

**Interaction Feature Analysis**: Plots timing vs. the interaction term (e.g., bands × channels) with color-coded points indicating which individual feature dominates:

* Red: First feature is larger (e.g., bands > channels)
* Blue: Second feature is larger (e.g., channels > bands)
* Green: Features are equal (e.g., bands = channels)

This color-coding helps identify whether the relative magnitude of the interacting features affects performance characteristics, revealing optimization patterns in the component behavior. Specific details are also outputted in result files (e.g., `results_peq_remote.txt`) below the regression formula.

**Regression Formulas Per Combination**: Outputs the regression formulas for each combination of interaction terms (e.g., 4 bands x 3 channels)

### Wav Read & Wav Write
Plots will only include timing for 1 channel input, with no regression line.

## Troubleshooting

### "Parameter setting index out of range"
- Check template files for hardcoded parameter indices
- Check that parameter values match what the algorithm expects

### "No columns to parse from file"
- fusion_dsp crashed before writing timing data
- Check JSON syntax in generated tmp.json
- Check all required WAV input files exist

### KeyError for algorithm name
- Add 'block' specification to algorithm configuration
- Check that the block name matches what's in the timing CSV

## Operating Systems

In local mode, automatically detects the OS and sets appropriate library paths:
- Linux: Uses `LD_LIBRARY_PATH`
- macOS: Uses `DYLD_LIBRARY_PATH`