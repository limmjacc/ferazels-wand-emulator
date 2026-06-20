#!/usr/bin/env bash
# Boot Mac OS 9 with the Ferazel's Wand game CD attached.
# Run the CD installer inside Mac OS 9, then shut down.
# Patches (v1.0.3 + no-gamma) are applied automatically afterwards
# by 'make apply-patches' — no manual steps required inside Mac OS 9.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/qemu.conf.sh"

if [[ ! -f "${DISK_IMAGE}" ]]; then
    echo "ERROR: ${DISK_IMAGE} not found."
    echo "       Run 'make create-disk' and 'make install-os' first."
    exit 1
fi

if [[ ! -f "${GAME_ISO}" ]]; then
    echo "ERROR: Game ISO not found at: ${GAME_ISO}"
    echo "       Place \"Ferazel's Wand 1.0.2.ISO\" in disks/"
    echo "       Download from https://macintoshgarden.org/games/ferazels-wand"
    exit 1
fi

cat <<'INSTRUCTIONS'
==> Booting Mac OS 9 with game CD — follow these steps:

  ① Wait ~60 seconds for Mac OS 9 to boot.

  ② On the desktop you will see a "Ferazel's Wand" CD icon.
     Double-click it to open the CD.

  ③ Double-click "Ferazel's Wand Installer".

  ④ Click "Easy Install".
     The installer copies the game to Macintosh HD (~60 seconds).

  ⑤ When the installer finishes, click Quit.

  ⑥ Special → Shut Down.
     DO NOT close the QEMU window — that corrupts the disk image.

  After shutdown, run 'make apply-patches' to finish setup.
  That step is fully automated — no Mac OS 9 interaction needed.

INSTRUCTIONS

"${QEMU_BIN}" \
    "${QEMU_BASE_FLAGS[@]}" \
    -device "ide-cd,bus=ide.1,unit=0,drive=cd0" \
    -drive  "id=cd0,file=${GAME_ISO},format=raw,if=none,media=cdrom,readonly=on,cache=unsafe" \
    -no-reboot

echo ""
echo "==> Session ended. Run 'make apply-patches' to apply v1.0.3 + no-gamma patches."
