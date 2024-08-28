Mune DSP
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

Building MuneDSP depends on the following:

- JACK Audio Connection Kit
- Boost
- spdlog
- libsndfile

To install on macOS:

~~~
brew install jack boost spdlog libsndfile
~~~

To install on Debian-based Linux:

~~~
sudo apt update
sudo apt install jackd libjack-jackd2-dev libboost-dev libspdlog-dev \
    libsndfile1 libsndfile1-dev
~~~

Doctest was a dependency, but it is now imported as a submodule and doesn't
need to be installed on the system.

To build using submodules, need to have cloned this repo using the
`--recurse-submodules` option.  Otherwise, after you clone it, you need to
run `git submodule update --init --recursive`.


Loading DSP Code to the Mune device
-----------------------------------

VB1 does not support passwordless scp command.  To work around this limitation it is helpful to install the [sshpass](https://www.cyberciti.biz/faq/how-to-install-sshpass-on-macos-os-x/) utility.

The loadDSP.sh script can then be used to load the new DSP code.

To start the newly loaded DSP code use the following commands:

shh into the VB1 and:

~~~	
killall AudioProcess
jackd -d alsa -P hw:1,0 -n 2 -r 48000 -p 32 &
./jack_dep -A &
jack_connect dante_in:capture_1 dante_out:playback_1
jack_connect dante_in:capture_2 dante_out:playback_2
~~~
