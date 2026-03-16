# Fusion Telemetry Core
This repository contains the source code and associated files for the fusion telemetry core firmware application.

## Requirements
The applications uses the following components and expects them to be installed on the build machine and the target.
1. Boost
2. SPDLOG

The make file supports x86 and ARM (i.MX8) architectures. In order to build for the i.MX8 target the SDK has to be installed. The script for installing the SDK can be downloaded from https://boseprofessional.sharepoint.com/:f:/s/FusionMVPTeam/En2Kvq3tm-BPiR0roMCaDPoB-HJMfQ5-pLCbVbECYoAEXw?e=95yzJm

Follow the steps bellow to install and use the SDK.
1. Create a directory to install the Fusion Yocto SDK in.
    >*SDK_DIR=/bose/fusion/yocto-sdk/*

    >*mkdir $SDK_DIR*

2. Install the SDK (do this only once).
    >*./imx8mm-var-dart-fusion-toolchain-4.2.2.sh -y -d $SDK_DIR*

3. Use the SDK (Do this every time you have a new terminal and need to build using the SDK)
    >*source $SDK_DIR/environment-setup-cortexa53-crypto-poky-linux*

## Building the application
The application uses *make*. To build the application run *make* from the application root folder. *make clean* will remove all the generated files.

With waf:

>*./waf configure && ./waf*

## Running unit tests

GoogleTest-based unit tests are built when `gtest` is available via `pkg-config`.

Build and run:

>*./waf configure && ./waf*

>*./build/telemetry_core_tests*

## Running the application
The application accepts the following arguments
1. The system IP and port number (-i IP:Port)

    This is a **Mandatory** argument. The format is *IP:Port*.

2. Configuration file. (-c full/path/of/config/file)

    Full path to the configuration file (JSON). This is an optional argument and the default file and path are *./config/telemetry-configuration.json*.

3. Unix Socket file path (-p /Unix/socket/file/path)

    Full path of the Unix socket file. This overrides the value in the configuration file.

4. Meter Data Update Request period (-u Hi_period Med_period Lo_period)

    The HI, MED & LO meters update request periods. This overrides the values in the configuration file.
    The units are in frames (1 frame = 2/3ms)

5. Meter Data Report period (-r Hi_period Med_period Lo_period)

    The HI, MED & LO meters report periods. This overrides the values in the configuration file.
    The units are in frames (1 frame = 2/3ms). The report periods must be mutiples of the respective update periods.

## Usage example:

>*./telemetry_core -c ./config/telemetry_configuration.json -i 172.23.100.178:1234*
