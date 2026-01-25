#!/bin/bash
# RPM package creation script for AIC8800 driver
# Supports Red Hat, Fedora, CentOS, Rocky, AlmaLinux, SUSE, and derivatives

set -e

# Source distribution detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/detect_distro.sh"

detect_distribution

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
echo "Building driver..."
cd "$(dirname "$(dirname "$SCRIPT_DIR")")"
make clean
make build

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
make

%install
cd drivers/aic8800
make install DESTDIR=%{buildroot}

# Install firmware
mkdir -p %{buildroot}/lib/firmware/aic8800D80
cp -r fw/aic8800D80/* %{buildroot}/lib/firmware/aic8800D80/

# Install udev rules
mkdir -p %{buildroot}/etc/udev/rules.d
cp tools/aic.rules %{buildroot}/etc/udev/rules.d/

%files
/lib/modules/*/kernel/drivers/net/wireless/aic8800/
/lib/firmware/aic8800D80/
/etc/udev/rules.d/aic.rules

%post
/sbin/depmod -a
udevadm trigger
udevadm control --reload

%postun
/sbin/depmod -a
udevadm control --reload

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
