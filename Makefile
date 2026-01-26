# Auto-detect kernel compiler
SHELL := /bin/bash

# Detect if kernel was built with clang
KERNEL_COMPILER := $(shell cat /proc/version 2>/dev/null | grep -o "clang version" || echo "gcc")

# Variables
INSTALL_SCRIPT = ./install_setup.sh
UNINSTALL_SCRIPT = ./uninstall_setup.sh
BUILD_DIR = drivers/aic8800
TARGET = aic8800_fdrv.ko
PACKAGE_NAME = aic8800-driver
PACKAGE_VERSION = 1.2.0
PACKAGE_ARCH = $(shell dpkg --print-architecture 2>/dev/null || echo "amd64")

# Set compiler based on detection (can be overridden by user)
ifeq ($(origin CC),default)
    # CC is not set by user, auto-detect
    ifeq ($(KERNEL_COMPILER),clang version)
        LLVM := 1
        LLVM_IAS := 1
        CC := clang
        $(info Detected kernel built with clang - using LLVM toolchain)
    else
        CC := gcc
        $(info Detected kernel built with gcc)
    endif
else
    # CC was set by user, respect it
    $(info Using user-specified compiler: $(CC))
endif

# Build EXTRA_MAKE_VARS from detected or user-provided values
EXTRA_MAKE_VARS =
ifneq ($(LLVM),)
EXTRA_MAKE_VARS += LLVM=$(LLVM)
endif
ifneq ($(LLVM_IAS),)
EXTRA_MAKE_VARS += LLVM_IAS=$(LLVM_IAS)
endif
ifneq ($(CC),)
EXTRA_MAKE_VARS += CC=$(CC)
endif

# Default target to build the driver
all: build

# Build the driver
build:
	@echo "Compiling the driver..."
	cd $(BUILD_DIR) && make $(EXTRA_MAKE_VARS)

# Install the driver using the install script
install: build
	@echo "Installing the driver using install_setup.sh..."
	cd $(BUILD_DIR) && make $(EXTRA_MAKE_VARS) install
	@bash $(INSTALL_SCRIPT)

# Uninstall the driver using the uninstall script
uninstall:
	@echo "Uninstalling the driver using uninstall_setup.sh..."
	cd $(BUILD_DIR) && make uninstall
	@bash $(UNINSTALL_SCRIPT)

# Create DEB package
deb: build
	@echo "Creating DEB package..."
	@bash scripts/package_deb.sh

# Create RPM package
rpm: build
	@echo "Creating RPM package..."
	@bash scripts/package_rpm.sh

# Create Arch Linux package
arch: build
	@echo "Creating Arch Linux package..."
	@bash scripts/package_arch.sh

# Create package for detected distribution
package: build
	@echo "Creating package for detected distribution..."
	@bash scripts/package_all.sh

# Create all package formats
packages: build
	@echo "Creating all package formats..."
	@echo "Creating DEB package..."
	@bash scripts/package_deb.sh || echo "DEB package creation failed"
	@echo "Creating RPM package..."
	@bash scripts/package_rpm.sh || echo "RPM package creation failed"
	@echo "Creating Arch package..."
	@bash scripts/package_arch.sh || echo "Arch package creation failed"
	@echo "Package creation completed!"

# Clean the build artifacts
clean:
	@echo "Cleaning the build artifacts..."
	cd $(BUILD_DIR) && make clean
	$(MAKE) -C $(BUILD_DIR) clean
	@echo "Cleaning package files..."
	rm -f *.deb *.tar.gz *.tgz

# Phony targets to avoid conflicts with files
.PHONY: all build install uninstall clean deb rpm arch package packages
