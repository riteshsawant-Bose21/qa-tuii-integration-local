# Make a tar.gz package of a build.
# Usage: python3 package.py [--info-only] [--build-dir=<build-dir>]

import tarfile
import subprocess
import datetime
import os
import sys

from argparse import ArgumentParser

TAG = "[package.py]"

# Getting version from the Jenkins environment, if not set default to LOCAL version
VERSION = os.getenv('VERSION', 'LOCAL')

parser = ArgumentParser()
parser.add_argument('-d', '--build-dir', default='./build')
parser.add_argument('-i', '--info-only', action='store_true')
args = parser.parse_args(sys.argv[1:])

BUILD_DIR = os.path.abspath(args.build_dir)
APP_PATH = os.path.join(BUILD_DIR, 'fusion_dsp')
INFO_PATH = os.path.join(BUILD_DIR, 'fusion-dsp.info')


def create_info_file():
    git_hash = subprocess.check_output(['git', 'rev-parse', 'HEAD']).decode('ascii').strip()
    git_branch = os.getenv('branch', 'HEAD')
    commit_ts = int(subprocess.check_output(['git', 'show', '-s', '--format=%ct', 'HEAD']).decode('ascii').strip())
    build_ts = os.path.getmtime(APP_PATH)

    # Get the commit date and build date in UTC.
    git_date = datetime.datetime.fromtimestamp(commit_ts, tz=datetime.timezone.utc).isoformat()
    build_date = datetime.datetime.fromtimestamp(build_ts, tz=datetime.timezone.utc).isoformat('T', 'seconds')

    # Write the fusion-dsp.info file.
    with open(INFO_PATH, "w") as info_file:
        info_file.write(f'APP="fusion-dsp"\n')
        info_file.write(f'VERSION="{VERSION}"\n')
        info_file.write(f'BRANCH="{git_branch}"\n')
        info_file.write(f'COMMIT_ID="{git_hash}"\n')
        info_file.write(f'COMMIT_DATE="{git_date}"\n')
        info_file.write(f'BUILD_DATE="{build_date}"\n')
    
    print(TAG, f'Created: {INFO_PATH}')

def create_tarball():
    # Add the files needed to install in the target image.
    build_files = [INFO_PATH, APP_PATH]

    config_files = [
        'config/algorithm-definitions.json',
        'config/configuration.json',
        'config/prototype1_demo.json',
        'config/telemetry-configuration.json',
        'config/telemetry-messages.json'
    ]

    print(TAG, 'Creating build package...')

    TAR_PATH = os.path.join(BUILD_DIR, f'fusion-dsp_{VERSION}.tar.gz')
    with tarfile.open(TAR_PATH, 'w:gz') as tar:
        for f in build_files:
            # Handle `build_files` specially, because the --build-dir argument
            # can vary widely between local and Jenkins builds. This will
            # simplify handling in Yocto.
            arcName =  os.path.join('build', os.path.basename(f))
            print(TAG, f'  add {f} as {arcName}')
            tar.add(f, arcname=arcName)

        for f in config_files:
            print(TAG, f'  add {f} as {arcName}')
            tar.add(f)

    print(TAG, f'Created: {TAR_PATH}')

if __name__ == '__main__':
    # Change directory to the path this script is in so Git commands work in Yocto.
    script_path = os.path.abspath(__file__)
    os.chdir(os.path.dirname(script_path))

    create_info_file()
    if not args.info_only:
        create_tarball()

        # Clean up temporary files.
        os.remove(INFO_PATH)

    print(TAG, "Done")
