#!/usr/bin/env bash
# Boot from Mac OS 9 ISO to install the OS onto disks/macos9.img.
# This is an interactive session - follow the on-screen instructions below.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/qemu.conf.sh"

if [[ ! -f "${MACOS9_ISO}" ]]; then
    echo "ERROR: Mac OS 9 ISO not found at: ${MACOS9_ISO}"
    echo "       Place your Mac OS 9.2.2 ISO there and re-run."
    echo "       See docs/setup-guide.md → Obtaining Mac OS 9."
    exit 1
fi

if [[ ! -f "${DISK_IMAGE}" ]]; then
    echo "ERROR: Disk image not found at: ${DISK_IMAGE}"
    echo "       Run 'make create-disk' first."
    exit 1
fi

cat <<'INSTRUCTIONS'
==> Booting Mac OS 9 installer - follow these steps exactly:

  ① Wait ~60 seconds for Mac OS 9 to boot from the installer CD.

  ② The installer opens automatically. A volume named "untitled" should
     already be visible — the disk was pre-initialized by create-disk.sh.
     If the installer says "no volumes found", see note ③ below.

     Select "untitled" → click Install (or Start).
     Installation takes 5–10 minutes.

  ③ [Only if "untitled" is NOT visible]: The pre-initialization failed.
     Close the installer. On the desktop, open the CD → Utilities →
     Drive Setup. Select the blank disk → Initialize (HFS+ format).
     Quit Drive Setup, then re-run the Mac OS 9 Installer.

  ④ When the installer finishes: Special → Shut Down.
     DO NOT close the QEMU window - that corrupts the disk image.
     The window closes automatically after Shut Down.

INSTRUCTIONS

# Use cache=unsafe on the hard disk during installation.
# The installer updates the Apple Partition Map (disk drivers) at the end —
# this write stalls without cache=unsafe. Not needed for normal gameplay.
"${QEMU_BIN}" \
    "${QEMU_DATA_FLAGS[@]+"${QEMU_DATA_FLAGS[@]}"}" \
    -M      mac99 \
    -m      256 \
    -cpu    G4 \
    -device "ide-hd,bus=ide.0,unit=0,drive=hd0" \
    -drive  "id=hd0,file=${DISK_IMAGE},format=raw,if=none,cache=unsafe" \
    -device "ide-cd,bus=ide.1,unit=0,drive=cd0" \
    -drive  "id=cd0,file=${MACOS9_ISO},format=raw,if=none,media=cdrom,readonly=on,cache=unsafe" \
    -display "cocoa,full-screen=on" \
    -usb \
    -device  usb-mouse \
    -device  usb-kbd \
    -boot d

echo ""
echo "==> Session ended. If installation completed, run 'make install-game'."
