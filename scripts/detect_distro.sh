#!/bin/bash
# Distribution detection script for AIC8800 driver
# Supports multiple distribution families

detect_distribution() {
    local distro_family=""
    local distro_name=""
    local distro_version=""
    local package_manager=""
    local package_extension=""
    local arch=$(uname -m)

    # Normalize architecture names
    case "$arch" in
        x86_64) arch="x86_64" ;;
        aarch64) arch="aarch64" ;;
        armv7l) arch="armv7l" ;;
        armv6l) arch="armv6l" ;;
        i386|i686) arch="i386" ;;
        *) arch="unknown" ;;
    esac

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        distro_name="$NAME"
        distro_version="$VERSION_ID"

        case "$ID" in
            ubuntu|debian|linuxmint|pop|elementary)
                distro_family="debian"
                package_manager="apt"
                package_extension="deb"
                ;;
            fedora|rhel|centos|rocky|almalinux|oracle)
                distro_family="redhat"
                package_manager="dnf"
                package_extension="rpm"
                ;;
            opensuse*|sles)
                distro_family="suse"
                package_manager="zypper"
                package_extension="rpm"
                ;;
            arch|manjaro|endeavouros)
                distro_family="arch"
                package_manager="pacman"
                package_extension="pkg.tar.zst"
                ;;
            alpine)
                distro_family="alpine"
                package_manager="apk"
                package_extension="apk"
                ;;
            *)
                # Try to detect by package manager presence
                if command -v apt >/dev/null 2>&1; then
                    distro_family="debian"
                    package_manager="apt"
                    package_extension="deb"
                elif command -v dnf >/dev/null 2>&1; then
                    distro_family="redhat"
                    package_manager="dnf"
                    package_extension="rpm"
                elif command -v yum >/dev/null 2>&1; then
                    distro_family="redhat"
                    package_manager="yum"
                    package_extension="rpm"
                elif command -v zypper >/dev/null 2>&1; then
                    distro_family="suse"
                    package_manager="zypper"
                    package_extension="rpm"
                elif command -v pacman >/dev/null 2>&1; then
                    distro_family="arch"
                    package_manager="pacman"
                    package_extension="pkg.tar.zst"
                else
                    distro_family="unknown"
                    package_manager="unknown"
                    package_extension="unknown"
                fi
                ;;
        esac
    else
        # Fallback detection
        if [ -f /etc/debian_version ]; then
            distro_family="debian"
            package_manager="apt"
            package_extension="deb"
            distro_name="Debian"
            distro_version=$(cat /etc/debian_version)
        elif [ -f /etc/redhat-release ]; then
            distro_family="redhat"
            package_manager="dnf"
            package_extension="rpm"
            distro_name=$(cat /etc/redhat-release | cut -d' ' -f1)
            distro_version=$(cat /etc/redhat-release | grep -oE '[0-9]+(\.[0-9]+)?' | head -1)
        elif [ -f /etc/arch-release ]; then
            distro_family="arch"
            package_manager="pacman"
            package_extension="pkg.tar.zst"
            distro_name="Arch Linux"
            distro_version="rolling"
        else
            distro_family="unknown"
            package_manager="unknown"
            package_extension="unknown"
            distro_name="Unknown"
            distro_version="Unknown"
        fi
    fi

    # Export variables
    export DISTRO_FAMILY="$distro_family"
    export DISTRO_NAME="$distro_name"
    export DISTRO_VERSION="$distro_version"
    export PACKAGE_MANAGER="$package_manager"
    export PACKAGE_EXTENSION="$package_extension"
    export ARCH="$arch"

    # Print detection results
    echo "Distribution Detection Results:"
    echo "  Family: $distro_family"
    echo "  Name: $distro_name"
    echo "  Version: $distro_version"
    echo "  Package Manager: $package_manager"
    echo "  Package Extension: $package_extension"
    echo "  Architecture: $arch"
}

# If script is run directly, execute detection
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    detect_distribution
fi
