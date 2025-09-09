import glob
import os
import re

def check_missing_combinations():
    """
    Check which matrix mixer combinations are missing from the expected 64x64 grid
    """
    pattern = 'profiling_results/timings_mm_*_*_processed.csv'
    existing_files = glob.glob(pattern)
    
    existing_combos = set()
    for filepath in existing_files:
        filename = os.path.basename(filepath)
        match = re.search(r'timings_mm_(\d+)_(\d+)_processed\.csv', filename)
        if match:
            num_inputs = int(match.group(1))
            num_outputs = int(match.group(2))
            existing_combos.add((num_inputs, num_outputs))
    
    expected_combos = set()
    for i in range(1, 65):
        for o in range(1, 65):
            expected_combos.add((i, o))
    
    missing_combos = expected_combos - existing_combos
    
    print("=" * 60)
    print("MATRIX MIXER FILE CHECK")
    print("=" * 60)
    print(f"Expected combinations: {len(expected_combos)} (64 × 64)")
    print(f"Existing combinations: {len(existing_combos)}")
    print(f"Missing combinations: {len(missing_combos)}")
    print(f"Completion: {len(existing_combos)/len(expected_combos)*100:.1f}%")
    
    if missing_combos:
        print("\n" + "=" * 60)
        print("MISSING COMBINATIONS")
        print("=" * 60)
        
        missing_by_input = {}
        for inp, outp in missing_combos:
            if inp not in missing_by_input:
                missing_by_input[inp] = []
            missing_by_input[inp].append(outp)
        
        for inp in sorted(missing_by_input.keys()):
            outputs = sorted(missing_by_input[inp])
            
            ranges = []
            start = outputs[0]
            end = outputs[0]
            
            for i in range(1, len(outputs)):
                if outputs[i] == end + 1:
                    end = outputs[i]
                else:
                    if start == end:
                        ranges.append(str(start))
                    else:
                        ranges.append(f"{start}-{end}")
                    start = outputs[i]
                    end = outputs[i]
            
            if start == end:
                ranges.append(str(start))
            else:
                ranges.append(f"{start}-{end}")
            
            print(f"  Input {inp:2d}: outputs {', '.join(ranges)}")
    
    if missing_combos:
        with open('profiling_results/missing_combinations.txt', 'w') as f:
            f.write("Missing Matrix Mixer Combinations\n")
            f.write("=" * 40 + "\n")
            f.write(f"Total missing: {len(missing_combos)} out of {len(expected_combos)}\n\n")
            
            for inp, outp in sorted(missing_combos):
                f.write(f"{inp},{outp}\n")
        
        print(f"\nDetailed list saved to: profiling_results/missing_combinations.txt")
    else:
        print("\n✓ All expected combinations are present!")
    
    return existing_combos, missing_combos

if __name__ == '__main__':
    existing, missing = check_missing_combinations()