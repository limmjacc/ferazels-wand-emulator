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

# ── Pre-initialize partition table from macOS ─────────────────────────────────
# The Mac OS 9 installer's "Updating Apple hard disk drivers" step hangs in
# QEMU when it has to CREATE driver partitions from scratch. Pre-initializing
# the Apple Partition Map + HFS+ from macOS means the partitions already exist
# and the installer only needs to overwrite driver data — completing in seconds.
#
# We also disable HFS+ journaling: Mac OS 9 does not understand journaling and
# will silently corrupt a journaled volume during installation.

echo ""
echo "==> Pre-initializing Apple Partition Map (skips Drive Setup in QEMU)..."

DISK_DEV=$(hdiutil attach -nomount \
    -imagekey diskimage-class=CRawDiskImage \
    "${DISK_IMAGE}" 2>/dev/null | awk '{print $1}' | head -1)

if [[ -n "${DISK_DEV}" && -b "${DISK_DEV}" ]]; then
    diskutil quiet partitionDisk "${DISK_DEV}" APM JHFS+ "untitled" 100% 2>/dev/null \
        && echo "  Partitioned: Apple Partition Map + HFS+" \
        || { echo "  WARNING: partitionDisk failed — Drive Setup will be needed inside QEMU."; hdiutil detach "${DISK_DEV}" -quiet 2>/dev/null; }

    # Disable journaling so Mac OS 9 can safely read and write the volume
    SLICE=$(diskutil list "${DISK_DEV}" 2>/dev/null | awk '/Apple_HFS/{print $NF}' | head -1)
    if [[ -n "${SLICE}" ]]; then
        diskutil disableJournal "${SLICE}" 2>/dev/null \
            && echo "  Journaling disabled (Mac OS 9 compatibility)" \
            || echo "  WARNING: Could not disable journaling — Mac OS 9 may have issues"
    fi

    hdiutil detach "${DISK_DEV}" -quiet 2>/dev/null || true
    echo "  Disk ready: Drive Setup step is not needed inside QEMU"
else
    echo "  WARNING: Could not attach disk image for pre-initialization."
    echo "           You will need to run Drive Setup inside QEMU (see install-os.sh instructions)."
fi

echo ""
if [[ ! -f "${MACOS9_ISO}" ]]; then
    echo "NOTE: Mac OS 9 ISO not found at ${MACOS9_ISO}"
    echo "      Place it there before running 'make install-os'."
else
    echo "Next: run 'make install-os'."
fi
