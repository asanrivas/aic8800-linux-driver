#!/bin/bash
# Universal package creation script for AIC8800 driver
# Automatically detects distribution and creates appropriate package

set -e

# Source distribution detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/detect_distro.sh"
source "${SCRIPT_DIR}/detect_compiler.sh"

detect_distribution
detect_kernel_compiler

echo "Creating packages for $DISTRO_NAME ($DISTRO_FAMILY) on $ARCH..."
echo "Detected compiler: $KERNEL_CC"

# Create packages based on detected distribution
case "$DISTRO_FAMILY" in
    "debian")
        echo "Creating DEB package..."
        bash "${SCRIPT_DIR}/package_deb.sh"
        ;;
    "redhat"|"suse")
        echo "Creating RPM package..."
        bash "${SCRIPT_DIR}/package_rpm.sh"
        ;;
    "arch")
        echo "Creating Arch package..."
        bash "${SCRIPT_DIR}/package_arch.sh"
        ;;
    *)
        echo "Unknown distribution family: $DISTRO_FAMILY"
        echo "Attempting to create packages for all supported formats..."

        # Try to create all package types
        echo "Creating DEB package..."
        if bash "${SCRIPT_DIR}/package_deb.sh" 2>/dev/null; then
            echo "DEB package created successfully"
        else
            echo "Failed to create DEB package"
        fi

        echo "Creating RPM package..."
        if bash "${SCRIPT_DIR}/package_rpm.sh" 2>/dev/null; then
            echo "RPM package created successfully"
        else
            echo "Failed to create RPM package"
        fi

        echo "Creating Arch package..."
        if bash "${SCRIPT_DIR}/package_arch.sh" 2>/dev/null; then
            echo "Arch package created successfully"
        else
            echo "Failed to create Arch package"
        fi
        ;;
    esac

echo "Package creation completed!"
echo "Available packages:"
ls -la *.deb *.rpm *.pkg.tar.* 2>/dev/null || echo "No packages found"
