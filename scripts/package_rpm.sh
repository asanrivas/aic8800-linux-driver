#!/bin/bash
# RPM package creation script for AIC8800 driver
# Supports Red Hat, Fedora, CentOS, Rocky, AlmaLinux, SUSE, and derivatives

set -e

# Source distribution detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/detect_distro.sh"
source "${SCRIPT_DIR}/detect_compiler.sh"

detect_distribution
detect_kernel_compiler

if [ "$DISTRO_FAMILY" != "redhat" ] && [ "$DISTRO_FAMILY" != "suse" ]; then
    echo "Warning: This script is designed for RPM-based distributions"
    echo "Detected: $DISTRO_NAME ($DISTRO_FAMILY)"
    echo "Continuing anyway..."
fi

# Package configuration
PACKAGE_NAME="aic8800-driver"
PACKAGE_VERSION="1.2.0"
PACKAGE_ARCH="$ARCH"
PACKAGE_RELEASE="1"
PACKAGE_MAINTAINER="AIC Driver Team"
PACKAGE_DESCRIPTION="AIC8800 Wi-Fi Driver for Linux"
PACKAGE_LONG_DESCRIPTION="Linux kernel driver for AIC8800 wireless chipset supporting USB and SDIO interfaces with 802.11ac capabilities."

# Check dependencies
echo "Checking dependencies..."
if ! command -v rpmbuild >/dev/null 2>&1; then
    echo "Error: rpmbuild is not installed"
    if [ "$DISTRO_FAMILY" = "redhat" ]; then
        echo "Please install it with: sudo dnf install rpm-build"
    elif [ "$DISTRO_FAMILY" = "suse" ]; then
        echo "Please install it with: sudo zypper install rpm-build"
    fi
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

# Create RPM build directory structure
BUILD_ROOT="/tmp/aic8800-rpm-build"
RPM_SOURCES="$BUILD_ROOT/SOURCES"
RPM_SPECS="$BUILD_ROOT/SPECS"
RPM_BUILD="$BUILD_ROOT/BUILD"
RPM_RPMS="$BUILD_ROOT/RPMS"

mkdir -p "$RPM_SOURCES" "$RPM_SPECS" "$RPM_BUILD" "$RPM_RPMS"

# Create spec file
cat > "$RPM_SPECS/aic8800-driver.spec" << EOF
Name:           $PACKAGE_NAME
Version:        $PACKAGE_VERSION
Release:        $PACKAGE_RELEASE%{?dist}
Summary:        $PACKAGE_DESCRIPTION
License:        MIT
URL:            https://github.com/asanrivas/aic8800-linux-driver
Source0:        %{name}-%{version}.tar.gz
BuildArch:      $PACKAGE_ARCH
BuildRequires:  kernel-devel, gcc, make
Requires:       kernel-headers, firmware-misc-nonfree
Conflicts:      %{name}
Provides:       %{name}

%description
$PACKAGE_LONG_DESCRIPTION

%prep
%setup -q

%build
cd drivers/aic8800
# Auto-detect and use appropriate compiler
if grep -qi "clang" /proc/version 2>/dev/null; then
    make LLVM=1 LLVM_IAS=1 CC=clang
else
    make CC=gcc
fi

%install
cd drivers/aic8800
# Auto-detect and use appropriate compiler
if grep -qi "clang" /proc/version 2>/dev/null; then
    make install DESTDIR=%{buildroot} LLVM=1 LLVM_IAS=1 CC=clang
else
    make install DESTDIR=%{buildroot} CC=gcc
fi

# Install firmware
cd ../..
mkdir -p %{buildroot}/lib/firmware/aic8800D80
cp -r fw/aic8800D80/* %{buildroot}/lib/firmware/aic8800D80/

# Install udev rules
mkdir -p %{buildroot}/etc/udev/rules.d
cp tools/aic.rules %{buildroot}/etc/udev/rules.d/

# Install setup scripts
mkdir -p %{buildroot}/usr/share/aic8800-driver
cp install_setup.sh %{buildroot}/usr/share/aic8800-driver/
cp uninstall_setup.sh %{buildroot}/usr/share/aic8800-driver/
cp -r fw %{buildroot}/usr/share/aic8800-driver/
cp -r tools %{buildroot}/usr/share/aic8800-driver/

%files
/lib/modules/*/kernel/drivers/net/wireless/aic8800/
/lib/firmware/aic8800D80/
/etc/udev/rules.d/aic.rules
/usr/share/aic8800-driver/

%post
/sbin/depmod -a
# Run install setup script
cd /usr/share/aic8800-driver
bash ./install_setup.sh || true

%preun
# Run uninstall setup script
cd /usr/share/aic8800-driver
bash ./uninstall_setup.sh || true

%postun
/sbin/depmod -a

%changelog
* $(date '+%a %b %d %Y') $PACKAGE_MAINTAINER - $PACKAGE_VERSION-$PACKAGE_RELEASE
- Initial package for $DISTRO_NAME $DISTRO_VERSION
EOF

# Create source tarball
echo "Creating source tarball..."
cd "$(dirname "$SCRIPT_DIR")/.."
tar -czf "$RPM_SOURCES/aic8800-driver-$PACKAGE_VERSION.tar.gz" \
    --exclude='.git' \
    --exclude='*.deb' \
    --exclude='*.rpm' \
    --exclude='*.pkg.tar.*' \
    --exclude='build' \
    --exclude='dist' \
    .

# Build RPM package
echo "Building RPM package..."
cd "$RPM_SPECS"
rpmbuild --define "_topdir $BUILD_ROOT" \
         --define "_builddir $RPM_BUILD" \
         --define "_rpmdir $RPM_RPMS" \
         --define "_sourcedir $RPM_SOURCES" \
         --define "_specdir $RPM_SPECS" \
         -ba aic8800-driver.spec

if [ $? -eq 0 ]; then
    echo "RPM package created successfully!"
    RPM_FILE=$(find "$RPM_RPMS" -name "*.rpm" | head -1)
    if [ -n "$RPM_FILE" ]; then
        cp "$RPM_FILE" "$(dirname "$SCRIPT_DIR")/.."
        echo "Package: $(basename "$RPM_FILE")"
        echo "Install with: sudo rpm -i $(basename "$RPM_FILE")"
    fi
else
    echo "Error: Failed to create RPM package"
    exit 1
fi

# Cleanup
rm -rf "$BUILD_ROOT"
