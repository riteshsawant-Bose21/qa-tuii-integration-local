#!/usr/bin/env python3

# Builder script for use with bose-builder/yocto-sdk Docker image or native builds.

import os
import sys
import platform
from argparse import ArgumentParser
from glob import glob
from os.path import exists
from shutil import copy2, rmtree, which
from subprocess import check_call, run
from traceback import format_exc

# Image to use for cross-compiling using the Yocto SDK.
BUILDER_IMAGE = os.environ.get('BOSE_BUILDER_IMAGE', 'bose-builder/yocto-sdk') 
TAG = '[build.py]'
ERR = '** ERROR **'
NATIVE = 'native'

parser = ArgumentParser(description='Builder script for use with bose-builder/yocto-sdk Docker image or native builds')
# Always running both configure and build commands for now.
# parser.add_argument('-b', '--build', action='store_true', help='Run the build command')
# parser.add_argument('-c', '--configure', action='store_true', help='Run the configure command, runs before the build command')
parser.add_argument('--package', action='store_true', help='Package the build output')
parser.add_argument('-p', '--platform', nargs='?', default=NATIVE, help='The target platform (raphael, willis, etc.)')
parser.add_argument('-k', '--platform-sdk', nargs='?', default='yocto', help='Name of the container volume that has the Yocto SDK, for cross-compiling.')
args = parser.parse_args(sys.argv[1:])

# Check if the container image exists 
def image_exists(oci_runner):
    r = run([oci_runner, 'images', '-q', BUILDER_IMAGE], capture_output=True)
    return r.returncode == 0 and r.stdout != b''

def get_oci_runner():
    runner = os.getenv('OCI_EXE')
    if runner:
        return runner
    
    # Figure out what is available, prefer Podman.
    if which('podman'):
        runner='podman'
    elif which('docker'):
        runner='docker'
    else:
        print(TAG, ERR, "No container executor found. Is docker or podman installed?")
    
    return runner

def get_oci_run_flags(runner):
    '''Set up the `run` command for the container.'''
    flags = ['run', '--rm', '-it']    
    flags.extend(['-v', './:/src'])
    flags.extend(['-v', '{}:/yocto'.format(args.platform_sdk)])
    
    if sys.platform == 'linux':
        # Don't use -u root with Linux. If you do, root will own all files and
        # directories written by the build, since it has real Linux container
        # support.
        if runner == 'podman':
            flags.append('--userns=keep-id')

    if platform.machine() == 'arm64':
        # For running on ARM-based Mac
        flags.append('--platform=linux/amd64')

    return flags

def get_yocto_platform():
    try:
        # The target-platform file should be created by the sdk_startup.py
        target_file = os.path.join(args.platform_sdk, 'target-platform')
        with open(target_file) as tFile:
            return tFile.readline().strip()

    except Exception as e:
        print(TAG, e)
        return 'yocto'

def make_package(target_platform):
    '''Package the Raphael-DSP code and assets in a zip file
    Derived from the build script on CloudBees Build-RaphaelBDSP job.

    Arguments:
     - target_platform - a platform name that has OS + CPU architecture (not the same as args.platform)
    '''

    if args.platform == NATIVE:
        print(TAG, ERR, "Refusing to package a native build, what would you do with it?")
        return

    print(TAG, "Packaging build artifacts for: '{}' ({}) NOT YET IMPLEMENTED".format(target_platform, args.platform))


def build_native(configure, build): 
    # Always running both configure and build commands for now.
    check_call(configure.split())
    check_call(build.split())

def build_target(configure, build, target_platform):
    # Prep commands for running inside the Yocto SDK container
    runner = get_oci_runner()

    # Set up build and configure options for the bose-builder/yocto-sdk container.
    # These options are handled by the sdk_startup.py entrypoint.
    configure_cmd = "--configure=" + configure
    build_cmd = "--build=" + build
    
    if args.platform != 'native':
        configure_cmd += ' --platform=' + args.platform

    run_cmd = [runner]
    run_cmd.extend(get_oci_run_flags(runner))
    run_cmd.append(BUILDER_IMAGE)

    # Always running both configure and build commands for now.
    run_cmd.append(configure_cmd)
    run_cmd.append(build_cmd)

    print(TAG, "Final container 'run' command:\n\t", run_cmd)
    check_call(run_cmd)


def main():
    '''Run the Raphael-DSP build, either native or cross-build in a yocto sdk
    container, and ptionally package the build.
    '''
    try:
        configure_cmd = 'python3 waf configure'
        build_cmd = 'python3 waf build'
        target_platform = ''

        if args.platform != NATIVE:
            target_platform = get_yocto_platform()
                        
            print(TAG, "Building for {} using Yocto SDK".format(target_platform))
            build_target(configure_cmd, build_cmd, target_platform)
        else:
            uname = platform.uname();
            target_platform = "{}-{}".format(uname.system.lower(), uname.machine)
            
            print(TAG, "Building for native: {}".format(target_platform))
            build_native(configure_cmd, build_cmd)
            
        if args.package:
            make_package(target_platform)

    except Exception as e:
        print(TAG, ERR, "Use -h for help")
        print('\n', format_exc())
        sys.exit(1)

main()
