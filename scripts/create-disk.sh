#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  create-disk.sh  —  Create Blank Mac OS 9 Disk Image
#
#  Creates disks/macos9.img — a blank 6 GB raw disk image.
#
#  Raw format is required (not QCOW2): mac99's ATA Manager in Mac OS 9.2.2
#  fails to enumerate QCOW2 disks during installation. See qemu.conf.sh quirk #1.
#
#  The disk is left completely blank (no partition table). Drive Setup runs
#  inside QEMU during install-os to write the Apple Partition Map. This is
#  intentional: install-os uses Homebrew QEMU 11, which handles disk init
#  correctly without the macio-ide issues of the screamer build.
#
#  Usage: make create-disk
# ─────────────────────────────────────────────────────────────────────────────
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
