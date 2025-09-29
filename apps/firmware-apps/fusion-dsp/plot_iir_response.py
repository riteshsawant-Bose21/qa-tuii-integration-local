#!/usr/bin/env python3
"""
IIR Filter Frequency Response Plotter
Saves each filter as a separate plot in an output folder.
"""

import numpy as np
import matplotlib.pyplot as plt
from scipy import signal
import os
from pathlib import Path

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# Output folder for plots
OUTPUT_FOLDER = "filter_plots"# Sample rate (Hz)
FS = 48000

# Plot settings
PLOT_SETTINGS = {
    'figsize': (12, 8),
    'dpi': 100,
    'freq_range': [10, FS/2],
    'mag_range': [-60, 20],
    'grid_alpha': 0.3,
    'linewidth': 2
}

FILTERS = [
        {
        'name': 'Linkwitz-Riley HPF 100Hz Order 4',
        'b': [[1, -2, 1], [1, -2, 1]],
        'a': [[1.0092989734624382, -1.9999143239041632, 0.9907867026333983],
              [1.0092989734624382, -1.9999143239041632, 0.9907867026333983]],
        'color': 'green',
        'linestyle': '-'
    },
    {
        'name': 'Linkwitz-Riley LPF 100Hz Order 4',
        'b': [[4.2838047918331032e-05, 8.5676095836662063e-05, 4.2838047918331032e-05],
              [4.2838047918331032e-05, 8.5676095836662063e-05, 4.2838047918331032e-05]],
        'a': [[1.0092989734624382, -1.9999143239041632, 0.9907867026333983],
              [1.0092989734624382, -1.9999143239041632, 0.9907867026333983]],
        'color': 'green',
        'linestyle': '--'
    },
    
    # Butterworth filters at 100Hz
    {
        'name': 'Butterworth HPF 100Hz Order 4',
        'b': [[1, -2, 1], [1, -2, 1]],
        'a': [[1.0121365677586978, -1.9999143239041632, 0.98794910833713889],
              [1.0050522238521657, -1.9999143239041632, 0.99503345224367079]],
        'color': 'blue',
        'linestyle': '-'
    },
    {
        'name': 'Butterworth LPF 100Hz Order 4',
        'b': [[4.2838047918331032e-05, 8.5676095836662063e-05, 4.2838047918331032e-05],
              [4.2838047918331032e-05, 8.5676095836662063e-05, 4.2838047918331032e-05]],
        'a': [[1.0121365677586978, -1.9999143239041632, 0.98794910833713889],
              [1.0050522238521657, -1.9999143239041632, 0.99503345224367079]],
        'color': 'blue',
        'linestyle': '--'
    },
    
    # Bessel filters at 100Hz
    {
        'name': 'Bessel HPF 100Hz Order 4',
        'b': [[1, -2, 1], [1, -2, 1]],
        'a': [[1.0134844992500944, -1.9999015511849221, 0.98661394956498349],
              [1.0078099226107766, -1.9999217114694747, 0.99226836591974854]],
        'color': 'red',
        'linestyle': '-'
    },
    {
        'name': 'Bessel LPF 100Hz Order 4',
        'b': [[3.7280252647040057e-05, 7.4560505294080114e-05, 3.7280252647040057e-05],
              [4.6880388152464704e-05, 9.3760776304929408e-05, 4.6880388152464704e-05]],
        'a': [[1.0117294666348973, -1.9999254394947059, 0.98834509387039682],
              [1.0085509351429112, -1.999906239223695, 0.9915428256333938]],
        'color': 'red',
        'linestyle': '--'
    },
    # PEQs
    {
        'name': 'PEQ_CS_100Hz_Q2.00_6dB',
        'b': [[1.0065724119406561, -1.9999143239039676, 0.99351326415537633]],
        'a': [[1.0033153771240333, -1.9999143239039676, 0.9967702989719992]],
        'color': 'blue',
        'linestyle': '-'
    },
    
    {
        'name': 'PEQ_CS_250Hz_Q1.41_-4dB',
        'b': [[1.0118405655982809, -1.9994644441046989, 0.98869499029702013]],
        'a': [[1.0186094103129328, -1.9994644441046989, 0.98192614558236835]],
        'color': 'blue',
        'linestyle': '--'
    },
    {
        'name': 'PEQ_CS_2500Hz_Q1.00_-3dB',
        'b': [[1.1923588988297062, -1.9454835387249805, 0.86215756244531327]],
        'a': [[1.260469123101291, -1.9454835387249805, 0.79404733817372841]],
        'color': 'blue',
        'linestyle': ':'
    },
    {
        'name': 'LowShelf_CS_200Hz_3dB',
        'b': [[1.031358754971289, -1.9995158757137192, 0.9691253693149916]],
        'a': [[1.0263528010434653, -1.9996572662524097, 0.97398993270412504]],
        'color': 'green',
        'linestyle': '-'
    },
    # Shelves
    {
        'name': 'HighShelf_CS_8000Hz_4dB',
        'b': [[3.3719083765724926, -2.5031197182555607, 0.46454467501640107]],
        'a': [[2.4880338717125845, -1.3333333333333335, 0.1786327949540818]],
        'color': 'green',
        'linestyle': '--'
    },
    # HPF/LPF
    {
        'name': 'HPF_CS_80Hz_ord2',
        'b': [[1.0, -2.0, 1.0]],
        'a': [[1.0074322863440843, -1.9999451678622717, 0.99262254579364406]],
        'color': 'red',
        'linestyle': '-'
    },
    {
        'name': 'LPF_CS_12000Hz_ord2',
        'b': [[0.99999999999999978, 1.9999999999999996, 0.99999999999999978]],
        'a': [[3.414213124746325, -4.4408920985006262e-16, 0.58578687525367457]],
        'color': 'red',
        'linestyle': '--'
    },
    # Notch filters
    {
        'name': 'Notch_CS_1000Hz_Q10.00',
        'b': [[1.0, -1.9828897227476208, 1.0]],
        'a': [[1.0065263096110026, -1.9828897227476208, 0.99347369038899747]],
        'color': 'purple',
        'linestyle': '-'
    },
    {
        'name': 'Notch_CS_500Hz_Q2.00',
        'b': [[1.0, -1.995717846477207, 1.0]],
        'a': [[1.0163507823075357, -1.995717846477207, 0.98364921769246427]],
        'color': 'purple',
        'linestyle': '--'
    },
    {
        'name': 'Notch_CS 1000Hz Q1.41',
        'b': [[1, -1.9828897227476208, 1]],
        'a': [[1.0461549466233533, -1.9828897227476208, 0.95384505337664682]],
        'color': 'purple',
        'linestyle': '-'
    },
    # {
    #     'name': 'Filter Name',
    #     'b': [[b0,b1,b2], [b0,b1,b2], ...],
    #     'a': [[a0,a1,a2], [a0,a1,a2], ...],
    #     'color': 'green',
    #     'linestyle': '--'
    # },
]

