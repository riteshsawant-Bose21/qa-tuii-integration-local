import pandas as pd
import jinja2 as jinja2
import itertools
import pickle
import sys
import os
import platform
import subprocess
import glob
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from sklearn.linear_model import LinearRegression

sample_rate = 48000

def convert_mips_to_time(mips_value, processor_speed_mhz,
                         sample_rate=sample_rate, frame_size=32):
    """
    Convert MIPS value to time in milliseconds.
    
    Args:
        mips_value (float): MIPS value to convert.
        processor_speed_mhz (float): Processor speed in MHz.
        sample_rate (int): Sample rate in Hz.
        frame_size (int): Frame size in samples.
        
    Returns:
        float: Time in seconds.
    """
    execution_time = mips_value * frame_size / (processor_speed_mhz * sample_rate)
    return execution_time

def check_remote_diskspace(board_ip):
    """
    Check the available disk space on the remote Variscite board and clean.

    Args:
        board_ip (str): The IP address of the Variscite board.
    """
    result = subprocess.run(
        ['ssh', f'root@{board_ip}', 'df', '-h', '/home/root'],
        capture_output=True,
        text=True
    )
    print(f'Disk space on {board_ip}:')
    print(result.stdout)
    
    print('Cleaning up previous files...')
    cleanup_result = subprocess.run(['ssh', f'root@{board_ip}', 'rm', '-f', '/home/root/tmp.json', '/home/root/timings.csv', '/home/root/out.wav'], 
                   capture_output=True, text=True)

    if cleanup_result.returncode == 0:
        print('Cleanup successful.')
    else:
        print('Cleanup failed:')
        print(cleanup_result.stderr)

def get_checkpoint_dir(config_name):
    """Get the checkpoint directory for a given config"""
    return f'profiling_results/{config_name}_checkpoints'

def get_checkpoint_params_file(config_name):
    """Get the checkpoint params file path"""
    checkpoint_dir = get_checkpoint_dir(config_name)
    return f'{checkpoint_dir}/processed_params.csv'

def save_processed_checkpoint(config_name, param_dict, df):
    """Save a processed dataframe to checkpoint directory"""
    checkpoint_dir = get_checkpoint_dir(config_name)
    os.makedirs(checkpoint_dir, exist_ok=True)
    
    if config_name == 'matrix_mixer':
        checkpoint_file = f"{checkpoint_dir}/timings_mm_{param_dict['num_inputs']}_{param_dict['num_outputs']}_processed.csv"
    elif config_name == 'peq':
        checkpoint_file = f"{checkpoint_dir}/timings_peq_{param_dict['bands']}_{param_dict['channels']}_processed.csv"
    else:
        param_str = '_'.join([f"{k}{v}" for k, v in param_dict.items()])
        checkpoint_file = f"{checkpoint_dir}/timings_{config_name}_{param_str}_processed.csv"
    
    df.to_csv(checkpoint_file, index=False)
    return checkpoint_file

def load_checkpoints(config_name):
    """Load existing checkpoints for a config"""
    checkpoint_dir = get_checkpoint_dir(config_name)
    params_file = get_checkpoint_params_file(config_name)
    processed_combos = set()
    
    if os.path.exists(params_file):
        params_df = pd.read_csv(params_file)
        
        if config_name == 'matrix_mixer' and 'num_inputs' in params_df.columns:
            processed_combos = set(zip(params_df['num_inputs'], params_df['num_outputs']))
        elif config_name == 'peq' and 'bands' in params_df.columns:
            processed_combos = set(zip(params_df['bands'], params_df['channels']))
        else:
            param_cols = [col for col in params_df.columns if col not in ['Unnamed: 0']]
            if param_cols:
                processed_combos = set([tuple(row[col] for col in param_cols) 
                                       for _, row in params_df.iterrows()])
        
        print(f'Loaded {len(processed_combos)} already processed combinations from checkpoint')
    
    return processed_combos

def cleanup_checkpoints(config_name):
    """Remove checkpoint directory after successful completion"""
    checkpoint_dir = get_checkpoint_dir(config_name)
    if os.path.exists(checkpoint_dir):
        for root, dirs, files in os.walk(checkpoint_dir, topdown=False):
            for file in files:
                os.remove(os.path.join(root, file))
            for dir in dirs:
                os.rmdir(os.path.join(root, dir))
        os.rmdir(checkpoint_dir)
        print(f"Cleaned up checkpoint directory: {checkpoint_dir}")

