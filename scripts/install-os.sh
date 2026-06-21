#!/usr/bin/env bash
# Boot from Mac OS 9 ISO to install the OS onto disks/macos9.img.
# This is an interactive session - follow the on-screen instructions below.
#
# Uses Homebrew QEMU 11 for installation — the screamer build (QEMU 7.1.94)
# has a macio-ide regression that causes "Updating Apple hard disk drivers" to
# hang indefinitely. QEMU 11 completes the install cleanly. The vendored
# screamer build is used at runtime (gameplay) for audio.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/qemu.conf.sh"

# ── Use Homebrew QEMU 11 for installation ─────────────────────────────────────
BREW_QEMU="/opt/homebrew/bin/qemu-system-ppc"
if [[ ! -x "${BREW_QEMU}" ]]; then
    echo "ERROR: Homebrew qemu-system-ppc not found at ${BREW_QEMU}"
    echo "       Run: brew install qemu"
    exit 1
fi
INSTALL_QEMU="${BREW_QEMU}"

if [[ ! -f "${MACOS9_ISO}" ]]; then
    echo "ERROR: Mac OS 9 ISO not found at: ${MACOS9_ISO}"
    echo "       Place your Mac OS 9.2.2 ISO there and re-run."
    echo "       See docs/setup-guide.md -> Obtaining Mac OS 9."
    exit 1
fi

if [[ ! -f "${DISK_IMAGE}" ]]; then
    echo "ERROR: Disk image not found at: ${DISK_IMAGE}"
    echo "       Run 'make create-disk' first."
    exit 1
fi

cat <<'INSTRUCTIONS'
==> Booting Mac OS 9 installer - follow these steps exactly:

  (1) Wait ~60 seconds for Mac OS 9 to boot from the installer CD.

  (2) The installer opens automatically and says "no volumes available".
      This is normal - the blank disk has no partition table yet.
      CLOSE or IGNORE the installer for now.

  (3) On the desktop, double-click the installer CD icon.
      Open the Utilities folder inside.
      Launch Drive Setup.

  (4) Drive Setup lists your blank disk. Select it -> click Initialize.
      Accept the default HFS+ format. This writes an Apple Partition Map.
      Quit Drive Setup when it finishes.

  (5) Now run the Mac OS 9 Installer (from the CD or the open window).
      The formatted volume now appears. Select it -> click Install.
      Installation takes 5-10 minutes.

  (6) When the installer finishes: Special -> Shut Down.
      DO NOT close the QEMU window - that corrupts the disk image.
      The window closes automatically after Shut Down.

INSTRUCTIONS

"${INSTALL_QEMU}" \
    -M      mac99 \
    -m      256 \
    -cpu    G4 \
    -device "ide-hd,bus=ide.0,unit=0,drive=hd0" \
    -drive  "id=hd0,file=${DISK_IMAGE},format=raw,if=none" \
    -device "ide-cd,bus=ide.1,unit=0,drive=cd0" \
    -drive  "id=cd0,file=${MACOS9_ISO},format=raw,if=none,media=cdrom,readonly=on,cache=unsafe,aio=threads" \
    -display "cocoa" \
    -usb \
    -device  usb-mouse \
    -device  usb-kbd \
    -boot d

echo ""
echo "==> Session ended. If installation completed, run 'make install-game'."
