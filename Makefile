# Variables
INSTALL_SCRIPT = ./install_setup.sh
UNINSTALL_SCRIPT = ./uninstall_setup.sh
BUILD_DIR = drivers/aic8800
TARGET = aic8800_fdrv.ko
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

# Clean the build artifacts
clean:
	@echo "Cleaning the build artifacts..."
	cd $(BUILD_DIR) && make clean
	$(MAKE) -C $(BUILD_DIR) clean

# Phony targets to avoid conflicts with files
.PHONY: all build install uninstall clean
