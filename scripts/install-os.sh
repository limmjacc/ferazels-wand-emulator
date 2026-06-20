#!/usr/bin/env bash
# Boot from Mac OS 9 ISO to install the OS onto disks/macos9.img.
# This is an interactive session — follow the on-screen instructions below.
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
==> Booting Mac OS 9 installer — follow these steps exactly:

  ① Wait ~60 seconds for Mac OS 9 to boot from the installer CD.

  ② The installer opens automatically and says "no volumes available".
     This is normal — the blank disk has no partition table yet.
     CLOSE or IGNORE the installer for now.

  ③ On the desktop, double-click the installer CD icon.
     Open the Utilities folder inside.
     Launch Drive Setup.

  ④ Drive Setup lists your blank disk. Select it → click Initialize.
     Accept the default HFS+ format. This writes an Apple Partition Map.
     Quit Drive Setup when it finishes.

  ⑤ Now run the Mac OS 9 Installer (from the CD or the open window).
     The formatted volume now appears. Select it → click Install.
     Installation takes 5–10 minutes.

  ⑥ When the installer finishes: Special → Shut Down.
     DO NOT close the QEMU window — that corrupts the disk image.
     The window closes automatically after Shut Down.

INSTRUCTIONS

"${QEMU_BIN}" \
    "${QEMU_BASE_FLAGS[@]}" \
    -device "ide-cd,bus=ide.1,unit=0,drive=cd0" \
    -drive  "id=cd0,file=${MACOS9_ISO},format=raw,if=none,media=cdrom,readonly=on,cache=unsafe" \
    -boot d

echo ""
echo "==> Session ended. If installation completed, run 'make install-game'."
