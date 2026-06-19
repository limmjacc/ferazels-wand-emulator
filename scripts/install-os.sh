#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/qemu.conf.sh"

# ── Preflight ────────────────────────────────────────────────────────────────

if [[ ! -f "${MACOS9_ISO}" ]]; then
    echo "ERROR: Mac OS 9 ISO not found at: ${MACOS9_ISO}"
    echo "       Place your Mac OS 9 installation ISO there and re-run."
    echo "       See docs/setup-guide.md for details."
    exit 1
fi

if [[ ! -f "${DISK_IMAGE}" ]]; then
    echo "ERROR: Disk image not found at: ${DISK_IMAGE}"
    echo "       Run 'make create-disk' first."
    exit 1
fi

# ── Launch ───────────────────────────────────────────────────────────────────
#
# The CD is attached on ide.1 with cache=unsafe. See config/qemu.conf.sh
# quirk #2 (explicit IDE bus) and quirk #6 (cache=unsafe on CD).
#
# Installation walkthrough:
#   1. Wait ~60s for Mac OS 9 to boot from the installer CD.
#   2. When the installer opens, click Continue — it will say "no volumes found".
#      This is expected: the blank disk has no partition table yet.
#   3. Do NOT run the installer yet. Instead, find Drive Setup:
#        • Open the installer CD icon on the desktop
#        • Navigate to Utilities → Drive Setup
#   4. Drive Setup will list the blank disk. Select it and click Initialize.
#      Accept the default HFS+ format. This writes an Apple Partition Map.
#   5. Close Drive Setup. The installer will now find the formatted volume.
#   6. Run the installer, select the new volume, and complete installation.
#   7. When done: Special → Shut Down (NOT the red window close button).
#      The emulator exits cleanly on shutdown and saves the disk image.

echo "==> Booting from Mac OS 9 ISO..."
echo ""
echo "    IMPORTANT — read before you click anything:"
echo "    The installer will say 'no volumes' on first open. This is normal."
echo "    You must run Drive Setup first (on the CD under Utilities/)."
echo "    Drive Setup will find the blank disk and initialize it."
echo "    Then run the installer. See docs/setup-guide.md for full steps."
echo ""
echo "    When installation is complete: Special → Shut Down (not Restart)."
echo ""

"${QEMU_BIN}" \
    "${QEMU_BASE_FLAGS[@]}" \
    -device "ide-cd,bus=ide.1,unit=0,drive=cd0" \
    -drive  "id=cd0,file=${MACOS9_ISO},format=raw,if=none,media=cdrom,readonly=on,cache=unsafe" \
    -boot d

echo ""
echo "==> Installation session ended."
echo "    If installation completed successfully, run 'make launch'."
