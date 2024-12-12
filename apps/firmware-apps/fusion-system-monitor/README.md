Fusion System Monitor
========

Building
--------

To configure the build, first run:

~~~
python3 waf configure
~~~

The build needs to be configured any time you change `wscript`.


To build the program, run:

~~~
python3 waf build
~~~

To clean up the build, simply remove the `build/` directory and its contents.


### Building for the Variscite i.MX 8M Mini Development Board

To build for the Variscite board, you need to have the Variscite SDK and
cross-compiler installed (built with Yocto).  Once it's installed, you
need to run (once per login):

~~~
source /opt/fsl-imx-xwayland/6.1-mickledore/environment-setup-armv8a-poky-linux
~~~

Then, you can configure the build using:

~~~
python3 waf configure --platform=varmini
~~~

Running `python3 waf build` does not require a platform argument.


Dependencies
------------

Building Fusion System Monitor depends on the following:

- Boost
- spdlog

To install on macOS:

~~~
brew install jack boost spdlog libsndfile
~~~

To install on Debian-based Linux:

~~~
sudo apt update
sudo apt install libboost-dev libspdlog-dev
~~~
