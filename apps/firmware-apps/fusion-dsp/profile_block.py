import pandas as pd
import jinja2 as j
import itertools
import pickle
import sys
import os
from sklearn.linear_model import LinearRegression
from subprocess import run

def profile(config_name):
    loader = j.FileSystemLoader("./config/profiling")
    env = j.Environment(loader=loader, autoescape=j.select_autoescape())
    current_config = configurations[config_name]

    template = env.get_template(current_config['path'])
    frames = []


    params_iter = dict_to_iter(
        current_config.get(
            'parameters',
            default_parameters
        )
    )
    feature_dict = current_config.get(
        'features',
        default_features
    )
    

    for param_dict in params_iter:
        f = open('tmp.json', 'w')
        f.write(
            template.render(
                output_file='timings.csv',
                wav_input=current_config.get(
                    'wav_input',
                    'in.wav'
                ),
                algorithm=current_config.get(
                    'algorithm'
                ),
                **param_dict
            )
        )
        f.close()
        
        env = {'DYLD_LIBRARY_PATH' : 'libs/onnxruntime-osx-universal2-1.17.0/lib/:'}
        run(['./build/mune_dsp','-c', 'tmp.json'],
            # If running on MacOS and having trouble with dylib, uncomment this.
            # env=env
            )
        df = pd.read_csv('timings.csv')
        for feature, formula in feature_dict.items():
            df[feature] = formula(param_dict)
        
        frames.append(df)

    result_df = pd.concat(frames, axis=0, ignore_index=True)
    if current_config.get('csv_dump'):
        result_df.to_csv(current_config['csv_dump'])
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

    Xs = filtered_df[feature_dict.keys()]
    ys = filtered_df[[block]]

    model = LinearRegression().fit(Xs, ys)

    print(model.coef_)
    print(model.intercept_)
    print(model.score(Xs, ys))

    return model
    

p = {
    'bands': range(5, 38, 4),
    'channels': range(1, 10)
}
feature_dict = {
    'bands': lambda x: x['bands'],
    'channels': lambda x: x['channels'],
    'bandchannels': lambda x: x['bands']*x['channels']
}


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
        'format_string' : 'T = {0} + {1}*num_inputs + {2}*num_outputs + {3}*num_inputs*num_outputs'
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
        'format_string' : 'T = {0} + {1}*bands + {2}*channels + {3}*bands*channels'
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
    if len(sys.argv) == 1:
        results = {}
        f_model_readable = open('results.txt', 'w')
        for config in configurations.keys():
            print(f'Running profiling configuration: {config}')
            model = results[config] = profile(config)
            f_model_readable.write(
                f'{config} : ' +
                configurations[config].get('format_string', default_format_string).format(*model.intercept_, *model.coef_[0])
                + '\n'
            )
        f_model_pickle = open('results.pkl', 'wb')
        pickle.dump(results, f_model_pickle)
        f_model_pickle.close()
        
    else:
        config = sys.argv[1]
        f_model_pickle = open(f'results_{config}.pkl', 'wb')
        f_model_readable = open(f'results_{config}.txt', 'w')
        model = profile(config)
        pickle.dump(model, f_model_pickle)
        f_model_readable.write(
            configurations[config].get('format_string', default_format_string).format(*model.intercept_, *model.coef_[0])
        )
        f_model_pickle.close()