def run_checkpoint_analysis(config_name, suffix='local'):
    """Run the CSV processing for configs that use checkpoints (matrix_mixer, peq, etc.)"""
    try:
        import process_csv
        print("\n" + "="*60)
        print(f"RUNNING {config_name.upper()} CHECKPOINT ANALYSIS")
        print("="*60)
        
        checkpoint_dir = get_checkpoint_dir(config_name)
        if os.path.exists(checkpoint_dir):
            print(f"Processing from checkpoint directory: {checkpoint_dir}")
            success = process_csv.process_files_in_batches(
                config_name=config_name,
                batch_size=100
            )
        else:
            print("No checkpoint directory found")
            return None
        
        if success:
            model = process_csv.perform_incremental_regression(
                config_name=config_name, 
                calculate_all_formulas=True,
                suffix=suffix
            )
            
            process_csv.cleanup_temp_files(config_name)
            
            return model
        else:
            print("Failed to process CSV files")
            return None
            
    except ImportError:
        print("Warning: process_csv.py not found, skipping checkpoint analysis")
        return None
    except Exception as e:
        print(f"Error during {config_name} analysis: {e}")
        return None

def check_missing_data(config_name, current_config):
    """Check for missing data combinations"""
    try:
        import check_missing
        
        print("\n" + "="*60)
        print(f"CHECKING FOR MISSING {config_name.upper()} DATA")
        print("="*60)
        
        params = current_config.get('parameters', {})
        if config_name in ['matrix_mixer', 'peq']:
            existing, missing = check_missing.check_missing_combinations(
                config_name, 
                expected_params=params
            )
            return len(missing) == 0
        
    except ImportError:
        print("Warning: check_missing.py not found, skipping missing data check")
        return True
    except Exception as e:
        print(f"Error checking missing data: {e}")
        return True

