#!/bin/bash
# DEB package creation script for AIC8800 driver
# Supports Ubuntu, Debian, and derivatives

set -e

# Source distribution detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/detect_distro.sh"

detect_distribution

if [ "$DISTRO_FAMILY" != "debian" ]; then
    echo "Warning: This script is designed for Debian-based distributions"
    echo "Detected: $DISTRO_NAME ($DISTRO_FAMILY)"
    echo "Continuing anyway..."
fi

# Package configuration
PACKAGE_NAME="aic8800-driver"
PACKAGE_VERSION="1.2.0"
PACKAGE_ARCH="$ARCH"
PACKAGE_MAINTAINER="AIC Driver Team <aic-driver@example.com>"
PACKAGE_DESCRIPTION="AIC8800 Wi-Fi Driver for Linux"
PACKAGE_LONG_DESCRIPTION="Linux kernel driver for AIC8800 wireless chipset supporting USB and SDIO interfaces with 802.11ac capabilities."

# Check dependencies
echo "Checking dependencies..."
if ! command -v checkinstall >/dev/null 2>&1; then
    echo "Error: checkinstall is not installed"
    echo "Please install it with: sudo apt install checkinstall"
    exit 1
fi

if ! command -v dpkg >/dev/null 2>&1; then
    echo "Error: dpkg is not installed"
    echo "Please install it with: sudo apt install dpkg"
    exit 1
fi

# Build the driver first
echo "Building driver..."
cd "$(dirname "$(dirname "$SCRIPT_DIR")")"
make clean
make build

if [ $? -ne 0 ]; then
    echo "Error: Driver build failed"
    exit 1
fi

# Create DEB package
echo "Creating DEB package..."
cd drivers/aic8800

checkinstall \
    --pkgname="$PACKAGE_NAME" \
    --pkgversion="$PACKAGE_VERSION" \
    --pkgarch="$PACKAGE_ARCH" \
    --pkgsource="AIC8800 Linux Driver" \
    --maintainer="$PACKAGE_MAINTAINER" \
    --provides="aic8800-driver" \
    --requires="linux-headers-$(uname -r),firmware-misc-nonfree" \
    --conflicts="aic8800-driver" \
    --replaces="aic8800-driver" \
    --install=no \
    --fstrans=no \
    --default \
    --pakdir=../.. \
    --backup=no \
    --deldoc=no \
    --deldesc=no \
    --delspec=no \
    --pkglicense="MIT" \
    --pkgrelease="1" \
    --pkgnotes="AIC8800 Linux Driver for $DISTRO_NAME $DISTRO_VERSION" \
    --install-script=../../install_setup.sh \
    --remove-script=../../uninstall_setup.sh \
    make install

if [ $? -eq 0 ]; then
    echo "DEB package created successfully!"
    echo "Package: ${PACKAGE_NAME}_${PACKAGE_VERSION}_${PACKAGE_ARCH}.deb"
    echo "Install with: sudo dpkg -i ${PACKAGE_NAME}_${PACKAGE_VERSION}_${PACKAGE_ARCH}.deb"
else
    echo "Error: Failed to create DEB package"
    exit 1
fi
