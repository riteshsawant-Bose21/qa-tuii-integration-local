# Makefile for Fusion Connect kernel module

# Module name
obj-m += fusion_connect.o

# Source files
fusion_connect-y := fusion_connect_alsa.o \
                    fusion_connect_manager.o \
                    fusion_connect_module.o \
                    fusion_connect_netfilter.o \
                    fusion_connect_rtp.o

# Kernel build directory (set by KDIR environment variable or passed via make)
KDIR ?= /path/to/your/kernel/source

# Cross-compiler prefix (set by CROSS_COMPILE environment variable or passed via make)
CROSS_COMPILE ?= /path/to/your/sdk/sysroots/x86_64-pokysdk-linux/usr/bin/aarch64-poky-linux/aarch64-poky-linux-

# Architecture (set by ARCH environment variable or passed via make)
ARCH ?= arm64

# Default target
all:
	$(MAKE) -C $(KDIR) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) modules

# Clean target
clean:
	$(MAKE) -C $(KDIR) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) clean
	rm -f *.o *.ko *.mod.c *.symvers *.order .*.cmd
	rm -rf .tmp_versions

.PHONY: all clean
