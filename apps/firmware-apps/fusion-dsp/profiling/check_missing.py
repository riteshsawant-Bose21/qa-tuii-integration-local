import glob
import os
import re

def check_missing_combinations(config_name='matrix_mixer', expected_params=None):
    """
    Check which combinations are missing from the expected grid for a given configuration.
    
    Args:
        config_name: The configuration to check ('matrix_mixer' or 'peq')
        expected_params: Dictionary of expected parameter ranges (if None, uses defaults)
    """
    
    checkpoint_dir = f'profiling_results/{config_name}_checkpoints'
    
    if os.path.exists(checkpoint_dir):
        print(f"Checking checkpoint directory: {checkpoint_dir}")
        if config_name == 'matrix_mixer':
            pattern = f'{checkpoint_dir}/timings_mm_*_*_processed.csv'
        elif config_name == 'peq':
            pattern = f'{checkpoint_dir}/timings_peq_*_*_processed.csv'
        else:
            pattern = f'{checkpoint_dir}/timings_{config_name}_*_processed.csv'
    else:
        config_dir = f'profiling_results/{config_name}'
        if os.path.exists(config_dir):
            print(f"No checkpoint directory, checking config directory: {config_dir}")
            if config_name == 'matrix_mixer':
                pattern = f'{config_dir}/timings_mm_*_*_processed.csv'
            elif config_name == 'peq':
                pattern = f'{config_dir}/timings_peq_*_*_processed.csv'
            else:
                pattern = f'{config_dir}/timings_{config_name}_*_processed.csv'
        else:
            print(f"No data directories found for {config_name}")
            return set(), set()
    
    existing_files = glob.glob(pattern)
    existing_combos = set()
    
    if config_name == 'matrix_mixer':
        for filepath in existing_files:
            filename = os.path.basename(filepath)
            match = re.search(r'timings_mm_(\d+)_(\d+)(?:_processed)?', filename)
            if match:
                num_inputs = int(match.group(1))
                num_outputs = int(match.group(2))
                existing_combos.add((num_inputs, num_outputs))
        
        if expected_params and 'num_inputs' in expected_params and 'num_outputs' in expected_params:
            inputs_range = list(expected_params['num_inputs'])
            outputs_range = list(expected_params['num_outputs'])
        else:
            inputs_range = list(range(1, 65))
            outputs_range = list(range(1, 65))
        
        expected_combos = set()
        for i in inputs_range:
            for o in outputs_range:
                expected_combos.add((i, o))
        
        param_names = ['num_inputs', 'num_outputs']
        
    elif config_name == 'peq':
        for filepath in existing_files:
            filename = os.path.basename(filepath)
            match = re.search(r'timings_peq_(\d+)_(\d+)(?:_processed)?', filename)
            if match:
                bands = int(match.group(1))
                channels = int(match.group(2))
                existing_combos.add((bands, channels))
        
        if expected_params and 'bands' in expected_params and 'channels' in expected_params:
            bands_range = list(expected_params['bands'])
            channels_range = list(expected_params['channels'])
        else:
            bands_range = list(range(1, 41))
            channels_range = list(range(1, 17))
        
        expected_combos = set()
        for b in bands_range:
            for c in channels_range:
                expected_combos.add((b, c))
        
        param_names = ['bands', 'channels']
        
    else:
        print(f"Configuration '{config_name}' not recognized for missing data check")
        return existing_combos, set()
    
    missing_combos = expected_combos - existing_combos
    
    print("=" * 60)
    print(f"{config_name.upper()} FILE CHECK")
    print("=" * 60)
    
    if config_name == 'matrix_mixer':
        if expected_params:
            inputs_count = len(list(expected_params.get('num_inputs', range(1, 65))))
            outputs_count = len(list(expected_params.get('num_outputs', range(1, 65))))
            print(f"Expected combinations: {len(expected_combos)} ({inputs_count} inputs × {outputs_count} outputs)")
        else:
            print(f"Expected combinations: {len(expected_combos)} (64 × 64)")
    elif config_name == 'peq':
        if expected_params:
            bands_count = len(list(expected_params.get('bands', range(1, 41))))
            channels_count = len(list(expected_params.get('channels', range(1, 17))))
            print(f"Expected combinations: {len(expected_combos)} ({bands_count} bands × {channels_count} channels)")
        else:
            print(f"Expected combinations: {len(expected_combos)} (40 bands × 16 channels)")
    else:
        print(f"Expected combinations: {len(expected_combos)}")
    
    print(f"Existing combinations: {len(existing_combos)}")
    print(f"Missing combinations: {len(missing_combos)}")
    if len(expected_combos) > 0:
        print(f"Completion: {len(existing_combos)/len(expected_combos)*100:.1f}%")
    
    if missing_combos:
        print("\n" + "=" * 60)
        print("MISSING COMBINATIONS")
        print("=" * 60)
        
        missing_by_first = {}
        for combo in missing_combos:
            first_val, second_val = combo
            if first_val not in missing_by_first:
                missing_by_first[first_val] = []
            missing_by_first[first_val].append(second_val)
        
        printed = 0
        max_to_print = 20
        for first_val in sorted(missing_by_first.keys()):
            if printed >= max_to_print:
                print(f"  ... and {len(missing_by_first) - printed} more {param_names[0]} values")
                break
            
            second_vals = sorted(missing_by_first[first_val])
            
            ranges = []
            start = second_vals[0]
            end = second_vals[0]
            
            for i in range(1, len(second_vals)):
                if second_vals[i] == end + 1:
                    end = second_vals[i]
                else:
                    if start == end:
                        ranges.append(str(start))
                    else:
                        ranges.append(f"{start}-{end}")
                    start = second_vals[i]
                    end = second_vals[i]
            
            if start == end:
                ranges.append(str(start))
            else:
                ranges.append(f"{start}-{end}")
            
            print(f"  {param_names[0]}={first_val:2d}: {param_names[1]} {', '.join(ranges)}")
            printed += 1
        
        config_dir = f'profiling_results/{config_name}'
        os.makedirs(config_dir, exist_ok=True)
        output_file = f'{config_dir}/{config_name}_missing_combinations.txt'
        
        with open(output_file, 'w') as f:
            f.write(f"Missing {config_name.upper()} Combinations\n")
            f.write("=" * 40 + "\n")
            f.write(f"Total missing: {len(missing_combos)} out of {len(expected_combos)}\n\n")
            f.write(f"{param_names[0]},{param_names[1]}\n")
            
            for combo in sorted(missing_combos):
                f.write(f"{combo[0]},{combo[1]}\n")
        
        print(f"\nDetailed list saved to: {output_file}")
    else:
        print(f"\n✓ All expected {config_name} combinations are present!")
    
    return existing_combos, missing_combos

