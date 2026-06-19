#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/qemu.conf.sh"

mkdir -p "${DISKS_DIR}"

if [[ -f "${DISK_IMAGE}" ]]; then
    echo "Disk image already exists: ${DISK_IMAGE}"
    read -r -p "Overwrite? This will permanently erase it. [y/N] " confirm
    [[ "${confirm}" =~ ^[yY]$ ]] || { echo "Aborted."; exit 0; }
    rm -f "${DISK_IMAGE}"
fi

echo "==> Creating ${DISK_SIZE} Mac OS 9 raw disk image..."
"${QEMU_IMG_BIN}" create -f raw "${DISK_IMAGE}" "${DISK_SIZE}"

echo ""
echo "==> Created: ${DISK_IMAGE}"
echo ""
echo "Next: place your Mac OS 9 ISO at disks/macos9.iso, then run 'make install-os'."
