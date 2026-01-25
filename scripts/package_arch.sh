#!/bin/bash
# Arch Linux PKGBUILD creation script for AIC8800 driver
# Supports Arch Linux, Manjaro, EndeavourOS, and derivatives

set -e

# Source distribution detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/detect_distro.sh"

detect_distribution

if [ "$DISTRO_FAMILY" != "arch" ]; then
    echo "Warning: This script is designed for Arch-based distributions"
    echo "Detected: $DISTRO_NAME ($DISTRO_FAMILY)"
    echo "Continuing anyway..."
fi

# Package configuration
PACKAGE_NAME="aic8800-driver"
PACKAGE_VERSION="1.2.0"
PACKAGE_RELEASE="1"
PACKAGE_ARCH="$ARCH"
PACKAGE_MAINTAINER="AIC Driver Team"
PACKAGE_DESCRIPTION="AIC8800 Wi-Fi Driver for Linux"
PACKAGE_LONG_DESCRIPTION="Linux kernel driver for AIC8800 wireless chipset supporting USB and SDIO interfaces with 802.11ac capabilities."

# Check dependencies
echo "Checking dependencies..."
if ! command -v makepkg >/dev/null 2>&1; then
    echo "Error: makepkg is not installed"
    echo "Please install it with: sudo pacman -S base-devel"
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

# Create PKGBUILD
echo "Creating PKGBUILD..."
cat > PKGBUILD << EOF
# Maintainer: $PACKAGE_MAINTAINER
pkgname=$PACKAGE_NAME
pkgver=$PACKAGE_VERSION
pkgrel=$PACKAGE_RELEASE
pkgdesc="$PACKAGE_DESCRIPTION"
arch=('$PACKAGE_ARCH')
url="https://github.com/asanrivas/aic8800-linux-driver"
license=('MIT')
depends=('linux-headers' 'firmware-misc-nonfree')
makedepends=('linux-headers' 'gcc' 'make')
provides=('aic8800-driver')
conflicts=('aic8800-driver')
source=("\${pkgname}-\${pkgver}.tar.gz")
sha256sums=('SKIP')

build() {
    cd "\${srcdir}/\${pkgname}-\${pkgver}"
    cd drivers/aic8800
    make
}

package() {
    cd "\${srcdir}/\${pkgname}-\${pkgver}"

    # Install kernel modules
    cd drivers/aic8800
    make install DESTDIR="\${pkgdir}"

    # Install firmware
    cd ../..
    mkdir -p "\${pkgdir}/lib/firmware/aic8800D80"
    cp -r fw/aic8800D80/* "\${pkgdir}/lib/firmware/aic8800D80/"

    # Install udev rules
    mkdir -p "\${pkgdir}/etc/udev/rules.d"
    cp tools/aic.rules "\${pkgdir}/etc/udev/rules.d/"

    # Install post-install script
    mkdir -p "\${pkgdir}/usr/lib/systemd/system"
    cat > "\${pkgdir}/usr/lib/systemd/system/aic8800-driver.service" << 'EOS'
[Unit]
Description=AIC8800 Wi-Fi Driver Setup
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'udevadm trigger && udevadm control --reload'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOS
}

post_install() {
    echo "AIC8800 driver installed successfully!"
    echo "Firmware installed to: /lib/firmware/aic8800D80/"
    echo "Udev rules installed to: /etc/udev/rules.d/aic.rules"
    echo "To load the driver, run: sudo modprobe aic8800_fdrv"
    echo "To enable automatic loading: sudo systemctl enable aic8800-driver"
}

post_remove() {
    echo "AIC8800 driver removed successfully!"
    echo "To unload the driver, run: sudo modprobe -r aic8800_fdrv"
}
EOF

# Create source tarball
echo "Creating source tarball..."
tar -czf "${PACKAGE_NAME}-${PACKAGE_VERSION}.tar.gz" \
    --exclude='.git' \
    --exclude='*.deb' \
    --exclude='*.rpm' \
    --exclude='*.pkg.tar.*' \
    --exclude='build' \
    --exclude='dist' \
    --exclude='PKGBUILD' \
    .

# Update checksum
echo "Updating checksum..."
SHA256SUM=$(sha256sum "${PACKAGE_NAME}-${PACKAGE_VERSION}.tar.gz" | cut -d' ' -f1)
sed -i "s/sha256sums=('SKIP')/sha256sums=('$SHA256SUM')/" PKGBUILD

# Build package
echo "Building Arch package..."
makepkg -s --noconfirm

if [ $? -eq 0 ]; then
    echo "Arch package created successfully!"
    PACKAGE_FILE=$(ls -t *.pkg.tar.* | head -1)
    if [ -n "$PACKAGE_FILE" ]; then
        echo "Package: $PACKAGE_FILE"
        echo "Install with: sudo pacman -U $PACKAGE_FILE"
    fi
else
    echo "Error: Failed to create Arch package"
    exit 1
fi
