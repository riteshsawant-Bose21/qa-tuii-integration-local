# Makefile for Fusion IO kernel module

# Module name
obj-m += fusion_io.o

# Source files
fusion_io-y := fusion_io_device.o \
               fusion_io_config.o \
               fusion_io_sysfs.o 

# Default target
all:
	$(MAKE) -C $(KDIR) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) modules

# Clean target
clean:
	$(MAKE) -C $(KDIR) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) clean
	rm -f *.o *.ko *.mod.c *.symvers *.order .*.cmd
	rm -rf .tmp_versions

.PHONY: all clean
