#!/usr/bin/env bash
# Normal gameplay launch — boots Mac OS 9 from disks/macos9.img.
# No CD attached. All saves write to macos9.img and persist between sessions.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/qemu.conf.sh"

if [[ ! -f "${DISK_IMAGE}" ]]; then
    echo "ERROR: ${DISK_IMAGE} not found."
    echo "       Complete the one-time setup first. See docs/setup-guide.md."
    exit 1
fi

[[ "${IS_VENDORED}" -eq 1 ]] \
    && echo "==> Launching Ferazel's Wand (self-contained)..." \
    || echo "==> Launching Ferazel's Wand (via Homebrew QEMU)..."

"${QEMU_BIN}" \
    "${QEMU_BASE_FLAGS[@]}" \
    -no-reboot
