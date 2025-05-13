# Makefile for Fusion Connect kernel module

# Module name
obj-m += fusion_connect.o

# Source files
fusion_connect-y := fusion_connect_alsa.o \
                    fusion_connect_manager.o \
                    fusion_connect_module.o \
                    fusion_connect_netfilter.o \
                    fusion_connect_rtp.o

# Default target
all:
	$(MAKE) -C $(KDIR) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) modules

# Clean target
clean:
	$(MAKE) -C $(KDIR) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) clean
	rm -f *.o *.ko *.mod.c *.symvers *.order .*.cmd
	rm -rf .tmp_versions

.PHONY: all clean
