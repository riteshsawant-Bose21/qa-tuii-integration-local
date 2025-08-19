import pandas as pd
import jinja2 as jinja2
import itertools
import pickle
import sys
import os
import platform
import subprocess
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from sklearn.linear_model import LinearRegression
from subprocess import run

processor_speed_mhz = 1800.0
sample_rate = 48000

def convert_mips_to_time(mips_value, processor_speed_mhz=processor_speed_mhz,
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

def profile(config_name, remote=True):
    """
    Profile a specific config locally or remotely on a Variscite board.
    
    Args:
        config_name (str): The name of the configuration to profile.
        remote (bool): If True, runs the profiling on a remote Variscite board via SSH.
                                If False, runs locally on detected OS (assumed to be Linux or macOS).
    """
    board_ip = "192.168.1.7" # Change this to your board's IP address; only for remote=True (default)
    loader = jinja2.FileSystemLoader("./config/profiling")
    env = jinja2.Environment(loader=loader, autoescape=jinja2.select_autoescape())
    current_config = configurations[config_name]
    template = env.get_template(current_config['path'])
    
    frames = []
    analysis_mips_data = []

    params_iter = dict_to_iter(current_config.get('parameters', default_parameters))
    feature_dict = current_config.get('features', default_features)

    for param_dict in params_iter:
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
                        analysis_thread_time = convert_mips_to_time(mips_value=mips_avg)
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
            run(['./build/fusion_dsp','-c', 'tmp.json'],
                env=env
                )
            
        try:
            df = pd.read_csv('timings.csv')
            
            for param_name, param_value in param_dict.items():
                df[param_name] = param_value
            
            for feature, formula in feature_dict.items():
                if feature != 'analysis_avg':
                    df[feature] = formula(param_dict)
            
            frames.append(df)
        except Exception as e:
            print(f"Error reading timings.csv: {e}")
            continue
    
    result_df = pd.concat(frames, axis=0, ignore_index=True)
    
    block = current_config.get(
            'block',
            config_name
        )
    # force any type errors (caused by disk space) to NaN 
    numeric_columns = [block, 'task1', 'matrix_mixer', 'outfile']
    for i in range(1, 58):
        col_name = f'infile{i}'
        if col_name in result_df.columns:
            numeric_columns.append(col_name)

    for col in numeric_columns:
        if col in result_df.columns:
            before = len(result_df)
            result_df[col] = pd.to_numeric(result_df[col], errors='coerce')
            after = result_df[col].notna().sum()
            if before != after:
                print(f"WARNING: {col} had {before - after} non-numeric values")

    result_df = result_df.dropna(subset=[block])
    print(f"Rows after cleaning mixed data types: {len(result_df)}") 

    if config_name == 'feedback_suppression':
        if analysis_mips_data:
            for mips_entry in analysis_mips_data:
                ch = mips_entry['channels']
                mask = result_df['channels'] == ch
                
                # DEBUG:
                original_main = result_df.loc[mask, block].mean()
                
                result_df.loc[mask, 'analysis_avg'] = mips_entry['analysis_avg']
                result_df.loc[mask, 'analysis_time'] = mips_entry['analysis_time']
                
                result_df.loc[mask, block] = (
                    result_df.loc[mask, block] + mips_entry['analysis_time']
                )
                
                # DEBUG: 
                new_total = result_df.loc[mask, block].mean()
                print(f"Channel {ch}:")
                print(f"  Original main thread: {original_main:.2e}")
                print(f"  Analysis thread: {mips_entry['analysis_time']:.2e}")
                print(f"  New total: {new_total:.2e}")
                print(f"  Expected: {original_main + mips_entry['analysis_time']:.2e}")

    print(result_df.columns.tolist())
    print(result_df.head())
    
    if remote:
        print("Copying out.wav from board...")
        os.system(f'scp root@{board_ip}:/home/root/out.wav ./out.wav')
        print("Cleaning up out.wav file...")
        os.system(f'ssh root@{board_ip} "rm -f /home/root/out.wav"')
    
    if current_config.get('csv_dump'):
        os.makedirs('profiling_results', exist_ok=True)
        result_df.to_csv(f"profiling_results/{current_config['csv_dump']}")

    # Identify all parameter columns
    params_dict = current_config.get('parameters', default_parameters)
    param_columns = list(params_dict.keys())
    
    existing_param_cols = [col for col in param_columns if col in result_df.columns]
    
    filtered_df = []
    
    if len(existing_param_cols) == 0:
        print("No parameter columns found, using overall quantiles")
        low_quantile = result_df.quantile(0.999)[block]
        high_quantile = result_df.quantile(0.9999)[block]
        filtered_df = [result_df[
            (result_df[block] >= low_quantile) &
            (result_df[block] <= high_quantile)
        ]]
        print(f"Low quantile: {low_quantile}, High quantile: {high_quantile}")
        print(f"Total points before filtering: {len(result_df)}, Points after filtering: {len(filtered_df[0])} ({len(filtered_df[0])/len(result_df)*100:.1f}%)")
    
    elif len(existing_param_cols) == 1:
        filter_column = existing_param_cols[0]
        print(f"Filtering by single parameter: {filter_column}")
        
        for group_value in sorted(result_df[filter_column].unique()):
            ch_df = result_df[result_df[filter_column] == group_value]
            ch_df[block] = pd.to_numeric(ch_df[block], errors='coerce')
            ch_df = ch_df.dropna(subset=[block])
            
            try:
                low_quantile = ch_df.quantile(0.999)[block]
                high_quantile = ch_df.quantile(0.9999)[block]
                filtered_ch = ch_df[
                    (ch_df[block] >= low_quantile) &
                    (ch_df[block] <= high_quantile)
                ]
                filtered_df.append(filtered_ch)
                print(f"{filter_column}={group_value}: Low={low_quantile:.2e}, High={high_quantile:.2e}")
                print(f"  Points: {len(ch_df)} → {len(filtered_ch)} ({len(filtered_ch)/len(ch_df)*100:.1f}%)")
            except Exception as e:
                print(f"Error processing {filter_column}={group_value}: {e}")
                continue
    
    else:
            print(f"Filtering by parameter combinations: {existing_param_cols}")
            param_combinations = result_df[existing_param_cols].drop_duplicates()
            
            for idx, row in param_combinations.iterrows():
                mask = pd.Series([True] * len(result_df))
                param_str = []
                for col in existing_param_cols:
                    mask = mask & (result_df[col] == row[col])
                    param_str.append(f"{col}={row[col]}")
                
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
                        print(f"{', '.join(param_str)}: Low={low_quantile:.2e}, High={high_quantile:.2e}")
                        print(f"  Points: {len(combo_df)} → {len(filtered_combo)} ({len(filtered_combo)/len(combo_df)*100:.1f}%)")
                    except Exception as e:
                        print(f"Error processing combination {', '.join(param_str)}: {e}")
                        continue
    
    # Concatenate all filtered groups
    if len(filtered_df) > 0:
        filtered_df = pd.concat(filtered_df, ignore_index=True)
    else:
        print("WARNING: No data passed filtering!")
        filtered_df = pd.DataFrame()
        return None

    Xs = filtered_df[list(feature_dict.keys())]
    ys = filtered_df[[block]]

    model = LinearRegression().fit(Xs, ys)
    print(f"Coefficients: {model.coef_}")
    print(f"Intercept:{model.intercept_}")
    print(f"R^2 Score: {model.score(Xs, ys)}")
    
    feature_names = list(feature_dict.keys())
    print(f"Feature names: {feature_names} - {len(feature_names)} features")
    if len(feature_names) == 1:
        plt.figure(figsize=(10, 6))
        x_data = Xs.iloc[:, 0]
        y_data = ys.iloc[:, 0]
        plt.scatter(x_data, y_data, alpha=0.7, s=50, label='Data Points')
        
        x_range = np.linspace(x_data.min(), x_data.max(), 100)
        
        x_range_df = pd.DataFrame({feature_names[0]: x_range})
        y_pred_line = model.predict(x_range_df)
        plt.plot(x_range, y_pred_line, 'r-', linewidth=2, 
                label=f'Linear fit: y = {model.intercept_[0]:.2e} + {model.coef_[0][0]:.2e}x')
        
        plt.xlabel(feature_names[0])
        plt.ylabel(f'{block} (timing)')
        plt.title(f'{config_name}: {block} vs {feature_names[0]}')
        plt.legend()
        plt.grid(True, alpha=0.3)
        
        os.makedirs('profiling_results', exist_ok=True)
        plt.savefig(f'profiling_results/{config_name}_regression_plot.png', dpi=300, bbox_inches='tight')
        print(f"Plot saved to: profiling_results/{config_name}_regression_plot.png")
        plt.close()
        
    else:
            # for multiple features - plots with fixed parameters where configured
            num_features = len(feature_names)
            fig, axes = plt.subplots(1, num_features, figsize=(6*num_features, 5))
            
            if num_features == 1:
                axes = [axes]
            
            fixed_values = current_config.get('fixed_values', {})
            
            for i, feature in enumerate(feature_names):
                ax = axes[i]
                
                # if this is a product feature (bandchannels or num_crosspoints) so we use all the datapoints
                is_product_feature = feature in ['bandchannels', 'num_crosspoints']
                
                if is_product_feature:
                    x_data = Xs.iloc[:, i]
                    y_data = ys.iloc[:, 0]
                    ax.scatter(x_data, y_data, alpha=0.5, s=30, label='All data points')
                    
                    x_range = np.linspace(x_data.min(), x_data.max(), 100)
                    x_range_df = pd.DataFrame(index=range(len(x_range)))  
                    for j, feat in enumerate(feature_names):
                        if feat == feature:
                            x_range_df[feat] = x_range
                        else:
                            median_val = Xs.iloc[:, j].median()
                            if pd.isna(median_val):
                                print(f"WARNING: Median for {feat} is NaN, using mean instead")
                                median_val = Xs.iloc[:, j].mean()
                                if pd.isna(median_val):
                                    print(f"ERROR: Both median and mean for {feat} are NaN, using 0")
                                    median_val = 0
                            x_range_df[feat] = median_val
                    
                    y_pred_line = model.predict(x_range_df)
                    coeff = model.coef_[0][i]
                    ax.plot(x_range, y_pred_line, 'r-', linewidth=2,
                           label=f'Coefficient: {coeff:.2e}')
                    ax.set_title(f'{config_name}: {block} vs {feature}')
                    
                else:
                    # For individual features, check if should fix other parameters
                    if feature in fixed_values:
                        fix_info = fixed_values[feature]
                        other_param = fix_info['fix_for']
                        fixed_value = fix_info['value']
                        
                        if other_param in filtered_df.columns:
                            mask = filtered_df[other_param] == fixed_value
                            filtered_indices = filtered_df[mask].index
                            
                            x_data_filtered = Xs.loc[Xs.index.isin(filtered_indices), feature]
                            y_data_filtered = ys.loc[ys.index.isin(filtered_indices)].iloc[:, 0]
                            
                            if len(x_data_filtered) == 0:
                                # Fall back to showing all data 
                                x_data = Xs.iloc[:, i]
                                y_data = ys.iloc[:, 0]
                                ax.scatter(x_data, y_data, alpha=0.7, s=50, label='All data points')
                                ax.set_title(f'{config_name}: {block} vs {feature}\n(No data for {other_param}={fixed_value})')
                            else:
                                ax.scatter(x_data_filtered, y_data_filtered, alpha=0.7, s=50, 
                                         label=f'Data points ({other_param}={fixed_value})')
                                
                                # create regression line for this subset
                                x_range = np.linspace(x_data_filtered.min(), x_data_filtered.max(), 100)
                                
                                x_range_df = pd.DataFrame(index=range(len(x_range)))  
                                for j, feat in enumerate(feature_names):
                                    if feat == feature:
                                        x_range_df[feat] = x_range
                                    elif feat == other_param:
                                        x_range_df[feat] = fixed_value
                                    elif feat in ['bandchannels', 'num_crosspoints']:
                                        if config_name == 'peq' and feat == 'bandchannels':
                                            if feature == 'bands':
                                                x_range_df[feat] = x_range * fixed_value  # bands * fixed_channels
                                            else:  # feature == 'channels'
                                                x_range_df[feat] = fixed_value * x_range  # fixed_bands * channels
                                        elif config_name == 'matrix_mixer' and feat == 'num_crosspoints':
                                            if feature == 'num_inputs':
                                                x_range_df[feat] = x_range * fixed_value  # inputs * fixed_outputs
                                            else:  # feature == 'num_outputs'
                                                x_range_df[feat] = fixed_value * x_range  # fixed_inputs * outputs
                                        else:
                                            # fallback
                                            x_range_df[feat] = Xs[feat].median()
                                    else:
                                        filtered_subset = Xs.loc[Xs.index.isin(filtered_indices), feat]
                                        median_val = filtered_subset.median()
                                        if pd.isna(median_val):
                                            median_val = filtered_subset.mean()
                                            if pd.isna(median_val):
                                                median_val = Xs[feat].median()
                                        x_range_df[feat] = median_val
                                
                                y_pred_line = model.predict(x_range_df)
                                coeff = model.coef_[0][i]
                                ax.plot(x_range, y_pred_line, 'r-', linewidth=2,
                                       label=f'Coefficient: {coeff:.2e}')
                                
                                ax.set_title(f'{config_name}: {block} vs {feature}\n(with {other_param}={fixed_value})')
                        else:
                            # Fallback
                            x_data = Xs.iloc[:, i]
                            y_data = ys.iloc[:, 0]
                            ax.scatter(x_data, y_data, alpha=0.7, s=50, label='Data Points')
                            ax.set_title(f'{config_name}: {block} vs {feature}')
                    else:
                        # No fixed value config, use original behavior
                        x_data = Xs.iloc[:, i]
                        y_data = ys.iloc[:, 0]
                        ax.scatter(x_data, y_data, alpha=0.7, s=50, label='Data Points')
                        
                        # regression line logic with NaN checking
                        x_range = np.linspace(x_data.min(), x_data.max(), 100)
                        x_range_df = pd.DataFrame(index=range(len(x_range))) 
                        for j, feat in enumerate(feature_names):
                            if j == i:  
                                x_range_df[feat] = x_range
                            else:
                                median_val = Xs.iloc[:, j].median()
                                if pd.isna(median_val):
                                    print(f"WARNING: Median for {feat} is NaN, using mean instead")
                                    median_val = Xs.iloc[:, j].mean()
                                    if pd.isna(median_val):
                                        print(f"ERROR: Both median and mean for {feat} are NaN, using 0")
                                        median_val = 0
                                x_range_df[feat] = median_val
                        
                        y_pred_line = model.predict(x_range_df)
                        coeff = model.coef_[0][i]
                        ax.plot(x_range, y_pred_line, 'r-', linewidth=2,
                               label=f'Partial fit: {coeff:.2e}')
                        ax.set_title(f'{config_name}: {block} vs {feature}')
                
                ax.set_xlabel(feature)
                ax.set_ylabel(f'{block} (timing)')
                ax.legend()
                ax.grid(True, alpha=0.3)
            
            fig.suptitle(f'{config_name}: {block} vs Features', fontsize=16)
            plt.tight_layout()
            os.makedirs('profiling_results', exist_ok=True)
            plt.savefig(f'profiling_results/{config_name}_regression_plots.png', dpi=300, bbox_inches='tight')
            print(f"Plot saved to: profiling_results/{config_name}_regression_plots.png")
            plt.close()
            
            equation_parts = [f"{model.intercept_[0]:.2e}"]
            for i, feature in enumerate(feature_names):
                coeff = model.coef_[0][i]
                equation_parts.append(f"{coeff:.2e}*{feature}")
            full_equation = " + ".join(equation_parts)
            print(f"Full equation: y = {full_equation}")
            
    print("SUMMARY STATS")
    print(f"Total points before filtering: {len(result_df)}")
    print(f"Points after filtering: {len(filtered_df)}")
    print(f"Percentage kept: {len(filtered_df)/len(result_df)*100:.1f}%")
    
    return model
    
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
            'num_inputs' : range(1, 60, 8),
            'num_outputs' : range(1, 33, 6)
        },
        'features' : {
            'num_inputs' : lambda x: x['num_inputs'],
            'num_outputs' : lambda x: x['num_outputs'],
            'num_crosspoints' : lambda x: x['num_inputs']*x['num_outputs']
        },
        'fixed_values': { # These must be values already included in feature parameters.
            'num_inputs' : { 'fix_for': 'num_outputs', 'value' : 19 }, # When varying num_inputs, fix num_outputs at 19
            'num_outputs' : { 'fix_for': 'num_inputs', 'value' : 33 } # When varying num_outputs, fix num_inputs at 33
        },
        'csv_dump' : 'matrix_mixer_timings.csv',
        'format_string' : 'T = {0} + {1}*num_inputs*num_outputs'
    },
    'passthrough' : {
        'path' : 'profile_passthrough.json.jinja',
        'block' : 'task1',
    },
    'peq' : {
        'path' : 'profile_peq.json.jinja',
        'parameters': {
            'bands': range(5, 38, 4),
            'channels': range(1, 17, 3)
        },
        'features': {
            'bands': lambda x: x['bands'],
            'channels': lambda x: x['channels'],
            'bandchannels': lambda x: x['bands']*x['channels']
        },
        'fixed_values': { # These must be values already included in feature parameters.
            'bands' : { 'fix_for': 'channels', 'value' : 7 }, # When varying bands, fix channels at 5
            'channels' : { 'fix_for': 'bands', 'value' : 21 } # When varying channels, fix bands at 21
        },
        'csv_dump' : 'peq_tmp.csv',
        'format_string' : 'T = {0} + {1}*bands*channels'
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
    
    args = parser.parse_args()
    
    if args.local and args.remote:
        print("Error: Cannot specify both --remote and --local")
        sys.exit(1)
    elif args.local:
        remote = False
    else:
        remote = True  # default is remote
    
    mode_str = "REMOTE BOARD" if remote else "LOCAL"
    print(f"Running in {mode_str} mode")
    
    os.makedirs('profiling_results', exist_ok=True)
    
    if args.config is None:
        results = {}
        suffix = "_remote" if remote else "_local"
        f_model_readable = open(f'profiling_results/results{suffix}.txt', 'w')
        
        for config in configurations.keys():
            print(f'Running profiling configuration: {config}')
            model = results[config] = profile(config, remote=remote)
            if model:
                f_model_readable.write(
                    f'{config} : ' +
                    configurations[config].get('format_string', default_format_string).format(*model.intercept_, *model.coef_[0])
                    + '\n'
                )
        
        f_model_pickle = open(f'profiling_results/results{suffix}.pkl', 'wb')
        pickle.dump(results, f_model_pickle)
        f_model_pickle.close()
        f_model_readable.close()
        
    else:
        config = args.config
        suffix = "_remote" if remote else "_local"
        f_model_pickle = open(f'profiling_results/results_{config}{suffix}.pkl', 'wb')
        f_model_readable = open(f'profiling_results/results_{config}{suffix}.txt', 'w')
        
        model = profile(config, remote=remote)
        if model:
            pickle.dump(model, f_model_pickle)
            f_model_readable.write(
                configurations[config].get('format_string', default_format_string).format(*model.intercept_, *model.coef_[0])
            )
        f_model_pickle.close()
        f_model_readable.close()