# Makefile for Fusion Connect kernel module

# Module name
obj-m += fusion_connect.o

# Source files
fusion_connect-y := fusion_connect_alsa.o \
                    fusion_connect_manager.o \
                    fusion_connect_module.o \
                    fusion_connect_netfilter.o \
                    fusion_connect_rtp.o \
					fusion_connect_metrics.o 

SRC ?= $(shell pwd)

# Default target
all:
	$(MAKE) -C $(KERNEL_SRC) M=$(SRC) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) modules
	
modules_install:
	$(MAKE) -C $(KERNEL_SRC) M=$(SRC) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) modules_install

# Clean target
clean:
	$(MAKE) -C $(KERNEL_SRC) M=$(SRC) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) clean
	rm -f *.o *.ko *.mod.c *.symvers *.order .*.cmd
	rm -rf .tmp_versions

.PHONY: all clean