def check_checkpoint_progress(config_name):
    """
    Check the progress of checkpointed data for a given configuration.
    """
    checkpoint_dir = f'profiling_results/{config_name}_checkpoints'
    
    if not os.path.exists(checkpoint_dir):
        print(f"No checkpoint directory found for {config_name}")
        return None, None
    
    print(f"\n" + "=" * 60)
    print(f"CHECKPOINT PROGRESS FOR {config_name.upper()}")
    print("=" * 60)
    
    existing, missing = check_missing_combinations(config_name)
    
    params_file = f'{checkpoint_dir}/processed_params.csv'
    if os.path.exists(params_file):
        import pandas as pd
        params_df = pd.read_csv(params_file)
        print(f"\nParams checkpoint file contains {len(params_df)} entries")
    
    return existing, missing

def check_all_configs():
    """
    Check missing data for all supported configurations.
    """
    configs = ['matrix_mixer', 'peq']
    
    for config in configs:
        print(f"\n{'='*70}")
        print(f"Checking {config.upper()}")
        print(f"{'='*70}")
        
        existing, missing = check_missing_combinations(config)
        
        checkpoint_dir = f'profiling_results/{config}_checkpoints'
        if os.path.exists(checkpoint_dir):
            print(f"\n✓ Checkpoint directory exists: {checkpoint_dir}")
            
            if config == 'matrix_mixer':
                pattern = f'{checkpoint_dir}/timings_mm_*_*_processed.csv'
            elif config == 'peq':
                pattern = f'{checkpoint_dir}/timings_peq_*_*_processed.csv'
            else:
                pattern = f'{checkpoint_dir}/timings_{config}_*_processed.csv'
            
            checkpoint_files = glob.glob(pattern)
            print(f"  Contains {len(checkpoint_files)} checkpoint files")

def get_resume_params(config_name, expected_params=None):
    """
    Get the parameters to resume from based on missing combinations.
    
    Returns a list of parameter dictionaries for missing combinations.
    """
    _, missing_combos = check_missing_combinations(config_name, expected_params)
    
    resume_params = []
    
    if config_name == 'matrix_mixer':
        for num_inputs, num_outputs in missing_combos:
            resume_params.append({
                'num_inputs': num_inputs,
                'num_outputs': num_outputs
            })
    elif config_name == 'peq':
        for bands, channels in missing_combos:
            resume_params.append({
                'bands': bands,
                'channels': channels
            })
    
    return resume_params

if __name__ == '__main__':
    import argparse
    
    parser = argparse.ArgumentParser(description='Check for missing profiling data combinations')
    parser.add_argument('config', nargs='?', default='matrix_mixer',
                       choices=['matrix_mixer', 'peq', 'all'],
                       help='Configuration to check (default: matrix_mixer)')
    parser.add_argument('--checkpoints', action='store_true',
                       help='Check checkpoint directories')
    parser.add_argument('--resume-params', action='store_true',
                       help='Generate parameters for resuming incomplete runs')
    
    args = parser.parse_args()
    
    if args.config == 'all':
        check_all_configs()
    else:
        if args.checkpoints:
            check_checkpoint_progress(args.config)
        else:
            existing, missing = check_missing_combinations(args.config)
        
        if args.resume_params and missing:
            resume_params = get_resume_params(args.config)
            print(f"\n" + "=" * 60)
            print(f"RESUME PARAMETERS")
            print("=" * 60)
            print(f"Found {len(resume_params)} missing combinations to process")
            
            import json
            config_dir = f'profiling_results/{args.config}'
            os.makedirs(config_dir, exist_ok=True)
            resume_file = f'{config_dir}/{args.config}_resume_params.json'
            with open(resume_file, 'w') as f:
                json.dump(resume_params, f, indent=2)
            print(f"Resume parameters saved to: {resume_file}")