def profile(config_name, remote=True, board_ip='192.168.1.6', board_clock=1500.0):
    """
    Profile a specific config locally or remotely on a Variscite board.
    
    Args:
        config_name (str): The name of the configuration to profile.
        remote (bool): If True, runs the profiling on a remote Variscite board via SSH.
        board_ip (str): IP address of the remote board
        board_clock (float): Clock speed in MHz of the remote board
    """
    loader = jinja2.FileSystemLoader("./config/profiling")
    env = jinja2.Environment(loader=loader, autoescape=jinja2.select_autoescape())
    current_config = configurations[config_name]
    template = env.get_template(current_config['path'])
    
    frames = []
    analysis_mips_data = []

    params_iter = dict_to_iter(current_config.get('parameters', default_parameters))
    feature_dict = current_config.get('features', default_features)

    param_counter = 0
    completed_params = []
    
    needs_special_processing = config_name in ['matrix_mixer', 'peq']
    
    processed_combos = set()
    if needs_special_processing:
        processed_combos = load_checkpoints(config_name)
    
    for param_dict in params_iter:
        if needs_special_processing:
            if config_name == 'matrix_mixer':
                combo_key = (param_dict['num_inputs'], param_dict['num_outputs'])
            elif config_name == 'peq':
                combo_key = (param_dict['bands'], param_dict['channels'])
            else:
                combo_key = tuple(param_dict.values())
            
            if combo_key in processed_combos:
                print(f"Skipping already processed combination: {combo_key}")
                continue

        param_counter += 1
        
        if remote:
            check_remote_diskspace(board_ip)
            config_content = template.render(
                output_file='/home/root/timings.csv',
                wav_input=current_config.get('wav_input','in.wav'),
                algorithm=current_config.get('algorithm'),
                **param_dict
            ) 
            
            with open('tmp.json', 'w') as f:
                f.write(config_content)
            
            print(f'REMOTE: Running with parameters: {param_dict}')
            os.system(f'scp tmp.json root@{board_ip}:/home/root/tmp.json')
            
            if config_name == 'feedback_suppression':
                fusion_cmd = '/usr/local/bin/fusion_dsp -v -d /etc/fusion/dsp/algorithm-definitions.json -c /home/root/tmp.json 2>&1'
            else:
                fusion_cmd = '/usr/local/bin/fusion_dsp -d /etc/fusion/dsp/algorithm-definitions.json -c /home/root/tmp.json'
        
            result = subprocess.run([
                'ssh', f'root@{board_ip}', fusion_cmd
            ], capture_output=True, text=True)

            print(f'fusion_dsp output: {result.stdout}')
            if result.stderr:
                print(f'fusion_dsp error: {result.stderr}')
            
            if config_name == 'feedback_suppression':
                for line in result.stdout.split('\n'):
                    if 'AudioTask 0 MIPS:' in line:
                        parts = line.split('MIPS:')[1].strip()
                        numbers = parts.replace(' first,', '').replace(' max,', '').replace(' avg.', '').split()
                        mips_avg = float(numbers[2])
                        analysis_thread_time = convert_mips_to_time(mips_value=mips_avg, processor_speed_mhz=board_clock)
                        analysis_mips_data.append({
                            'channels': param_dict['channels'],
                            'analysis_first': float(numbers[0]),
                            'analysis_max': float(numbers[1]),
                            'analysis_avg': mips_avg,
                            'analysis_time': analysis_thread_time
                        })
                        print(f"Captured analysis MIPS: avg={mips_avg}")
                        print(f"Converted to analysis thread time: {analysis_thread_time} seconds")
            
            os.system(f'scp root@{board_ip}:/home/root/timings.csv ./timings.csv')
            local_csv_name = 'timings.csv'
            
            print(f'Cleanup after remote execution')
            os.system(f'ssh root@{board_ip} "rm -f /home/root/tmp.json /home/root/timings.csv"')
        else:
            config_content = template.render(
                output_file='timings.csv',
                wav_input=current_config.get('wav_input','in.wav'),
                algorithm=current_config.get('algorithm'),
                **param_dict
            )
            
            with open('tmp.json', 'w') as f:
                f.write(config_content)
            
            print(f'LOCAL: Running with parameters: {param_dict}')
            if platform.system() == 'Darwin':
                env = {'DYLD_LIBRARY_PATH' : 'libs/onnxruntime-osx-universal2-1.17.0/lib/:'}
            else:
                env = {'LD_LIBRARY_PATH' : 'libs/onnxruntime-linux-x64-1.17.0/lib/:'}
            subprocess.run(['./build/fusion_dsp','-c', 'tmp.json'], env=env)
            local_csv_name = 'timings.csv'
        
        try:
            df = pd.read_csv(local_csv_name)
            print(f"Read {len(df)} rows from {local_csv_name}")
            
            for param_name, param_value in param_dict.items():
                df[param_name] = param_value
            
            for feature, formula in feature_dict.items():
                if feature != 'analysis_avg':
                    df[feature] = formula(param_dict)
            
            if needs_special_processing:
                checkpoint_file = save_processed_checkpoint(config_name, param_dict, df)
                print(f"Checkpoint saved: {checkpoint_file}")
            else:
                frames.append(df)
            
            completed_params.append(param_dict)
            
            if needs_special_processing and param_counter % 10 == 0:
                checkpoint_dir = get_checkpoint_dir(config_name)
                os.makedirs(checkpoint_dir, exist_ok=True)
                params_file = get_checkpoint_params_file(config_name)
                params_df = pd.DataFrame(completed_params)
                params_df.to_csv(params_file, index=False)
                print(f"Params checkpoint saved at iteration {param_counter}")
            
            if os.path.exists(local_csv_name):
                os.remove(local_csv_name)
                
        except Exception as e:
            print(f"Error reading {local_csv_name}: {e}")
            continue
    
    if needs_special_processing and completed_params:
        checkpoint_dir = get_checkpoint_dir(config_name)
        os.makedirs(checkpoint_dir, exist_ok=True)
        params_file = get_checkpoint_params_file(config_name)
        params_df = pd.DataFrame(completed_params)
        params_df.to_csv(params_file, index=False)
        print(f"Final params checkpoint saved: {len(completed_params)} combinations")
    
    if needs_special_processing:
        complete = check_missing_data(config_name, current_config)
        if not complete:
            print(f"WARNING: Some {config_name} combinations are missing!")
    
    if config_name in ['matrix_mixer', 'peq']:
        print(f"\n{'='*60}")
        print(f"{config_name.upper()} DATA COLLECTION COMPLETE")
        print(f"{'='*60}")
        print(f"Parameter combinations processed: {param_counter}")
        
        suffix = 'remote' if remote else 'local'
        model = run_checkpoint_analysis(config_name, suffix)
        
        if model is not None:
            cleanup_checkpoints(config_name)
        
        return model
    
    if needs_special_processing:
        checkpoint_dir = get_checkpoint_dir(config_name)
        processed_files = glob.glob(f'{checkpoint_dir}/timings_{config_name}_*_processed.csv')
        
        print(f"Found {len(processed_files)} processed files")
        
        for file in processed_files:
            try:
                df = pd.read_csv(file)
                frames.append(df)
            except Exception as e:
                print(f"Error loading {file}: {e}")
                continue
    
    if not frames:
        print("No data to process!")
        return None
    
    result_df = pd.concat(frames, axis=0, ignore_index=True)
    
    block = current_config.get('block', config_name)
    
    print(f"Total rows for analysis: {len(result_df)}")
    
    if config_name == 'feedback_suppression' and analysis_mips_data:
        for mips_entry in analysis_mips_data:
            ch = mips_entry['channels']
            mask = result_df['channels'] == ch
            
            result_df.loc[mask, 'analysis_avg'] = mips_entry['analysis_avg']
            result_df.loc[mask, 'analysis_time'] = mips_entry['analysis_time']
            result_df.loc[mask, block] = (
                result_df.loc[mask, block] + mips_entry['analysis_time']
            )
    
    if current_config.get('csv_dump'):
        config_dir = f'profiling_results/{config_name}'
        os.makedirs(config_dir, exist_ok=True)
        result_df.to_csv(f"{config_dir}/{current_config['csv_dump']}")
    
    params_dict = current_config.get('parameters', default_parameters)
    param_columns = list(params_dict.keys())
    existing_param_cols = [col for col in param_columns if col in result_df.columns]
    
    filtered_df = []
    
    if len(existing_param_cols) == 0:
        low_quantile = result_df.quantile(0.999)[block]
        high_quantile = result_df.quantile(0.9999)[block]
        filtered_df = [result_df[
            (result_df[block] >= low_quantile) &
            (result_df[block] <= high_quantile)
        ]]
    elif len(existing_param_cols) == 1:
        filter_column = existing_param_cols[0]
        for group_value in sorted(result_df[filter_column].unique()):
            ch_df = result_df[result_df[filter_column] == group_value].copy()
            ch_df[block] = pd.to_numeric(ch_df[block], errors='coerce')
            ch_df = ch_df.dropna(subset=[block])
            
            if len(ch_df) > 0:
                try:
                    low_quantile = ch_df.quantile(0.999)[block]
                    high_quantile = ch_df.quantile(0.9999)[block]
                    filtered_ch = ch_df[
                        (ch_df[block] >= low_quantile) &
                        (ch_df[block] <= high_quantile)
                    ]
                    filtered_df.append(filtered_ch)
                except Exception as e:
                    print(f"Error processing {filter_column}={group_value}: {e}")
                    continue
    else:
        param_combinations = result_df[existing_param_cols].drop_duplicates()
        for idx, row in param_combinations.iterrows():
            mask = pd.Series([True] * len(result_df))
            for col in existing_param_cols:
                mask = mask & (result_df[col] == row[col])
            
            combo_df = result_df[mask].copy()
            combo_df[block] = pd.to_numeric(combo_df[block], errors='coerce')
            combo_df = combo_df.dropna(subset=[block])
            
            if len(combo_df) > 0:
                try:
                    low_quantile = combo_df.quantile(0.999)[block]
                    high_quantile = combo_df.quantile(0.9999)[block]
                    filtered_combo = combo_df[
                        (combo_df[block] >= low_quantile) &
                        (combo_df[block] <= high_quantile)
                    ]
                    filtered_df.append(filtered_combo)
                except Exception as e:
                    continue
    
    if len(filtered_df) > 0:
        filtered_df = pd.concat(filtered_df, ignore_index=True)
    else:
        print("WARNING: No data passed filtering!")
        return None
    
    feature_names = list(feature_dict.keys())
    Xs = filtered_df[feature_names]
    ys = filtered_df[[block]]
    
    model = LinearRegression().fit(Xs, ys)
    print(f"Coefficients: {model.coef_}")
    print(f"Intercept: {model.intercept_}")
    print(f"R^2 Score: {model.score(Xs, ys)}")
    
    suffix = 'remote' if remote else 'local'
    create_regression_plots(filtered_df, model, feature_names, block, config_name, current_config, suffix)
    
    print("\nSUMMARY STATS")
    print(f"Total points before filtering: {len(result_df)}")
    print(f"Points after filtering: {len(filtered_df)}")
    print(f"Percentage kept: {len(filtered_df)/len(result_df)*100:.1f}%")
    
    if needs_special_processing:
        cleanup_checkpoints(config_name)
    
    return model

