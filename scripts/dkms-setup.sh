#!/bin/bash
set -e

PACKAGE="aic8800"
VERSION="1.2.1"
DKMS_SRC="/usr/src/${PACKAGE}-${VERSION}"
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Syncing source to ${DKMS_SRC}..."
rm -rf "${DKMS_SRC}"
mkdir -p "${DKMS_SRC}"
cp -r "${SCRIPT_DIR}/." "${DKMS_SRC}/"
chmod +x "${DKMS_SRC}/scripts/dkms-pre-build.sh"

echo "Removing old DKMS registration (if any)..."
dkms remove "${PACKAGE}/${VERSION}" --all 2>/dev/null || true

echo "Registering with DKMS..."
dkms add "${PACKAGE}/${VERSION}"

echo "Building..."
dkms build "${PACKAGE}/${VERSION}"

echo "Installing..."
dkms install "${PACKAGE}/${VERSION}" --force

echo ""
echo "Done. '${PACKAGE}' will now auto-rebuild on every kernel update."
echo "Run 'dkms status' to verify."
