multipass exec arm-builder -- mkdir -p observer
multipass transfer tools/observer/Makefile arm-builder:observer/Makefile
multipass transfer tools/observer/observer.cpp arm-builder:observer/observer.cpp
multipass exec arm-builder -- bash -c "cd observer; make arm64"
multipass transfer arm-builder:observer/build/arm64/observer /tmp
multipass transfer /tmp/observer fusion1:/tmp
multipass exec fusion1 -- sudo mv /tmp/observer /usr/local/bin
