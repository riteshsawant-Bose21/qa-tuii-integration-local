# OCA Lite Project Root Makefile

.PHONY: all device controller clean clean-device clean-controller help

help:
	@echo "OCA Lite Build System"
	@echo "===================="
	@echo "Available targets:"
	@echo "  device     - Build OCA device application"
	@echo "  controller - Build OCA controller application"
	@echo "  all        - Build both device and controller"
	@echo "  clean      - Clean all build artifacts"
	@echo "  help       - Show this help message"

all: device controller

device:
	@echo "Building OCA Device..."
	$(MAKE) -C app/OCALite

controller:
	@echo "Building OCA Controller..."
	$(MAKE) -C app/OCALiteController

clean: clean-device clean-controller

clean-device:
	@echo "Cleaning OCA Device..."
	$(MAKE) -C app/OCALite clean

clean-controller:
	@echo "Cleaning OCA Controller..."
	$(MAKE) -C app/OCALiteController clean
