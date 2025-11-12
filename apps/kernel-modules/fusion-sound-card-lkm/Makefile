# Makefile for Fusion Sound Card and Codec kernel modules triggered by CI

# Module names
obj-m += fusion_sound_card.o
obj-m += fusion_codec.o

EXTRA_CFLAGS := -I$(KERNEL_SRC)

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
