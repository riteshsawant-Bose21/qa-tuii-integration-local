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
sudo apt install jackd libjack-jackd2-dev libboost-dev libspdlog-dev libsndfile1 libsndfile1-dev
~~~


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
