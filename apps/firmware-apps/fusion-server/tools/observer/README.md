# UDP JSON Observer

A lightweight UDP-based JSON value monitor that supports nested object paths and array indexing.

## Building for ARM64

### Create a Builder Instance
```bash
multipass launch -n arm-builder -c 2 -m 4G -d 10G --cloud-init - << EOF
#cloud-config
package_update: true
package_upgrade: false
packages:
 - g++
 - build-essential
 - libjsoncpp-dev
 - libspdlog-dev
 - libcurl4-openssl-dev
 - libboost-dev
 - libboost-program-options-dev
 - libjack-jackd2-dev
 - libsndfile1-dev

runcmd:
 - which g++
 - g++ --version
 - ld --version
EOF
```

### Setup Build Environment
```bash
# Create the target directory
multipass exec arm-builder -- mkdir -p observer

# Copy the source to the instance and build
multipass transfer Makefile arm-builder:observer/Makefile
multipass transfer observer.* arm-builder:observer/
multipass exec arm-builder -- bash -c "cd observer; make arm64"

# Copy the binary to fusion1
multipass transfer arm-builder:observer/build/arm64/observer /tmp
multipass transfer /tmp/observer fusion1:/tmp
multipass exec fusion1 -- sudo mv /tmp/observer /usr/local/bin
```

## Usage

Basic syntax:
```bash
/usr/local/bin/observer <server_ip> <port> <path>
```
There is an options --verbose argument which enables debug output.

The observer supports several path notation formats:

### Simple Key Path
Monitor a nested object value:
```bash
/usr/local/bin/observer 127.0.0.1 7947 settings.audio.volume
```

### Array Index Path
Monitor a specific array element:
```bash
/usr/local/bin/observer 127.0.0.1 7947 settings.audio.peq1.gain[2]
```

### Combined Object and Array Path
Monitor nested array elements within objects:
```bash
/usr/local/bin/observer 127.0.0.1 7947 devices[0].channel.volume
/usr/local/bin/observer 127.0.0.1 7947 mixer.inputs[3].effects[1].param
```

## Path Format

The path can include:
- Dot notation for object properties: `parent.child.property`
- Array indices in square brackets: `array[0]`
- Any combination of objects and arrays: `parent.array[0].child.items[2].value`

## Example Output

When monitoring a path, changes will be displayed with timestamps:

```
14:23:45 settings.audio.volume changed from: 0.5 to: 0.7
14:23:47 settings.audio.peq1.gain[2] changed from: -6.0 to: -3.0
14:23:50 devices[0].channel.volume changed from: 0.8 to: 0.6
```

## Notes

- Array indices start at 0
- Invalid array indices will be reported as errors
- The observer automatically creates missing objects and arrays in the path
- Arrays are automatically resized to accommodate the specified index