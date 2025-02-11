# Make a tar.gz package of a build.
# Usage: python3 package.py

import tarfile
import subprocess
import datetime
import os


APP_PATH = 'build/mune_dsp'
INFO_PATH = 'build/fusion-dsp.info'

# Getting version from the Jenkins environment, if not set default to LOCAL version
version = os.getenv('VERSION', 'LOCAL')

git_hash = subprocess.check_output(['git', 'rev-parse', 'HEAD']).decode('ascii').strip()
git_branch = subprocess.check_output(['git', 'rev-parse', '--abbrev-ref', 'HEAD']).decode('ascii').strip()
commit_ts = int(subprocess.check_output(['git', 'show', '-s', '--format=%ct', 'HEAD']).decode('ascii').strip())
build_ts = os.path.getmtime(APP_PATH)

# Get the commit date and build date in UTC.
git_date = datetime.datetime.fromtimestamp(commit_ts, tz=datetime.timezone.utc).isoformat() 
build_date = datetime.datetime.fromtimestamp(build_ts, tz=datetime.timezone.utc).isoformat('T', 'seconds')

# Write the fusion-dsp.info file.
with open(INFO_PATH, "w") as info_file:
    info_file.write(f'APP="mune-dsp"\n')
    info_file.write(f'VERSION="{version}"\n')
    info_file.write(f'BRANCH="{git_branch}"\n')
    info_file.write(f'COMMIT_ID="{git_hash}"\n')
    info_file.write(f'COMMIT_DATE="{git_date}"\n')
    info_file.write(f'BUILD_DATE="{build_date}"\n')

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

print(f'Creating build package...')

TAR_PATH = f'build/fusion-dsp_{version}.tar.gz'
with tarfile.open(TAR_PATH, 'w:gz') as tar:
    for f in required_files:
        print(f'  add {f}')
        tar.add(f)

# Clean up temporary files.
os.remove(INFO_PATH)

print(f'Created: {TAR_PATH}')
