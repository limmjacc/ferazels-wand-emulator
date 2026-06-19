#!/usr/bin/env bash
# Boot Mac OS 9 with three drives attached:
#   ide.0 unit 0  — macos9.img  (Mac OS 9 hard disk)
#   ide.1 unit 0  — game CD ISO (Ferazel's Wand 1.0.2.ISO)
#   ide.0 unit 1  — transfer.img (APM HFS+: 1.0.3 update + no-gamma patch)
#
# Inside Mac OS 9:
#   1. The game CD ("Ferazel's Wand 1.0.2") appears on the desktop
#   2. The transfer disk ("FWTransfer") appears on the desktop
#   3. Drag the game folder from the CD to the hard disk
#   4. Double-click "Ferazel's Wand 1.0.3 update.sit" on FWTransfer
#      → StuffIt Expander replaces the 1.0.2 executable with 1.0.3
#   5. Double-click "Ferazels_Wand_103_nogamma.sit" on FWTransfer
#      → replaces the executable with the no-gamma patched version
#   6. Special → Shut Down when done

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/qemu.conf.sh"

GAME_ISO="${DISKS_DIR}/Ferazel's Wand 1.0.2.ISO"
XFER_DISK="${DISKS_DIR}/transfer.img"

if [[ ! -f "${DISK_IMAGE}" ]]; then
    echo "ERROR: Mac OS 9 disk not found at: ${DISK_IMAGE}"
    echo "       Run 'make create-disk' and 'make install-os' first."
    exit 1
fi

if [[ ! -f "${GAME_ISO}" ]]; then
    echo "ERROR: Game ISO not found at: ${GAME_ISO}"
    echo "       Place Ferazel's Wand 1.0.2.ISO in the disks/ folder."
    exit 1
fi

if [[ ! -f "${XFER_DISK}" ]]; then
    echo "ERROR: Transfer disk not found at: ${XFER_DISK}"
    echo "       Run the transfer disk setup steps in docs/setup-guide.md."
    exit 1
fi

echo "==> Launching Mac OS 9 with game CD + transfer disk..."
echo "    ide.0 unit 0 — macos9.img (Mac OS 9 hard disk)"
echo "    ide.1 unit 0 — Ferazel's Wand 1.0.2.ISO (game CD)"
echo "    ide.0 unit 1 — transfer.img (1.0.3 update + no-gamma patch)"
echo ""
echo "    Inside Mac OS 9:"
echo "    1. Drag game folder from CD to hard disk"
echo "    2. Expand both .sit files from FWTransfer with StuffIt Expander"
echo "    3. Special → Shut Down when done"
echo ""

"${QEMU_BIN}" \
    "${QEMU_BASE_FLAGS[@]}" \
    -device "ide-hd,bus=ide.0,unit=1,drive=xfer" \
    -drive  "id=xfer,file=${XFER_DISK},format=raw,if=none" \
    -device "ide-cd,bus=ide.1,unit=0,drive=cd0" \
    -drive  "id=cd0,file=${GAME_ISO},format=raw,if=none,media=cdrom,readonly=on,cache=unsafe" \
    -no-reboot