# ==============================================================================
# PLOTTING CODE
# ==============================================================================
def cascade_biquads_response(b_sections, a_sections, fs=48000, nfft=100000):
    """Compute frequency response of cascaded biquad sections."""
    num = np.array([1.0])
    den = np.array([1.0])
    
    for b, a in zip(b_sections, a_sections):    
        num = np.convolve(num, b)
        den = np.convolve(den, a)
    
    w, h = signal.freqz(num, den, worN=nfft, fs=fs)
    return w, h

def plot_single_filter(filt, output_path):
    """Plot a single filter's magnitude and phase response."""
    
    if not filt.get('b') or not filt.get('a'):
        print(f"Skipping {filt['name']}: Missing coefficients")
        return
    
    w, h = cascade_biquads_response(filt['b'], filt['a'], fs=FS)
    
    mag_db = 20 * np.log10(np.abs(h) + 1e-12)
    
    phase = np.unwrap(np.angle(h))
    phase_deg = np.degrees(phase)
    
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=PLOT_SETTINGS['figsize'])
    
    ax1.semilogx(w, mag_db, 
                color=filt.get('color', 'blue'),
                linestyle=filt.get('linestyle', '-'),
                linewidth=PLOT_SETTINGS['linewidth'])
    
    ax1.set_title(f"{filt['name']} - Magnitude Response", fontsize=14, fontweight='bold')
    ax1.set_xlabel('Frequency (Hz)')
    ax1.set_ylabel('Magnitude (dB)')
    ax1.grid(True, which='both', linestyle='--', alpha=PLOT_SETTINGS['grid_alpha'])
    ax1.axhline(y=0, color='black', linestyle='-', alpha=0.3)
    ax1.axhline(y=-3, color='gray', linestyle=':', alpha=0.5, label='-3dB')
    ax1.axvline(x=100, color='gray', linestyle=':', alpha=0.3)
    ax1.axvline(x=1000, color='gray', linestyle=':', alpha=0.3)
    ax1.axvline(x=10000, color='gray', linestyle=':', alpha=0.3)
    ax1.set_xlim(PLOT_SETTINGS['freq_range'])
    ax1.set_ylim(PLOT_SETTINGS['mag_range'])
    
    ax1.text(100, ax1.get_ylim()[1]-5, '100Hz', fontsize=8, alpha=0.5)
    ax1.text(1000, ax1.get_ylim()[1]-5, '1kHz', fontsize=8, alpha=0.5)
    ax1.text(10000, ax1.get_ylim()[1]-5, '10kHz', fontsize=8, alpha=0.5)
    
    ax2.semilogx(w, phase_deg,
                color=filt.get('color', 'blue'),
                linestyle=filt.get('linestyle', '-'),
                linewidth=PLOT_SETTINGS['linewidth'])
    
    ax2.set_title(f"{filt['name']} - Phase Response", fontsize=14, fontweight='bold')
    ax2.set_xlabel('Frequency (Hz)')
    ax2.set_ylabel('Phase (degrees)')
    ax2.grid(True, which='both', linestyle='--', alpha=PLOT_SETTINGS['grid_alpha'])
    ax2.axhline(y=0, color='black', linestyle='-', alpha=0.3)
    ax2.set_xlim(PLOT_SETTINGS['freq_range'])
    
    plt.tight_layout()
    
    plt.savefig(output_path, dpi=PLOT_SETTINGS['dpi'], bbox_inches='tight')
    plt.close()
    
    print(f"✓ Saved: {output_path}")

