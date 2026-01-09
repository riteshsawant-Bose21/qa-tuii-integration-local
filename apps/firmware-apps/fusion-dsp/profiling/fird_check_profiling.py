#!/usr/bin/env python3
"""
Profiling results checker for FIR Direct.
Displays MIPS budget, pass/fail status, and maximum safe filter lengths.
"""
import pandas as pd
import sys

FRAME_TIME = 32 / 48000
TARGET_MIPS = 100

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    RESET = '\033[0m'
    BOLD = '\033[1m'


def check_profiling_results():
    """Load FIR Direct results and print pass/fail table."""
    try:
        df = pd.read_csv('../profiling_results/fir_direct/fir_direct_timings.csv')
    except FileNotFoundError:
        print("Error: profiling_results/fir_direct/fir_direct_timings.csv not found")
        print("Run profiling first: cd profiling && python profile_block.py fir_direct --local")
        return 1

    print("=" * 70)
    print(" FIR DIRECT PROFILING - QUICK CHECKER")
    print("=" * 70)
    print(f"\nTarget: {FRAME_TIME*1000:.3f} ms per frame | MIPS Budget: {TARGET_MIPS}%")
    print(f"Total samples: {len(df):,}\n")

    summary = df.groupby(['channels', 'num_taps'])['fir_direct'].agg(['mean', 'max'])
    summary['avg_mips'] = (summary['mean'] / FRAME_TIME) * 100
    summary['worst_mips'] = (summary['max'] / FRAME_TIME) * 100
    summary['status'] = summary['worst_mips'].apply(lambda x: 'PASS' if x < TARGET_MIPS else 'FAIL')

    print("-" * 70)
    print(f"{'CH':<6} {'Taps':<8} {'Avg MIPS':<14} {'Worst MIPS':<14} {'Status':<8}")
    print("-" * 70)

    for (ch, taps), row in summary.iterrows():
        is_passing = row['status'] == 'PASS'
        status_color = Colors.GREEN if is_passing else Colors.RED
        status_text = f"{status_color}{row['status']}{Colors.RESET}"
        avg = f"{row['avg_mips']:.1f}%"
        worst = f"{row['worst_mips']:.1f}%"
        print(f"{ch:<6} {taps:<8} {avg:<14} {worst:<14} {status_text}")

    print("\n" + "=" * 70)
    print(" MAXIMUM SAFE FILTER LENGTHS")
    print("=" * 70)

    for ch in sorted(summary.index.get_level_values(0).unique()):
        ch_data = summary.loc[ch]
        passing = ch_data[ch_data['worst_mips'] < TARGET_MIPS]

        if len(passing) > 0:
            max_taps = passing.index.max()
            worst = passing.loc[max_taps, 'worst_mips']
            print(f"  {Colors.GREEN}{ch} Channel(s): Up to {max_taps:>5} taps ({worst:>5.1f}% worst-case){Colors.RESET}")
        else:
            print(f"  {Colors.RED}{ch} Channel(s): ALL FAIL - no safe configurations{Colors.RESET}")

    passing_count = (summary['worst_mips'] < TARGET_MIPS).sum()
    total_count = len(summary)

    print("\n" + "=" * 70)
    print(f" {Colors.GREEN}Passing: {passing_count}/{total_count} ({passing_count/total_count*100:.0f}%){Colors.RESET}")
    print(f" {Colors.RED}Failing: {total_count - passing_count}/{total_count}{Colors.RESET}")
    print("=" * 70 + "\n")

    return 0


if __name__ == '__main__':
    sys.exit(check_profiling_results())
