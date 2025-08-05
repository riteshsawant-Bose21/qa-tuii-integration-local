import pandas as pd
import jinja2 as j
import itertools
import pickle
import sys
import os
import platform
import subprocess
from sklearn.linear_model import LinearRegression
from subprocess import run

def profile(config_name, remote=True):
    """
    Profile a specific config locally or remotely on a Variscite board.
    
    Args:
        config_name (str): The name of the configuration to profile.
        remote (bool): If True, runs the profiling on a remote Variscite board via SSH.
                                If False, runs locally on detected OS (assumed to be Linux or macOS).
    """
    board_ip = "192.168.1.7" # Change this to your board's IP address; only for remote=True (default)
    loader = j.FileSystemLoader("./config/profiling")
    env = j.Environment(loader=loader, autoescape=j.select_autoescape())
    current_config = configurations[config_name]
    template = env.get_template(current_config['path'])
    
    frames = []

    params_iter = dict_to_iter(current_config.get('parameters', default_parameters))
    feature_dict = current_config.get('features', default_features)

    for param_dict in params_iter:
        if remote:
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
        
            result = subprocess.run([
                'ssh', f'root@{board_ip}', '/usr/local/bin/fusion_dsp -d /etc/fusion/dsp/algorithm-definitions.json -c /home/root/tmp.json',
            ], capture_output=True, text=True)

            print(f'fusion_dsp output: {result.stdout}')
            if result.stderr:
                print(f'fusion_dsp error: {result.stderr}')
            
            os.system(f'scp root@{board_ip}:/home/root/timings.csv ./timings.csv')
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
            df = pd.read_csv('timings.csv')
            for feature, formula in feature_dict.items():
                df[feature] = formula(param_dict)
            
            frames.append(df)
        try:
            df = pd.read_csv('timings.csv')
            for feature, formula in feature_dict.items():
                df[feature] = formula(param_dict)
            frames.append(df)
        except Exception as e:
            print(f"Error reading timings.csv: {e}")
            continue 
    
    result_df = pd.concat(frames, axis=0, ignore_index=True)
    if remote:
        print("Copying out.wav from board...")
        os.system(f'scp root@{board_ip}:/home/root/out.wav ./out.wav')
    
    if current_config.get('csv_dump'):
        os.makedirs('profiling_results', exist_ok=True)
        result_df.to_csv(f"profiling_results/{current_config['csv_dump']}")

    block = current_config.get(
            'block',
            config_name
        )
    low_quantile = result_df.quantile(0.99)[block]
    high_quantile = result_df.quantile(0.9999)[block]
    filtered_df = result_df[
        (result_df[block] > low_quantile) &
        (result_df[block] < high_quantile)
    ]

    Xs = filtered_df[list(feature_dict.keys())]
    ys = filtered_df[[block]]

    model = LinearRegression().fit(Xs, ys)
    print(model.coef_)
    print(model.intercept_)
    print(model.score(Xs, ys))

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
        'path' : 'profile_ducker.json.jinja'
    },
    'feedback_suppression' : {
        'path' : 'profile_simple_block.json.jinja',
        'algorithm' : 'feedback_suppression'
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
            'num_inputs' : range(1, 60, 5),
            'num_outputs' : range(1, 60, 4)
        },
        'features' : {
            # 'num_inputs' : lambda x: x['num_inputs'],
            # 'num_outputs' : lambda x: x['num_outputs'],
            'num_crosspoints' : lambda x: x['num_inputs']*x['num_outputs']
        },
        'wav_input' : 'MD24_10.wav',
        'csv_dump' : 'matrix_mixer_timings.csv',
        'format_string' : 'T = {0} + {1}*num_inputs*num_outputs'
    },
    'passthrough' : {
        'path' : 'profile_passthrough.json.jinja',
        'block' : 'task1',
        'wav_input' : 'in_10_tracks.wav'
    },
    'peq' : {
        'path' : 'profile_peq.json.jinja',
        'parameters': {
            'bands': range(5, 38, 4),
            'channels': range(1, 10)
        },
        'features': {
            # 'bands': lambda x: x['bands'],
            # 'channels': lambda x: x['channels'],
            'bandchannels': lambda x: x['bands']*x['channels']
        },
        'wav_input' : 'MD24_10.wav',
        'csv_dump' : 'peq_tmp.csv',
        'format_string' : 'T = {0} + {1}*bands*channels'
    },
    'tone' : {
        'path' : 'profile_tone.json.jinja'
    },
    'wav_read' : {
        'path' : 'profile_passthrough.json.jinja',
        'block' : 'task1',
        'wav_input' : 'in_10_tracks.wav'
    },
    'wav_write' : {
        'path' : 'profile_passthrough.json.jinja',
        'block' : 'task1',
        'wav_input' : 'in_10_tracks.wav'
    }
}
default_parameters = {
    'channels' : range(1,10,3)
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