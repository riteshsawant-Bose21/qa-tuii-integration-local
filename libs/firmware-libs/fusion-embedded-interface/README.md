Fusion Embedded Interface Library
=================================

This library provides common functionality used by fusion-dsp,
fusion-system-monitor, and fusion-telemetry-core.  It includes:

- JSON parsing and abstraction of configuration data and parameter data received
    from the fusion server.
- Definition of messages passed between fusion-telemetry-core and its peers.
- The shared memory interface between fusion-telemetry-core and its peers.

Dependencies:

- Boost
- spdlog

This library must be built before attempting to build fusion-dsp,
fusion-system-monitor, and fusion-telemetry-core.

Building
--------

To configure the build natively for the platform on which the build is done,
first run:

~~~
python3 waf configure
~~~

The build needs to be configured after cloning the repo, or any time you change
`wscript`.

To build the program, run:

~~~
python3 waf build
~~~

To clean the build, remove `build/` and its contents.

To build for Fusion hardware, you need to set up to use the SDK for,
cross-compilation and configure the build to use it.

~~~
. /opt/bosepro-fusion/6.12-styhead/environment-setup-armv8a-poky-linux
~~~

This needs to be done once per login.

When configuring the build:

~~~
python3 waf configure --platform=varmini
~~~

The remaining build steps are the same.

