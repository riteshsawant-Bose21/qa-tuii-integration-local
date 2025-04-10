# Make a tar.gz package of a build.
# Usage: python3 package.py [--info-only]
# Args:
#   --info-only - Only generate fusion-dsp.info, don't create a tarball.

import tarfile
import subprocess
import datetime
import os
import sys

TAG = "[package.py]"
APP_PATH = 'build/fusion_dsp'
INFO_PATH = 'build/fusion-dsp.info'

def create_info_file(version):
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
        info_file.write(f'VERSION="{version}"\n')
        info_file.write(f'BRANCH="{git_branch}"\n')
        info_file.write(f'COMMIT_ID="{git_hash}"\n')
        info_file.write(f'COMMIT_DATE="{git_date}"\n')
        info_file.write(f'BUILD_DATE="{build_date}"\n')
    
    print(TAG, f'Created: {INFO_PATH}')

def create_tarball(version):
    # Add the files needed to install in the target image.
    required_files = [
        INFO_PATH,
        APP_PATH,
        'config/algorithm-definitions.json',
        'config/configuration.json',
        'config/prototype1_demo.json',
        'config/telemetry-configuration.json',
        'config/telemetry-messages.json'
    ]

    print(TAG, 'Creating build package...')

    TAR_PATH = f'build/fusion-dsp_{version}.tar.gz'
    with tarfile.open(TAR_PATH, 'w:gz') as tar:
        for f in required_files:
            print(TAG, f'  add {f}')
            tar.add(f)

    print(TAG, f'Created: {TAR_PATH}')

if __name__ == '__main__':
    info_only = False
    if len(sys.argv) > 1 and sys.argv[1] == '--info-only':
        info_only = True

    # Getting version from the Jenkins environment, if not set default to LOCAL version
    version = os.getenv('VERSION', 'LOCAL')

    create_info_file(version)
    if not info_only:
        create_tarball(version)

        # Clean up temporary files.
        os.remove(INFO_PATH)

    print(TAG, "Done")
