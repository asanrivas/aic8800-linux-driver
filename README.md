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
- GCC and Make
- Clang/LLVM (optional, for clang builds)
- Git (for cloning the repository)

```bash
# Fedora example
sudo dnf install kernel-devel kernel-headers gcc make git
```

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

   This will generate the necessary kernel modules (`aic8800_fdrv.ko` and `aic_load_fw.ko`).

   To build with clang/LLVM:

   ```bash
   make LLVM=1 LLVM_IAS=1 CC=clang
   ```

### Installing the Driver

3. Install the compiled driver:

   ```bash
   sudo make install
   ```

4. Load the driver:

   ```bash
   sudo modprobe aic8800_fdrv
   ```

   For USB combo Wi-Fi + Bluetooth devices, also load:

   ```bash
   sudo modprobe aic_load_fw
   ```

5. To verify the driver is loaded, run:

   ```bash
   lsmod | grep aic8800_fdrv
   ```

### Uninstalling the Driver

If you need to remove the driver:

```bash
sudo make uninstall
```

## Usage

Once the driver is installed and loaded, the AIC8800 chipset will be automatically recognized by the Linux system. You can verify the wireless device is working by checking the network interfaces:

```bash
ip link
```

You can also manage the wireless device using standard Linux network management tools like `iwconfig`, `ifconfig`, or `nmcli`.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
