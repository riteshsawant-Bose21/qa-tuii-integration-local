import pandas as pd
import glob
import os
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from sklearn.linear_model import LinearRegression
import pickle
import re

CONFIG_DEFINITIONS = {
    'matrix_mixer': {
        'file_pattern': 'timings_mm_*_*_processed.csv',
        'checkpoint_pattern': 'timings_mm_*_*_processed.csv',
        'param_regex': r'timings_mm_(\d+)_(\d+)_processed',
        'param_names': ['num_inputs', 'num_outputs'],
        'features': ['num_inputs', 'num_outputs', 'num_crosspoints'],
        'block': 'matrix_mixer',
        'max_params': [(64, 64)],
        'format_string': 'T = {0} + {1}*num_inputs + {2}*num_outputs + {3}*num_crosspoints'
    },
    'peq': {
        'file_pattern': 'timings_peq_*_*_processed.csv',
        'checkpoint_pattern': 'timings_peq_*_*_processed.csv',
        'param_regex': r'timings_peq_(\d+)_(\d+)_processed',
        'param_names': ['bands', 'channels'],
        'features': ['bands', 'channels', 'bandchannels'],
        'block': 'peq',
        'max_params': [(40, 16)],
        'format_string': 'T = {0} + {1}*bands + {2}*channels + {3}*bandchannels'
    }
}

def process_files_in_batches(config_name='matrix_mixer', batch_size=100):
    """
    Process checkpoint files in small batches and save intermediate results to disk.
    
    Args:
        config_name: Configuration name ('matrix_mixer', 'peq', etc.)
        batch_size: Number of files to process per batch
    """
    config = CONFIG_DEFINITIONS.get(config_name)
    if not config:
        print(f"Configuration '{config_name}' not supported")
        return False
    
    print(f"\n{'='*60}")
    print(f"PROCESSING {config_name.upper()} DATA IN BATCHES")
    print(f"{'='*60}")
    
    checkpoint_dir = f'profiling_results/{config_name}_checkpoints'
    if os.path.exists(checkpoint_dir):
        pattern = f"{checkpoint_dir}/{config['checkpoint_pattern']}"
        processed_files = glob.glob(pattern)
        print(f"Using checkpoint files from: {checkpoint_dir}")
    else:
        print(f"No checkpoint directory found at: {checkpoint_dir}")
        return False
    
    print(f"Found {len(processed_files)} files matching pattern: {pattern}")
    print(f"Processing in batches of {batch_size} files")
    
    if not processed_files:
        print("No files found!")
        return False
    
    temp_dir = f'profiling_results/{config_name}_temp_batches'
    os.makedirs(temp_dir, exist_ok=True)
    
    batch_num = 0
    param_regex = config['param_regex']
    param_names = config['param_names']
    block_name = config['block']
    
    for i in range(0, len(processed_files), batch_size):
        batch_files = processed_files[i:i+batch_size]
        batch_frames = []
        
        print(f"\nProcessing batch {batch_num + 1} (files {i+1} to {min(i+batch_size, len(processed_files))})")
        
        for file in batch_files:
            try:
                df = pd.read_csv(file)
                
                filename = os.path.basename(file)
                match = re.search(param_regex, filename)
                
                if match:
                    for idx, param_name in enumerate(param_names):
                        if param_name not in df.columns:
                            df[param_name] = int(match.group(idx + 1))
                
                if config_name == 'matrix_mixer':
                    if 'num_crosspoints' not in df.columns:
                        df['num_crosspoints'] = df['num_inputs'] * df['num_outputs']
                elif config_name == 'peq':
                    if 'bandchannels' not in df.columns:
                        df['bandchannels'] = df['bands'] * df['channels']
                
                if block_name in df.columns:
                    block_values = pd.to_numeric(df[block_name], errors='coerce')
                    df = df[~block_values.isna()]
                    
                    if len(df) > 0:
                        low_q = df[block_name].quantile(0.999)
                        high_q = df[block_name].quantile(0.9999)
                        df = df[(df[block_name] >= low_q) & (df[block_name] <= high_q)]
                        batch_frames.append(df)
                
            except Exception as e:
                print(f"Error loading {file}: {e}")
                continue
        
        if batch_frames:
            batch_df = pd.concat(batch_frames, ignore_index=True)
            batch_file = f"{temp_dir}/batch_{batch_num:04d}.parquet"
            batch_df.to_parquet(batch_file)
            print(f"Saved batch {batch_num + 1} with {len(batch_df)} rows to {batch_file}")
            batch_num += 1
            
            del batch_frames, batch_df
    
    print(f"\nSaved {batch_num} batch files to {temp_dir}")
    return True

