import pandas as pd
import glob
import os
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from sklearn.linear_model import LinearRegression
import pickle
import gc
import re

def process_files_in_batches(batch_size=100):
    """
    Process files in small batches and save intermediate results to disk
    """
    print(f"\n{'='*60}")
    print(f"PROCESSING MATRIX MIXER DATA IN BATCHES")
    print(f"{'='*60}")
    
    # Find all processed files
    processed_files = glob.glob('profiling_results/timings_mm_*_*_processed.csv')
    print(f"Found {len(processed_files)} processed files")
    print(f"Processing in batches of {batch_size} files")
    
    if not processed_files:
        print("No processed files found!")
        return False
    
    # Create temp directory for batch files
    temp_dir = 'profiling_results/temp_batches'
    os.makedirs(temp_dir, exist_ok=True)
    
    # Process in batches
    batch_num = 0
    for i in range(0, len(processed_files), batch_size):
        batch_files = processed_files[i:i+batch_size]
        batch_frames = []
        
        print(f"\nProcessing batch {batch_num + 1} (files {i+1} to {min(i+batch_size, len(processed_files))})")
        
        for file in batch_files:
            try:
                df = pd.read_csv(file)
                
                # Extract parameters from filename for adding to dataframe
                filename = os.path.basename(file)
                match = re.search(r'timings_mm_(\d+)_(\d+)_processed\.csv', filename)
                if match and 'num_inputs' not in df.columns:
                    df['num_inputs'] = int(match.group(1))
                    df['num_outputs'] = int(match.group(2))
                
                # Add features
                df['num_crosspoints'] = df['num_inputs'] * df['num_outputs']
                
                # Apply per-combination filtering
                block_values = pd.to_numeric(df['matrix_mixer'], errors='coerce')
                df = df[~block_values.isna()]
                
                if len(df) > 0:
                    low_q = df['matrix_mixer'].quantile(0.999)
                    high_q = df['matrix_mixer'].quantile(0.9999)
                    df = df[(df['matrix_mixer'] >= low_q) & (df['matrix_mixer'] <= high_q)]
                    batch_frames.append(df)
                
            except Exception as e:
                print(f"Error loading {file}: {e}")
                continue
        
        if batch_frames:
            batch_df = pd.concat(batch_frames, ignore_index=True)
            # Save batch to disk
            batch_file = f"{temp_dir}/batch_{batch_num:04d}.parquet"
            batch_df.to_parquet(batch_file)
            print(f"Saved batch {batch_num + 1} with {len(batch_df)} rows to {batch_file}")
            batch_num += 1
            
            # Clear memory
            del batch_frames, batch_df
            gc.collect()
    
    print(f"\nSaved {batch_num} batch files to {temp_dir}")
    return True

def calculate_all_regression_formulas(config_name='matrix_mixer'):
    """
    Calculate regression formulas for ALL parameter combinations from batch files
    This ensures we get formulas for all 64x64 combinations, not just sampled ones
    """
    temp_dir = 'profiling_results/temp_batches'
    batch_files = sorted(glob.glob(f"{temp_dir}/batch_*.parquet"))
    
    if not batch_files:
        print("No batch files found for calculating individual formulas")
        return []
    
    print("\nCalculating individual regression formulas for all combinations...")
    
    # Dictionary to store data for each combination
    combination_data = {}
    
    # Read all batch files and organize by combination
    for batch_file in batch_files:
        df = pd.read_parquet(batch_file)
        
        # Group by num_inputs and num_outputs
        for (inp, outp), group in df.groupby(['num_inputs', 'num_outputs']):
            key = (int(inp), int(outp))
            if key not in combination_data:
                combination_data[key] = []
            combination_data[key].append(group[['num_inputs', 'num_outputs', 'num_crosspoints', 'matrix_mixer']])
        
        del df
        gc.collect()
    
    regression_formulas = []
    
    # Calculate regression for each fixed parameter value
    # First: num_outputs fixed, varying num_inputs
    for fixed_output in range(1, 65):
        x_data = []
        y_data = []
        
        for inp in range(1, 65):
            key = (inp, fixed_output)
            if key in combination_data:
                combo_df = pd.concat(combination_data[key])
                x_data.extend([inp] * len(combo_df))
                y_data.extend(combo_df['matrix_mixer'].values)
        
        if len(x_data) > 1 and len(set(x_data)) > 1:
            X = np.array(x_data).reshape(-1, 1)
            y = np.array(y_data)
            model = LinearRegression().fit(X, y)
            r2 = model.score(X, y)
            
            regression_formulas.append({
                'feature': 'num_inputs',
                'fixed_param': 'num_outputs',
                'fixed_value': fixed_output,
                'intercept': model.intercept_,
                'coefficient': model.coef_[0],
                'r2': r2
            })
    
    # Second: num_inputs fixed, varying num_outputs
    for fixed_input in range(1, 65):
        x_data = []
        y_data = []
        
        for outp in range(1, 65):
            key = (fixed_input, outp)
            if key in combination_data:
                combo_df = pd.concat(combination_data[key])
                x_data.extend([outp] * len(combo_df))
                y_data.extend(combo_df['matrix_mixer'].values)
        
        if len(x_data) > 1 and len(set(x_data)) > 1:
            X = np.array(x_data).reshape(-1, 1)
            y = np.array(y_data)
            model = LinearRegression().fit(X, y)
            r2 = model.score(X, y)
            
            regression_formulas.append({
                'feature': 'num_outputs',
                'fixed_param': 'num_inputs', 
                'fixed_value': fixed_input,
                'intercept': model.intercept_,
                'coefficient': model.coef_[0],
                'r2': r2
            })
    
    print(f"Calculated {len(regression_formulas)} individual regression formulas")
    return regression_formulas

