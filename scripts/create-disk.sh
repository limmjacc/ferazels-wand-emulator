#!/usr/bin/env bash
# Creates a blank 6 GB raw disk image for Mac OS 9.
# Raw format is required - see config/qemu.conf.sh quirk #1.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/qemu.conf.sh"

mkdir -p "${DISKS_DIR}"

if [[ -f "${DISK_IMAGE}" ]]; then
    echo "Disk image already exists: ${DISK_IMAGE}"
    read -r -p "Overwrite? This permanently erases it. [y/N] " confirm
    [[ "${confirm}" =~ ^[yY]$ ]] || { echo "Aborted."; exit 0; }
    rm -f "${DISK_IMAGE}"
fi

echo "==> Creating ${DISK_SIZE} raw disk image..."
"${QEMU_IMG_BIN}" create -f raw "${DISK_IMAGE}" "${DISK_SIZE}"
echo "    Created: ${DISK_IMAGE}"
echo ""

if [[ ! -f "${MACOS9_ISO}" ]]; then
    echo "NOTE: Mac OS 9 ISO not found at ${MACOS9_ISO}"
    echo "      Place it there before running 'make install-os'."
else
    echo "Next: run 'make install-os'."
fi