def calculate_all_regression_formulas(config_name='matrix_mixer'):
    """
    Calculate regression formulas for ALL parameter combinations from batch files.
    """
    config = CONFIG_DEFINITIONS.get(config_name)
    if not config:
        print(f"Configuration '{config_name}' not supported")
        return []
    
    temp_dir = f'profiling_results/{config_name}_temp_batches'
    batch_files = sorted(glob.glob(f"{temp_dir}/batch_*.parquet"))
    
    if not batch_files:
        print("No batch files found for calculating individual formulas")
        return []
    
    print("\nCalculating individual regression formulas for all combinations...")
    
    combination_data = {}
    param_names = config['param_names']
    block_name = config['block']
    
    for batch_file in batch_files:
        df = pd.read_parquet(batch_file)
        
        if len(param_names) == 2:
            for (p1, p2), group in df.groupby(param_names):
                key = (int(p1), int(p2))
                if key not in combination_data:
                    combination_data[key] = []
                
                cols_to_keep = param_names + config['features'] + [block_name]
                combination_data[key].append(group[cols_to_keep])
        
        del df
    
    regression_formulas = []
    
    all_keys = list(combination_data.keys())
    if all_keys and config_name in ['matrix_mixer', 'peq']:
        actual_max_p1 = max(k[0] for k in all_keys)
        actual_max_p2 = max(k[1] for k in all_keys)
        actual_min_p1 = min(k[0] for k in all_keys)
        actual_min_p2 = min(k[1] for k in all_keys)
    else:
        actual_max_p1, actual_max_p2 = config['max_params'][0]
        actual_min_p1 = actual_min_p2 = 1
    
    if config_name == 'matrix_mixer':
        for fixed_output in range(actual_min_p2, actual_max_p2 + 1):
            x_data = []
            y_data = []
            
            for inp in range(actual_min_p1, actual_max_p1 + 1):
                key = (inp, fixed_output)
                if key in combination_data:
                    combo_df = pd.concat(combination_data[key])
                    x_data.extend([inp] * len(combo_df))
                    y_data.extend(combo_df[block_name].values)
            
            if len(x_data) > 1 and len(set(x_data)) > 1:
                X = np.array(x_data).reshape(-1, 1)
                y = np.array(y_data)
                model = LinearRegression().fit(X, y)
                r2 = model.score(X, y)
                
                regression_formulas.append({
                    'feature': param_names[0],
                    'fixed_param': param_names[1],
                    'fixed_value': fixed_output,
                    'intercept': model.intercept_,
                    'coefficient': model.coef_[0],
                    'r2': r2
                })
        
        for fixed_input in range(actual_min_p1, actual_max_p1 + 1):
            x_data = []
            y_data = []
            
            for outp in range(actual_min_p2, actual_max_p2 + 1):
                key = (fixed_input, outp)
                if key in combination_data:
                    combo_df = pd.concat(combination_data[key])
                    x_data.extend([outp] * len(combo_df))
                    y_data.extend(combo_df[block_name].values)
            
            if len(x_data) > 1 and len(set(x_data)) > 1:
                X = np.array(x_data).reshape(-1, 1)
                y = np.array(y_data)
                model = LinearRegression().fit(X, y)
                r2 = model.score(X, y)
                
                regression_formulas.append({
                    'feature': param_names[1],
                    'fixed_param': param_names[0],
                    'fixed_value': fixed_input,
                    'intercept': model.intercept_,
                    'coefficient': model.coef_[0],
                    'r2': r2
                })
    
    elif config_name == 'peq':
        for fixed_channel in range(actual_min_p2, actual_max_p2 + 1):
            x_data = []
            y_data = []
            
            for band in range(actual_min_p1, actual_max_p1 + 1):
                key = (band, fixed_channel)
                if key in combination_data:
                    combo_df = pd.concat(combination_data[key])
                    x_data.extend([band] * len(combo_df))
                    y_data.extend(combo_df[block_name].values)
            
            if len(x_data) > 1 and len(set(x_data)) > 1:
                X = np.array(x_data).reshape(-1, 1)
                y = np.array(y_data)
                model = LinearRegression().fit(X, y)
                r2 = model.score(X, y)
                
                regression_formulas.append({
                    'feature': 'bands',
                    'fixed_param': 'channels',
                    'fixed_value': fixed_channel,
                    'intercept': model.intercept_,
                    'coefficient': model.coef_[0],
                    'r2': r2
                })
        
        for fixed_band in range(actual_min_p1, actual_max_p1 + 1):
            x_data = []
            y_data = []
            
            for channel in range(actual_min_p2, actual_max_p2 + 1):
                key = (fixed_band, channel)
                if key in combination_data:
                    combo_df = pd.concat(combination_data[key])
                    x_data.extend([channel] * len(combo_df))
                    y_data.extend(combo_df[block_name].values)
            
            if len(x_data) > 1 and len(set(x_data)) > 1:
                X = np.array(x_data).reshape(-1, 1)
                y = np.array(y_data)
                model = LinearRegression().fit(X, y)
                r2 = model.score(X, y)
                
                regression_formulas.append({
                    'feature': 'channels',
                    'fixed_param': 'bands',
                    'fixed_value': fixed_band,
                    'intercept': model.intercept_,
                    'coefficient': model.coef_[0],
                    'r2': r2
                })
    
    print(f"Calculated {len(regression_formulas)} individual regression formulas")
    return regression_formulas

