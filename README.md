# AIC8800 Linux Driver

This project provides a Linux driver for the AIC8800 chipset, supporting both USB and SDIO interfaces.

## Table of Contents
- [Project Overview](#project-overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
  - [Compiling the Driver](#compiling-the-driver)
  - [Installing the Driver](#installing-the-driver)
- [Usage](#usage)
- [License](#license)

## Project Overview

The AIC8800 Linux Driver supports the AIC8800 chipset for wireless communication, enabling functionality on devices using Linux-based operating systems. This driver is compatible with various kernel versions and can be used with different hardware configurations, such as USB or SDIO interfaces.

## Features

- Support for USB interface
- FullMAC driver with 802.11ac capabilities
- WPA/WPA2 encryption
- MAC randomization support
- Power management features (DCDC_VRF mode)
- WPA3 compatibility (for kernels supporting it)
- MU-MIMO support (requires compatible firmware)
- Wireless extensions support
- USB combo Wi-Fi + Bluetooth devices (via `aic_load_fw` and `CONFIG_USB_BT`)

## Requirements

To compile and install this driver, ensure the following dependencies are installed:

- Linux kernel headers and development files
- GCC or Clang/LLVM (auto-detected based on kernel build)
- Make
- Git (for cloning the repository)
- checkinstall (for creating DEB/RPM packages)

```bash
# Debian/Ubuntu/PikaOS example
sudo apt install linux-headers-$(uname -r) build-essential git checkinstall

# Fedora example
sudo dnf install kernel-devel kernel-headers gcc make git rpm-build
```

**Note:** The build system automatically detects which compiler (gcc or clang) was used to build your kernel and uses the same compiler for building the driver. This ensures compatibility.

## Installation

### Compiling the Driver

1. Clone the repository:

   ```bash
   git clone git@github.com:goecho/aic8800_linux_drvier.git
   cd aic8800-linux-driver
   ```

2. Compile the driver:

   ```bash
   make
   ```

   This will automatically detect whether your kernel was built with gcc or clang and use the appropriate compiler. The necessary kernel modules (`aic8800_fdrv.ko` and `aic_load_fw.ko`) will be generated.

   **Manual compiler override (optional):**

   If you need to override the auto-detection, you can manually specify the compiler:

   ```bash
   # Force clang
   make LLVM=1 LLVM_IAS=1 CC=clang

   # Force gcc
   make CC=gcc
   ```

### Installing the Driver

3. Install the compiled driver:

   ```bash
   sudo make install
   ```

   This will:
   - Install the kernel modules
   - Copy firmware files to `/lib/firmware/aic8800D80/`
   - Install udev rules for USB mode switching
   - **Configure auto-load on boot** via `/etc/modules-load.d/aic8800.conf`

4. Load the driver (or reboot for automatic loading):

   ```bash
   sudo modprobe aic8800_fdrv
   ```

   For USB combo Wi-Fi + Bluetooth devices, also load:

   ```bash
   sudo modprobe aic_load_fw
   ```

   **Note:** After installation, the modules will automatically load on every boot. Manual loading is only needed for the first time before rebooting.

5. To verify the driver is loaded, run:

   ```bash
   lsmod | grep aic8800_fdrv
   ```

### Package Installation (Recommended)

For easier installation and management, you can create distribution-specific packages. The build system automatically detects your compiler and includes auto-load configuration.

#### Debian/Ubuntu/PikaOS (DEB Package)

1. Create the DEB package:

   ```bash
   make deb
   ```

2. Install the package:

   ```bash
   sudo dpkg -i aic8800-driver_1.2.0-1_amd64.deb
   ```

   **Note:** If you encounter dependency warnings about linux-headers, you can safely ignore them with:

   ```bash
   sudo dpkg -i --force-depends aic8800-driver_1.2.0-1_amd64.deb
   ```

#### Fedora/RHEL/Rocky/AlmaLinux (RPM Package)

1. Create the RPM package:

   ```bash
   make rpm
   ```

2. Install the package:

   ```bash
   sudo rpm -i aic8800-driver-1.2.0-1.x86_64.rpm
   # or
   sudo dnf install aic8800-driver-1.2.0-1.x86_64.rpm
   ```

#### Arch Linux/Manjaro/EndeavourOS (PKG Package)

1. Create the Arch package:

   ```bash
   make arch
   ```

2. Install the package:

   ```bash
   sudo pacman -U aic8800-driver-1.2.0-1-x86_64.pkg.tar.zst
   ```

#### Auto-detect and Build for Your Distribution

```bash
make package
```

This will automatically detect your distribution and create the appropriate package type.

#### What Packages Include

All packages automatically:
- Install the kernel modules
- Copy firmware files
- Configure udev rules
- **Set up auto-load on boot** via `/etc/modules-load.d/aic8800.conf`
- Run depmod to update module dependencies
- Use the correct compiler (auto-detected)

### Uninstalling the Driver

If you need to remove the driver:

```bash
# If installed from source
sudo make uninstall

# If installed from DEB package
sudo dpkg -r aic8800-driver
```

## Usage

Once the driver is installed and loaded, the AIC8800 chipset will be automatically recognized by the Linux system. You can verify the wireless device is working by checking the network interfaces:

```bash
ip link
```

You can also manage the wireless device using standard Linux network management tools like `iwconfig`, `ifconfig`, or `nmcli`.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