def perform_incremental_regression(config_name='matrix_mixer', calculate_all_formulas=True):
    """
    Perform regression using batch files without loading all data at once
    """
    config = {
        'features': {
            'num_inputs': lambda x: x['num_inputs'],
            'num_outputs': lambda x: x['num_outputs'],
            'num_crosspoints': lambda x: x['num_inputs'] * x['num_outputs']
        },
        'fixed_values': {
            'num_inputs': {'fix_for': 'num_outputs', 'values': list(range(1, 65, 1))},
            'num_outputs': {'fix_for': 'num_inputs', 'values': list(range(1, 65, 1))}
        },
        'block': 'matrix_mixer',
        'format_string': 'T = {0} + {1}*num_inputs + {2}*num_outputs + {3}*num_crosspoints'
    }
    
    temp_dir = 'profiling_results/temp_batches'
    batch_files = sorted(glob.glob(f"{temp_dir}/batch_*.parquet"))
    
    if not batch_files:
        print("No batch files found! Run with --process-batches first")
        return None
    
    print(f"\n{'='*60}")
    print(f"PERFORMING INCREMENTAL REGRESSION")
    print(f"{'='*60}")
    print(f"Found {len(batch_files)} batch files")
    
    # First pass: calculate statistics for regression
    feature_names = list(config['features'].keys())
    n_features = len(feature_names)
    
    # Initialize accumulators for incremental statistics
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
        
        X = df[feature_names].values
        y = df['matrix_mixer'].values
        
        batch_n = len(df)
        n += batch_n
        sum_x += np.sum(X, axis=0)
        sum_y += np.sum(y)
        sum_xx += X.T @ X
        sum_xy += X.T @ y
        sum_yy += y @ y
        
        del df
        gc.collect()
    
    # Calculate regression coefficients using normal equations
    mean_x = sum_x / n
    mean_y = sum_y / n
    
    # Covariance matrices
    cov_xx = sum_xx / n - np.outer(mean_x, mean_x)
    cov_xy = sum_xy / n - mean_x * mean_y
    
    # Solve for coefficients
    try:
        coef = np.linalg.solve(cov_xx, cov_xy)
        intercept = mean_y - np.dot(mean_x, coef)
        
        # Calculate R-squared
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
    
    # Build equation
    equation_parts = [f"{intercept:.2e}"]
    for i, feature in enumerate(feature_names):
        equation_parts.append(f"{coef[i]:.2e}*{feature}")
    full_equation = " + ".join(equation_parts)
    print(f"Full equation: y = {full_equation}")
    
    # Create a simple LinearRegression model object for compatibility
    model = LinearRegression()
    model.coef_ = coef.reshape(1, -1)
    model.intercept_ = np.array([intercept])
    
    # Pass 2: Create plots using sampled data
    print("\nPass 2: Creating plots with sampled data...")
    
    # Sample data for plotting (to avoid memory issues)
    plot_data = []
    sample_interval = max(1, len(batch_files) // 20)  # Sample from up to 20 batches
    
    for i in range(0, len(batch_files), sample_interval):
        df = pd.read_parquet(batch_files[i])
        # Sample 10% of each batch for plotting
        df_sample = df.sample(frac=0.1, random_state=42)
        plot_data.append(df_sample)
        del df
        gc.collect()
    
    plot_df = pd.concat(plot_data, ignore_index=True)
    print(f"Using {len(plot_df):,} sampled points for plotting")
    
    # Create plots (this will calculate formulas from sampled data)
    plot_regression_formulas = create_plots(plot_df, model, config, feature_names, config_name)
    
    # If requested, calculate ALL regression formulas from batch files
    if calculate_all_formulas:
        all_regression_formulas = calculate_all_regression_formulas(config_name)
    else:
        all_regression_formulas = plot_regression_formulas
    
    # Save results
    with open(f'profiling_results/{config_name}_model_from_csv.pkl', 'wb') as f:
        pickle.dump(model, f)
    
    with open(f'profiling_results/{config_name}_results_from_csv.txt', 'w') as f:
        f.write(f"Configuration: {config_name.upper()}\n")
        f.write("Main Regression Formula:\n")
        f.write("=" * 50 + "\n")
        main_formula = config['format_string'].format(intercept, *coef)
        f.write(main_formula + "\n\n")
        f.write(f"Based on {n:,} data points from {len(batch_files)} batches\n")
        f.write(f"R² Score: {r2_score:.4f}\n\n")
        
        # Add individual regression formulas just like profile_block
        if all_regression_formulas:
            feature_formulas = {}
            for formula in all_regression_formulas:
                if formula['feature'] not in feature_formulas:
                    feature_formulas[formula['feature']] = []
                feature_formulas[formula['feature']].append(formula)
            
            for feature, formulas in feature_formulas.items():
                if feature == 'num_crosspoints':  # Skip product features
                    continue
                    
                f.write(f"\n{feature.upper()} Regression Formulas:\n")
                f.write("=" * 50 + "\n")
                
                # Sort formulas by fixed value
                for formula in sorted(formulas, key=lambda x: x.get('fixed_value', 0)):
                    fixed_param = formula.get('fixed_param')
                    fixed_value = formula.get('fixed_value')
                    f.write(
                        f"{fixed_param} = {fixed_value}:\n"
                        f"T = {formula['intercept']:.2e} + {formula['coefficient']:.2e}*{feature}"
                        f" (R² = {formula['r2']:.3f})\n"
                    )
                f.write("\n")
            
            print(f"Wrote {len(all_regression_formulas)} individual regression formulas to results file")
    
    print(f"\nResults written to: profiling_results/{config_name}_results_from_csv.txt")
    
    return model

def create_plots(plot_df, model, config, feature_names, config_name):
    """Create plots using sampled data and return regression formulas"""
    
    num_features = len(feature_names)
    fig, axes = plt.subplots(1, num_features, figsize=(6*num_features, 5))
    
    if num_features == 1:
        axes = [axes]
    
    fixed_values = config.get('fixed_values', {})
    regression_formulas = []  # Track all individual regression formulas
    
    for i, feature in enumerate(feature_names):
        ax = axes[i]
        
        is_product_feature = feature == 'num_crosspoints'
        
        if not is_product_feature and feature in fixed_values:
            fix_info = fixed_values[feature]
            fix_for = fix_info['fix_for']
            
            # Get ALL unique values for regression calculation
            all_existing_vals = sorted(plot_df[fix_for].unique())
            
            # Calculate regression for ALL values (not just plotted ones)
            for fixed_val in all_existing_vals:
                mask = plot_df[fix_for] == fixed_val
                subset_df = plot_df[mask]
                
                if len(subset_df) > 1 and len(subset_df[feature].unique()) > 1:
                    x_data = subset_df[feature].values
                    y_data = subset_df['matrix_mixer'].values
                    
                    X = x_data.reshape(-1, 1)
                    y = y_data.reshape(-1, 1)
                    subset_model = LinearRegression().fit(X, y)
                    r2_score = subset_model.score(X, y)
                    
                    # Store the regression formula
                    regression_formulas.append({
                        'feature': feature,
                        'fixed_param': fix_for,
                        'fixed_value': fixed_val,
                        'intercept': subset_model.intercept_[0],
                        'coefficient': subset_model.coef_[0][0],
                        'r2': r2_score
                    })
                    
                    # Only plot a subset for visibility
                    step = max(1, len(all_existing_vals) // 15)
                    if fixed_val in all_existing_vals[::step]:
                        ax.scatter(x_data, y_data, alpha=0.3, s=10, label=f'{fix_for}={fixed_val}')
                        x_range = np.linspace(x_data.min(), x_data.max(), 50)
                        y_pred = subset_model.predict(x_range.reshape(-1, 1))
                        ax.plot(x_range, y_pred, '--', linewidth=1, alpha=0.7)
        
        elif is_product_feature:
            # Color code by input/output ratio
            colors = []
            for idx in range(len(plot_df)):
                inputs = plot_df.iloc[idx]['num_inputs']
                outputs = plot_df.iloc[idx]['num_outputs']
                if inputs > outputs:
                    colors.append('blue')
                elif outputs > inputs:
                    colors.append('red')
                else:
                    colors.append('green')
            
            ax.scatter(plot_df[feature], plot_df['matrix_mixer'], 
                      alpha=0.3, s=10, c=colors)
            
            # Add regression line
            x_range = np.linspace(plot_df[feature].min(), plot_df[feature].max(), 100)
            X_pred = np.zeros((len(x_range), len(feature_names)))
            X_pred[:, i] = x_range
            for j in range(len(feature_names)):
                if j != i:
                    X_pred[:, j] = plot_df[feature_names[j]].median()
            
            y_pred = model.predict(X_pred)
            ax.plot(x_range, y_pred, 'r-', linewidth=2, label=f'Regression line')
        
        ax.set_xlabel(feature)
        ax.set_ylabel('matrix_mixer (timing)')
        ax.set_title(f'{config_name}: {feature}')
        ax.grid(True, alpha=0.3)
        ax.yaxis.set_major_formatter(matplotlib.ticker.ScalarFormatter(useMathText=True))
        ax.ticklabel_format(style='scientific', axis='y', scilimits=(0,0))
        
        if len(ax.get_legend_handles_labels()[0]) <= 10:
            ax.legend(fontsize=6, loc='best')
    
    fig.suptitle(f'{config_name}: Regression Analysis', fontsize=16)
    plt.tight_layout()
    
    plot_file = f'profiling_results/{config_name}_regression_plots_from_csv.png'
    plt.savefig(plot_file, dpi=150, bbox_inches='tight')
    print(f"Plot saved to: {plot_file}")
    plt.close()
    
    return regression_formulas  # Return the formulas for writing to file

def cleanup_temp_files():
    """Remove temporary batch files"""
    import shutil
    temp_dir = 'profiling_results/temp_batches'
    if os.path.exists(temp_dir):
        shutil.rmtree(temp_dir)
        print(f"Cleaned up temporary files in {temp_dir}")

if __name__ == '__main__':
    import argparse
    
    parser = argparse.ArgumentParser(description='Plot and analyze matrix mixer data from CSV files')
    parser.add_argument('--batch-size', type=int, default=100,
                       help='Number of files to process per batch (default: 100)')
    parser.add_argument('--process-batches', action='store_true',
                       help='Process CSV files into batches (step 1)')
    parser.add_argument('--analyze', action='store_true',
                       help='Perform regression analysis on batches (step 2)')
    parser.add_argument('--all-formulas', action='store_true',
                       help='Calculate regression formulas for ALL parameter combinations (takes longer)')
    parser.add_argument('--cleanup', action='store_true',
                       help='Remove temporary batch files after analysis')
    
    args = parser.parse_args()
    
    # If no specific action, do both
    if not args.process_batches and not args.analyze and not args.cleanup:
        args.process_batches = True
        args.analyze = True
    
    success = True
    
    if args.process_batches:
        success = process_files_in_batches(batch_size=args.batch_size)
    
    if success and args.analyze:
        model = perform_incremental_regression(calculate_all_formulas=args.all_formulas)
        
        if model:
            print("\nProcessing completed successfully!")
            print("Generated files:")
            print("  - profiling_results/matrix_mixer_regression_plots_from_csv.png")
            print("  - profiling_results/matrix_mixer_results_from_csv.txt")
            print("  - profiling_results/matrix_mixer_model_from_csv.pkl")
    
    if args.cleanup:
        cleanup_temp_files()