def perform_incremental_regression(config_name='matrix_mixer', calculate_all_formulas=True, suffix='local'):
    """
    Perform regression using batch files without loading all data at once.
    """
    output_dir = f'profiling_results/{config_name}'
    os.makedirs(output_dir, exist_ok=True)
    
    config = CONFIG_DEFINITIONS.get(config_name)
    if not config:
        print(f"Configuration '{config_name}' not supported")
        return None
    
    temp_dir = f'profiling_results/{config_name}_temp_batches'
    batch_files = sorted(glob.glob(f"{temp_dir}/batch_*.parquet"))
    
    if not batch_files:
        print(f"No batch files found! Run with --process-batches first")
        return None
    
    print(f"\n{'='*60}")
    print(f"PERFORMING INCREMENTAL REGRESSION FOR {config_name.upper()}")
    print(f"{'='*60}")
    print(f"Found {len(batch_files)} batch files")
    
    feature_names = config['features']
    n_features = len(feature_names)
    block_name = config['block']
    
    n = 0
    sum_x = np.zeros(n_features)
    sum_y = 0
    sum_xx = np.zeros((n_features, n_features))
    sum_xy = np.zeros(n_features)
    sum_yy = 0
    
    print("\nPass 1: Calculating statistics...")
    for i, batch_file in enumerate(batch_files):
        print(f"Processing batch {i+1}/{len(batch_files)}")
        df = pd.read_parquet(batch_file)
        
        if config_name == 'matrix_mixer' and 'num_crosspoints' not in df.columns:
            df['num_crosspoints'] = df['num_inputs'] * df['num_outputs']
        elif config_name == 'peq' and 'bandchannels' not in df.columns:
            df['bandchannels'] = df['bands'] * df['channels']
        
        X = df[feature_names].values
        y = df[block_name].values
        
        batch_n = len(df)
        n += batch_n
        sum_x += np.sum(X, axis=0)
        sum_y += np.sum(y)
        sum_xx += X.T @ X
        sum_xy += X.T @ y
        sum_yy += y @ y
        
        del df
    
    mean_x = sum_x / n
    mean_y = sum_y / n
    
    cov_xx = sum_xx / n - np.outer(mean_x, mean_x)
    cov_xy = sum_xy / n - mean_x * mean_y
    
    try:
        coef = np.linalg.solve(cov_xx, cov_xy)
        intercept = mean_y - np.dot(mean_x, coef)
        
        ss_tot = sum_yy / n - mean_y ** 2
        ss_res = ss_tot - np.dot(cov_xy, coef)
        r2_score = 1 - (ss_res / ss_tot) if ss_tot > 0 else 0
        
    except np.linalg.LinAlgError:
        print("Warning: Singular matrix, using pseudoinverse")
        coef = np.linalg.pinv(cov_xx) @ cov_xy
        intercept = mean_y - np.dot(mean_x, coef)
        r2_score = 0
    
    print(f"\nRegression Results:")
    print(f"Total data points: {n:,}")
    print(f"Coefficients: {coef}")
    print(f"Intercept: {intercept}")
    print(f"R^2 Score: {r2_score:.4f}")
    
    equation_parts = [f"{intercept:.2e}"]
    for i, feature in enumerate(feature_names):
        equation_parts.append(f"{coef[i]:.2e}*{feature}")
    full_equation = " + ".join(equation_parts)
    print(f"Full equation: y = {full_equation}")
    
    model = LinearRegression()
    model.coef_ = coef.reshape(1, -1)
    model.intercept_ = np.array([intercept])
    
    print("\nPass 2: Creating plots with sampled data...")
    
    plot_data = []
    sample_interval = max(1, len(batch_files) // 20)
    
    for i in range(0, len(batch_files), sample_interval):
        df = pd.read_parquet(batch_files[i])
        
        if config_name == 'matrix_mixer' and 'num_crosspoints' not in df.columns:
            df['num_crosspoints'] = df['num_inputs'] * df['num_outputs']
        elif config_name == 'peq' and 'bandchannels' not in df.columns:
            df['bandchannels'] = df['bands'] * df['channels']
        
        df_sample = df.sample(frac=0.1, random_state=42) if len(df) > 10 else df
        plot_data.append(df_sample)
        del df
    
    plot_df = pd.concat(plot_data, ignore_index=True)
    print(f"Using {len(plot_df):,} sampled points for plotting")
    
    plot_regression_formulas = create_plots(plot_df, model, config, feature_names, config_name, suffix)
    
    if calculate_all_formulas:
        all_regression_formulas = calculate_all_regression_formulas(config_name)
    else:
        all_regression_formulas = plot_regression_formulas
    
    with open(f'{output_dir}/results_{config_name}_{suffix}.pkl', 'wb') as f:
        pickle.dump(model, f)
    
    with open(f'{output_dir}/results_{config_name}_{suffix}.txt', 'w') as f:
        f.write(f"Configuration: {config_name.upper()}\n")
        f.write("Main Regression Formula:\n")
        f.write("=" * 50 + "\n")
        main_formula = config['format_string'].format(intercept, *coef)
        f.write(main_formula + "\n\n")
        f.write(f"Based on {n:,} data points from {len(batch_files)} batches\n")
        f.write(f"R² Score: {r2_score:.4f}\n\n")
        
        if all_regression_formulas:
            write_individual_formulas(f, all_regression_formulas, config_name)
    
    print(f"\nResults written to: {output_dir}/results_{config_name}_{suffix}.txt")
    
    return model

def write_individual_formulas(file_handle, regression_formulas, config_name):
    """Write individual regression formulas to file."""
    feature_formulas = {}
    for formula in regression_formulas:
        if formula['feature'] not in feature_formulas:
            feature_formulas[formula['feature']] = []
        feature_formulas[formula['feature']].append(formula)
    
    product_features = ['num_crosspoints', 'bandchannels']
    
    for feature, formulas in feature_formulas.items():
        if feature in product_features:
            continue
        
        file_handle.write(f"\n{feature.upper()} Regression Formulas:\n")
        file_handle.write("=" * 50 + "\n")
        
        for formula in sorted(formulas, key=lambda x: x.get('fixed_value', 0)):
            fixed_param = formula.get('fixed_param')
            fixed_value = formula.get('fixed_value')
            file_handle.write(
                f"{fixed_param} = {fixed_value}:\n"
                f"T = {formula['intercept']:.2e} + {formula['coefficient']:.2e}*{feature}"
                f" (R² = {formula['r2']:.3f})\n"
            )
        file_handle.write("\n")
    
    print(f"Wrote {len(regression_formulas)} individual regression formulas to results file")

def create_plots(plot_df, model, config, feature_names, config_name, suffix='local'):
    """Create plots using sampled data and return regression formulas."""
    
    output_dir = f'profiling_results/{config_name}'
    os.makedirs(output_dir, exist_ok=True)
    
    num_features = len(feature_names)
    fig, axes = plt.subplots(1, num_features, figsize=(6*num_features, 5))
    
    if num_features == 1:
        axes = [axes]
    
    regression_formulas = []
    block_name = config['block']
    param_names = config['param_names']
    
    for i, feature in enumerate(feature_names):
        ax = axes[i]
        
        is_product_feature = feature in ['num_crosspoints', 'bandchannels']
        
        if not is_product_feature and i < len(param_names):
            fixed_param = param_names[1-i] if len(param_names) == 2 else None
            
            if fixed_param and fixed_param in plot_df.columns:
                all_fixed_vals = sorted(plot_df[fixed_param].unique())
                
                step = max(1, len(all_fixed_vals) // 10)
                sampled_vals = all_fixed_vals[::step]
                
                for fixed_val in sampled_vals:
                    mask = plot_df[fixed_param] == fixed_val
                    subset_df = plot_df[mask]
                    
                    if len(subset_df) > 1 and len(subset_df[feature].unique()) > 1:
                        x_data = subset_df[feature].values
                        y_data = subset_df[block_name].values
                        
                        X = x_data.reshape(-1, 1)
                        y = y_data.reshape(-1, 1)
                        subset_model = LinearRegression().fit(X, y)
                        r2_score = subset_model.score(X, y)
                        
                        regression_formulas.append({
                            'feature': feature,
                            'fixed_param': fixed_param,
                            'fixed_value': fixed_val,
                            'intercept': subset_model.intercept_[0],
                            'coefficient': subset_model.coef_[0][0],
                            'r2': r2_score
                        })
                        
                        ax.scatter(x_data, y_data, alpha=0.3, s=10, label=f'{fixed_param}={fixed_val}')
                        x_range = np.linspace(x_data.min(), x_data.max(), 50)
                        y_pred = subset_model.predict(x_range.reshape(-1, 1))
                        ax.plot(x_range, y_pred, '--', linewidth=1, alpha=0.7)
        
        elif is_product_feature:
            colors = []
            for idx in range(len(plot_df)):
                if config_name == 'matrix_mixer':
                    inputs = plot_df.iloc[idx]['num_inputs']
                    outputs = plot_df.iloc[idx]['num_outputs']
                    colors.append('blue' if inputs > outputs else 'red' if outputs > inputs else 'green')
                elif config_name == 'peq':
                    bands = plot_df.iloc[idx]['bands']
                    channels = plot_df.iloc[idx]['channels']
                    colors.append('blue' if bands > channels else 'red' if channels > bands else 'green')
                else:
                    colors.append('gray')
            
            ax.scatter(plot_df[feature], plot_df[block_name], alpha=0.3, s=10, c=colors)
            
            x_range = np.linspace(plot_df[feature].min(), plot_df[feature].max(), 100)
            X_pred = np.zeros((len(x_range), len(feature_names)))
            X_pred[:, i] = x_range
            for j in range(len(feature_names)):
                if j != i:
                    X_pred[:, j] = plot_df[feature_names[j]].median()
            
            y_pred = model.predict(X_pred)
            ax.plot(x_range, y_pred, 'r-', linewidth=2, label='Regression line')
        
        ax.set_xlabel(feature)
        ax.set_ylabel(f'{block_name} (timing)')
        ax.set_title(f'{config_name}: {feature}')
        ax.grid(True, alpha=0.3)
        ax.yaxis.set_major_formatter(matplotlib.ticker.ScalarFormatter(useMathText=True))
        ax.ticklabel_format(style='scientific', axis='y', scilimits=(0,0))
        
        if len(ax.get_legend_handles_labels()[0]) <= 10:
            ax.legend(fontsize=6, loc='best')
    
    fig.suptitle(f'{config_name.upper()}: Regression Analysis', fontsize=16)
    plt.tight_layout()
    
    plot_file = f'{output_dir}/{config_name}_regression_plots_{suffix}.png'
    plt.savefig(plot_file, dpi=150, bbox_inches='tight')
    print(f"Plot saved to: {plot_file}")
    plt.close()
    
    return regression_formulas

def cleanup_temp_files(config_name=None):
    """Remove temporary batch files."""
    if config_name:
        temp_dirs = [f'profiling_results/{config_name}_temp_batches']
    else:
        temp_dirs = glob.glob('profiling_results/*_temp_batches')
    
    for temp_dir in temp_dirs:
        if os.path.exists(temp_dir):
            for root, dirs, files in os.walk(temp_dir, topdown=False):
                for file in files:
                    os.remove(os.path.join(root, file))
                for dir in dirs:
                    os.rmdir(os.path.join(root, dir))
            os.rmdir(temp_dir)
            print(f"Cleaned up temporary files in {temp_dir}")

def process_from_checkpoints(config_name, suffix='local'):
    """Process data directly from checkpoint files."""
    checkpoint_dir = f'profiling_results/{config_name}_checkpoints'
    
    if not os.path.exists(checkpoint_dir):
        print(f"No checkpoint directory found: {checkpoint_dir}")
        return None
    
    print(f"\n{'='*60}")
    print(f"PROCESSING FROM CHECKPOINTS: {config_name.upper()}")
    print(f"{'='*60}")
    
    success = process_files_in_batches(config_name, batch_size=100)
    
    if success:
        model = perform_incremental_regression(config_name, calculate_all_formulas=True, suffix=suffix)
        
        cleanup_temp_files(config_name)
        
        return model
    
    return None

if __name__ == '__main__':
    import argparse
    import sys
    
    parser = argparse.ArgumentParser(description='Process and analyze profiling data from CSV files')
    parser.add_argument('config', nargs='?', default='matrix_mixer',
                       choices=['matrix_mixer', 'peq'],
                       help='Configuration to process (default: matrix_mixer)')
    parser.add_argument('--batch-size', type=int, default=100,
                       help='Number of files to process per batch (default: 100)')
    parser.add_argument('--process-batches', action='store_true',
                       help='Process CSV files into batches (step 1)')
    parser.add_argument('--analyze', action='store_true',
                       help='Perform regression analysis on batches (step 2)')
    parser.add_argument('--all-formulas', action='store_true',
                       help='Calculate regression formulas for ALL parameter combinations')
    parser.add_argument('--cleanup', action='store_true',
                       help='Remove temporary batch files after analysis')
    parser.add_argument('--from-checkpoints', action='store_true',
                       help='Process directly from checkpoint files')
    parser.add_argument('--suffix', default='local',
                       help='Suffix for output files (local/remote)')
    
    args = parser.parse_args()
    
    if args.from_checkpoints:
        model = process_from_checkpoints(args.config, suffix=args.suffix)
        if model:
            print("\nProcessing from checkpoints completed successfully!")
        sys.exit(0 if model else 1)
    
    if not args.process_batches and not args.analyze and not args.cleanup:
        args.process_batches = True
        args.analyze = True
    
    success = True
    
    if args.process_batches:
        success = process_files_in_batches(
            config_name=args.config,
            batch_size=args.batch_size
        )
    
    if success and args.analyze:
        model = perform_incremental_regression(
            config_name=args.config,
            calculate_all_formulas=args.all_formulas,
            suffix=args.suffix
        )
        
        if model:
            print("\nProcessing completed successfully!")
            print("Generated files:")
            print(f"  - profiling_results/{args.config}/{args.config}_regression_plots_{args.suffix}.png")
            print(f"  - profiling_results/{args.config}/results_{args.config}_{args.suffix}.txt")
            print(f"  - profiling_results/{args.config}/results_{args.config}_{args.suffix}.pkl")
    
    if args.cleanup:
        cleanup_temp_files(args.config)