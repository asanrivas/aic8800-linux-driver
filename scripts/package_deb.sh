#!/bin/bash
# DEB package creation script for AIC8800 driver
# Supports Ubuntu, Debian, and derivatives

set -e

# Source distribution detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/detect_distro.sh"
source "${SCRIPT_DIR}/detect_compiler.sh"

detect_distribution
detect_kernel_compiler

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
echo "Building driver with detected compiler: $KERNEL_CC"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"
make clean

# Build with auto-detected compiler settings
if [ "$KERNEL_CC" = "clang" ]; then
    make build LLVM=$LLVM LLVM_IAS=$LLVM_IAS CC=$CC
else
    make build CC=$CC
fi

if [ $? -ne 0 ]; then
    echo "Error: Driver build failed"
    exit 1
fi

# Create DEB package
echo "Creating DEB package..."
cd drivers/aic8800

# Build install command with detected compiler
if [ "$KERNEL_CC" = "clang" ]; then
    INSTALL_CMD="make install LLVM=$LLVM LLVM_IAS=$LLVM_IAS CC=$CC"
else
    INSTALL_CMD="make install CC=$CC"
fi

# Create package using checkinstall
sudo checkinstall \
    --pkgname="$PACKAGE_NAME" \
    --pkgversion="$PACKAGE_VERSION" \
    --pkgarch="$PACKAGE_ARCH" \
    --maintainer="$PACKAGE_MAINTAINER" \
    --provides="aic8800-driver" \
    --requires="linux-headers" \
    --install=no \
    --fstrans=no \
    --default \
    --pakdir=../.. \
    --backup=no \
    --deldoc=yes \
    --deldesc=yes \
    --delspec=yes \
    $INSTALL_CMD

# Run post-package setup on the built package
# Note: checkinstall may add a release number, so find the actual file
cd ../..
DEB_FILE=$(ls -t ${PACKAGE_NAME}_${PACKAGE_VERSION}*.deb 2>/dev/null | head -1)
if [ -n "$DEB_FILE" ] && [ -f "$DEB_FILE" ]; then
    echo ""
    echo "Updating DEB package with setup scripts..."

    # Extract the package
    DEB_BASENAME=$(basename "$DEB_FILE")
    sudo rm -rf /tmp/aic8800-pkg
    sudo mkdir -p /tmp/aic8800-pkg
    sudo dpkg-deb -x "$DEB_FILE" /tmp/aic8800-pkg
    sudo dpkg-deb --control "$DEB_FILE" /tmp/aic8800-pkg/DEBIAN

    # Fix architecture in control file (x86_64 -> amd64)
    sudo sed -i 's/Architecture: x86_64/Architecture: amd64/' /tmp/aic8800-pkg/DEBIAN/control
    sudo tee /tmp/aic8800-pkg/DEBIAN/postinst > /dev/null << 'POSTINST_EOF'
#!/bin/bash
set -e
# Run install setup
cd /usr/share/aic8800-driver
bash ./install_setup.sh || true
exit 0
POSTINST_EOF
    sudo chmod 755 /tmp/aic8800-pkg/DEBIAN/postinst

    # Create prerm script
    sudo tee /tmp/aic8800-pkg/DEBIAN/prerm > /dev/null << 'PRERM_EOF'
#!/bin/bash
set -e
# Run uninstall setup
cd /usr/share/aic8800-driver
bash ./uninstall_setup.sh || true
exit 0
PRERM_EOF
    sudo chmod 755 /tmp/aic8800-pkg/DEBIAN/prerm

    # Copy setup scripts to package
    sudo mkdir -p /tmp/aic8800-pkg/usr/share/aic8800-driver
    sudo cp install_setup.sh /tmp/aic8800-pkg/usr/share/aic8800-driver/
    sudo cp uninstall_setup.sh /tmp/aic8800-pkg/usr/share/aic8800-driver/
    sudo cp -r fw /tmp/aic8800-pkg/usr/share/aic8800-driver/
    sudo cp -r tools /tmp/aic8800-pkg/usr/share/aic8800-driver/

    # Rebuild the package
    sudo dpkg-deb --root-owner-group -b /tmp/aic8800-pkg "$DEB_BASENAME"

    # Cleanup
    sudo rm -rf /tmp/aic8800-pkg

    echo "DEB package updated with install/uninstall scripts!"
    echo "Final package: $DEB_BASENAME"
fi

if [ $? -eq 0 ]; then
    echo "DEB package created successfully!"
    echo "Package: ${PACKAGE_NAME}_${PACKAGE_VERSION}_${PACKAGE_ARCH}.deb"
    echo "Install with: sudo dpkg -i ${PACKAGE_NAME}_${PACKAGE_VERSION}_${PACKAGE_ARCH}.deb"
else
    echo "Error: Failed to create DEB package"
    exit 1
fi
