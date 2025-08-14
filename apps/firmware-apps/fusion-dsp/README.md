Fusion DSP
==========

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

Building Fusion DSP depends on the following:

- JACK Audio Connection Kit
- Boost
- spdlog
- libsndfile
- libsamplerate
- jsoncpp

To install on macOS:

~~~
brew install jack boost spdlog libsndfile libsamplerate jsoncpp
~~~

To install on Debian-based Linux:

~~~
sudo apt update
sudo apt install jackd libjack-jackd2-dev libboost-dev libspdlog-dev \
    libsndfile1 libsndfile1-dev libsamplerate0 libsamplerate0-dev \
    libjsoncpp-dev libboost-program-options-dev
sudo ln -s /usr/include/jsoncpp/json/ /usr/include/json
~~~

Doctest was a dependency, but it is now imported as a submodule and doesn't
need to be installed on the system.

To build using submodules, need to have cloned this repo using the
`--recurse-submodules` option.  Otherwise, after you clone it, you need to
run `git submodule update --init --recursive`.


Running with the Fusion Server
------------------------------

Here are the steps needed to run the DSP on a Mac, communicating with the
Fusion Server.

First, build and run the Fusion Server as described in the fusion-services
repo: <https://github.com/BoseProfessional/fusion-services>.  This does not
need to run on locally: the server just needs to be available on the network.

Start the JACK server.  This is easiest to do using `qjackctl`.  Click the
"Settings" button and ensure the sample rate is set to 48 kHz and the frame size to
256.  For the interface, select the audio device you want to play back through,
such as "BuiltInSpeakerDevice".  Then press the "Start" button to start JACK.

A simplified version of the first prototype configuration is included in
`config/prototype0.json`.  This uses a pink noise generator, which goes through
a tone control block, a gain block, and a limiter before being played to the
selected output device.

Check the volume level of your output device, especially if wearing headphones!

Start the DSP using the following command (replacing the IP address in the `-s`
argument with the IP address through which the Fusion Server can be reached):

~~~
DYLD_LIBRARY_PATH=libs/onnxruntime-osx-universal2-1.17.0/lib/: ./build/fusion_dsp -c config/prototype0.json -s 192.168.1.100
~~~

You should hear pink noise.  You can adjust some of the dynamic parameters of
the DSP blocks, such as:

~~~
curl --location '192.168.1.100:8080/setValue' --header 'Content-Type: application/json' --data '{ "settings": { "audio": { "tone_eq1": { "high_gain": 6.0 } } } }'
~~~

Similar commands can be used to set:

- "tone_eq1", "low_gain" between -15.0 and 15.0
- "tone_eq1", "mid_gain" between -15.0 and 15.0
- "tone_eq1", "low_gain" between -15.0 and 15.0
- "tone_eq1", "bypass" to true or false
- "gain1", "gain" between -60.0 and 12.0
- "gain1", "mute" to true or false

You should hear audible changes in the noise output.

If you quit the DSP (using ctrl-C) and restart, you will notice that it will
resume with the latest settings that you applied.

