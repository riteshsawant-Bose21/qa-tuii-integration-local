# Makefile for Fusion GPT kernel module

# Module name
obj-m += fusion_gpt.o

# Source files
fusion_gpt-y := fusion_gpt_dr.o 

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
