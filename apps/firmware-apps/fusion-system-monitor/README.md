# fusion-system-monitor
System monitor FW app, based on Fusion DSP 

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


Doctest was a dependency, but it is now imported as a submodule and doesn't
need to be installed on the system.

To build using submodules, need to have cloned this repo using the
`--recurse-submodules` option.  Otherwise, after you clone it, you need to
run `git submodule update --init --recursive`.