def create_regression_plots(filtered_df, model, feature_names, block, config_name, current_config, suffix='local'):
    """Create regression plots for the analysis"""
    config_dir = f'profiling_results/{config_name}'
    os.makedirs(config_dir, exist_ok=True)
    
    if len(feature_names) == 1:
        plt.figure(figsize=(10, 6))
        x_data = filtered_df[feature_names[0]]
        y_data = filtered_df[block]
        plt.scatter(x_data, y_data, alpha=0.7, s=50, label='Data Points')
        
        x_range = np.linspace(x_data.min(), x_data.max(), 100)
        x_range_df = pd.DataFrame({feature_names[0]: x_range})
        y_pred_line = model.predict(x_range_df)
        r2_score = model.score(filtered_df[feature_names], filtered_df[[block]])
        
        plt.plot(x_range, y_pred_line, 'r-', linewidth=2, 
                label=f'Linear fit (R² = {r2_score:.3f})\ny = {model.intercept_[0]:.2e} + {model.coef_[0][0]:.2e}x')
        
        plt.xlabel(feature_names[0])
        plt.ylabel(f'{block} (timing)')
        plt.title(f'{config_name}: {block} vs {feature_names[0]}')
        plt.legend()
        plt.grid(True, alpha=0.3)
        
        plt.savefig(f'{config_dir}/{config_name}_regression_plot_{suffix}.png', dpi=300, bbox_inches='tight')
        plt.close()
    else:
        num_features = len(feature_names)
        fig, axes = plt.subplots(1, num_features, figsize=(6*num_features, 5))
        
        if num_features == 1:
            axes = [axes]
        
        fixed_values = current_config.get('fixed_values', {})
        
        for i, feature in enumerate(feature_names):
            ax = axes[i]
            
            is_product_feature = feature in ['bandchannels', 'num_crosspoints']
            
            if not is_product_feature and feature in fixed_values:
                fix_info = fixed_values[feature]
                fix_for = fix_info['fix_for']
                fixed_vals = fix_info['values']
                
                step = max(1, len(fixed_vals) // 10)
                sampled_vals = fixed_vals[::step]
                
                for fixed_val in sampled_vals:
                    mask = filtered_df[fix_for] == fixed_val
                    if mask.sum() > 1:
                        x_subset = filtered_df[mask][feature]
                        y_subset = filtered_df[mask][block]
                        
                        ax.scatter(x_subset, y_subset, alpha=0.5, label=f'{fix_for}={fixed_val}')
                        
                        if len(x_subset.unique()) > 1:
                            X = x_subset.values.reshape(-1, 1)
                            y = y_subset.values
                            model_fixed = LinearRegression().fit(X, y.reshape(-1, 1))
                            x_range = np.linspace(x_subset.min(), x_subset.max(), 50)
                            y_pred = model_fixed.predict(x_range.reshape(-1, 1))
                            ax.plot(x_range, y_pred, '--', linewidth=1)
            
            elif is_product_feature:
                x_data = filtered_df[feature]
                y_data = filtered_df[block]
                
                if config_name == 'peq' and feature == 'bandchannels':
                    colors = []
                    for idx in range(len(x_data)):
                        bands = filtered_df.iloc[idx]['bands']
                        channels = filtered_df.iloc[idx]['channels']
                        colors.append('blue' if bands > channels else 'red' if channels > bands else 'green')
                else:
                    colors = 'gray'
                
                ax.scatter(x_data, y_data, alpha=0.5, s=30, c=colors)
            else:
                x_data = filtered_df[feature]
                y_data = filtered_df[block]
                ax.scatter(x_data, y_data, alpha=0.7, s=50)
            
            ax.set_xlabel(feature)
            ax.set_ylabel(f'{block} (timing)')
            ax.set_title(f'{feature}')
            ax.grid(True, alpha=0.3)
            ax.yaxis.set_major_formatter(matplotlib.ticker.ScalarFormatter(useMathText=True))
            ax.ticklabel_format(style='scientific', axis='y', scilimits=(0,0))
        
        fig.suptitle(f'{config_name}: {block} vs Features', fontsize=16)
        plt.tight_layout()
        plt.savefig(f'{config_dir}/{config_name}_regression_plots_{suffix}.png', dpi=300, bbox_inches='tight')
        plt.close()

configurations = {
    'agc' : {
        'path' : 'profile_simple_block.json.jinja',
        'algorithm' : 'agc',
        'csv_dump' : 'agc.csv'
    },
    'compressor' : {
        'path' : 'profile_compressor.json.jinja'
    },
    'ducker' : {
        'path' : 'profile_ducker.json.jinja',
        'wav_input' : 'in_ducker_2.wav'
    },
    'feedback_suppression' : {
        'path' : 'profile_simple_block.json.jinja',
        'algorithm' : 'feedback_suppression',
        'wav_input': 'in_feedback.wav',
        'features': {
            'channels': lambda x: x['channels'],
        },
        'block': 'feedback_suppression', 
        'csv_dump': 'feedback_suppression.csv',
        'format_string': 'T = {0} + {1}*channels'
    },
    'gain' : {
        'path' : 'profile_simple_block.json.jinja',
        'algorithm' : 'gain'
    },
    'gate' : {
        'path' : 'profile_gate.json.jinja'
    },
    'graphic_eq' : {
        'path' : 'profile_graphic_eq.json.jinja'
    },
    'limiter' : {
        'path' : 'profile_limiter.json.jinja'
    },
    'matrix_mixer' : {
        'path' : 'profile_matrix_mixer.json.jinja',
        'parameters' : {
            'num_inputs' : range(1, 65, 1),
            'num_outputs' : range(1, 65, 1)
        },
        'features' : {
            'num_inputs' : lambda x: x['num_inputs'],
            'num_outputs' : lambda x: x['num_outputs'],
            'num_crosspoints' : lambda x: x['num_inputs']*x['num_outputs']
        },
        'fixed_values': {
            'num_inputs': { 'fix_for': 'num_outputs', 'values': list(range(1, 65, 1)) },
            'num_outputs': { 'fix_for': 'num_inputs', 'values': list(range(1, 65, 1)) }
        },
        'csv_dump' : 'matrix_mixer_timings.csv',
        'format_string' : 'T = {0} + {1}*num_inputs + {2}*num_outputs + {3}*num_crosspoints'
    },
    'peq' : {
        'path' : 'profile_peq.json.jinja',
        'parameters': {
            'bands': range(1, 41, 1),
            'channels': range(1, 17, 1)
        },
        'features': {
            'bands': lambda x: x['bands'],
            'channels': lambda x: x['channels'],
            'bandchannels': lambda x: x['bands']*x['channels']
        },
        'fixed_values': {
            'bands': { 'fix_for': 'channels', 'values': list(range(1, 17, 1)) },
            'channels': { 'fix_for': 'bands', 'values': list(range(1, 41, 1)) }
        },
        'csv_dump' : 'peq_tmp.csv',
        'format_string' : 'T = {0} + {1}*bands + {2}*channels + {3}*bandchannels'
    },
    'tone' : {
        'path' : 'profile_tone.json.jinja'
    },
    'wav_read' : {
        'path' : 'profile_wav_io.json.jinja',
        'block' : 'wav_read',
        'wav_input' : 'in.wav',
        'parameters' : {},
        'features' : {
            'channels' : lambda x: 1
        },
        'csv_dump' : 'wav_read_timings.csv',
        'format_string' : 'T = {0}'
    },
    'wav_write' : {
        'path' : 'profile_wav_io.json.jinja',
        'block' : 'wav_write',
        'wav_input' : 'in.wav',
        'parameters' : {},
        'features' : {
            'channels' : lambda x: 1
        },
        'csv_dump' : 'wav_write_timings.csv',
        'format_string' : 'T = {0}'
    }
}

default_parameters = {
    'channels' : range(1,17, 3)
}
default_features = {
    'channels': lambda x: x['channels']
}
default_format_string ='T = {0} + {1}*channels'

def dict_to_iter(d):
    p = itertools.product(*d.values())
    return map(
        lambda t: dict(zip(d.keys(), t)),
        p
    )

if __name__ == '__main__':
    import argparse
    
    parser = argparse.ArgumentParser(description='Fusion DSP Algorithm Profiler')
    parser.add_argument('config', nargs='?', help='Configuration to profile (if not specified, runs all)')
    parser.add_argument('--remote', action='store_true', help='Run on remote Variscite board (default behavior)')
    parser.add_argument('--local', action='store_true', help='Run locally on the host machine')
    parser.add_argument('--ip', type=str, default='192.168.1.5', help='IP address of remote Variscite board')
    parser.add_argument('--clock', type=float, default=1500.0, help='Processor clock speed in MHz for remote board')
    
    args = parser.parse_args()
    
    if args.local and args.remote:
        print("Error: Cannot specify both --remote and --local")
        sys.exit(1)
    elif args.local:
        remote = False
    else:
        remote = True  # default is remote
    
    board_ip = args.ip
    board_clock = args.clock
    
    if remote:
        print(f"Using remote board at {board_ip} with clock {board_clock} MHz")
    
    mode_str = "REMOTE BOARD" if remote else "LOCAL"
    print(f"Running in {mode_str} mode")
    
    os.makedirs('profiling_results', exist_ok=True)
    
    if args.config is None:
        results = {}
        suffix = "_remote" if remote else "_local"
        
        for config in configurations.keys():
            print(f'\n{"="*60}')
            print(f'Running profiling configuration: {config}')
            print(f'{"="*60}')
            model = results[config] = profile(config, remote=remote, board_ip=board_ip, board_clock=board_clock)
            if model:
                config_dir = f'profiling_results/{config}'
                os.makedirs(config_dir, exist_ok=True)

                try:
                    with open(f'{config_dir}/results_{config}{suffix}.pkl', 'wb') as pf:
                        pickle.dump(model, pf)
                    print(f"Saved model pickle: {config_dir}/results_{config}{suffix}.pkl")
                except Exception as e:
                    print(f"Failed to save model pickle for {config}: {e}")

                try:
                    with open(f'{config_dir}/results_{config}{suffix}.txt', 'w') as f:
                        f.write(f"\n{'='*60}\n")
                        f.write(f"Configuration: {config.upper()}\n")
                        f.write("Main Regression Formula:\n")
                        f.write("=" * 50 + "\n")

                        intercepts = list(np.ravel(model.intercept_)) if hasattr(model, 'intercept_') else []
                        coefs = list(np.ravel(model.coef_)) if hasattr(model, 'coef_') else []
                        format_values = intercepts + coefs

                        try:
                            main_formula = configurations[config].get('format_string', default_format_string).format(*format_values)
                        except Exception as fe:
                            main_formula = f"Could not format formula: {fe}"

                        f.write(main_formula + "\n\n")
                except Exception as e:
                    print(f"Failed to write results txt for {config}: {e}")
        
        with open(f'profiling_results/all_results{suffix}.pkl', 'wb') as f:
            pickle.dump(results, f)
        
    else:
        config = args.config
        suffix = "_remote" if remote else "_local"
        
        print(f'\n{"="*60}')
        print(f'Running profiling configuration: {config}')
        print(f'{"="*60}')
        
        model = profile(config, remote=remote, board_ip=board_ip, board_clock=board_clock)
        
        if model:
            if config not in ['matrix_mixer', 'peq']:
                config_dir = f'profiling_results/{config}'
                os.makedirs(config_dir, exist_ok=True)
                
                with open(f'{config_dir}/results_{config}{suffix}.pkl', 'wb') as f:
                    pickle.dump(model, f)
                
                with open(f'{config_dir}/results_{config}{suffix}.txt', 'w') as f:
                    f.write(f"Configuration: {config.upper()}\n")
                    f.write("Main Regression Formula:\n")
                    f.write("=" * 50 + "\n")
                    f.write(
                        configurations[config].get('format_string', default_format_string).format(*model.intercept_, *model.coef_[0])
                        + "\n\n"
                    )