def create_output_folder():
    """Create output folder if it doesn't exist."""
    folder = Path(OUTPUT_FOLDER)
    folder.mkdir(exist_ok=True)
    return folder

def print_filter_info():
    """Print basic info about each filter."""
    print("\n" + "="*60)
    print("IIR FILTER RESPONSE PLOTTER")
    print("="*60)
    print(f"Sample Rate: {FS} Hz")
    print(f"Nyquist Frequency: {FS/2} Hz")
    print(f"Output Folder: {OUTPUT_FOLDER}/")
    print(f"Number of Filters: {len(FILTERS)}\n")

def main():
    """Main function to plot all filters."""
    print_filter_info()
    
    output_folder = create_output_folder()
    
    print("Generating plots...")
    print("-"*40)
    
    for i, filt in enumerate(FILTERS, 1):
        filename = f"{filt['name']}.png"
        filename = filename.replace(' ', '_').replace('/', '_')
        
        output_path = output_folder / filename
        
        try:
            plot_single_filter(filt, output_path)
        except Exception as e:
            print(f"✗ Error plotting {filt['name']}: {e}")
    
    print("-"*40)
    print(f"\nComplete! All plots saved to: {output_folder.absolute()}/")
    print("\nNote: Existing files with the same names have been replaced.")

if __name__ == '__main__':
    main()