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

echo "==> Booting from Mac OS 9 ISO..."
echo "    Install Mac OS 9 onto 'Mac OS 9' (the blank disk)."
echo "    When installation is complete, choose Shut Down — do not restart."
echo ""

"${QEMU_BIN}" \
    "${QEMU_BASE_FLAGS[@]}" \
    -drive "file=${MACOS9_ISO},media=cdrom,index=2,readonly=on" \
    -boot d

echo ""
echo "==> Installation session ended."
echo "    If installation completed, run 'make launch' to boot into Mac OS 9."
