#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  launch.sh  —  Ferazel's Wand Gameplay Launch
#
#  Boots Mac OS 9 from disks/macos9.img with the game CD attached.
#  Uses the vendored screamer QEMU build (vendor/qemu/) for audio support.
#  All saves write to macos9.img and persist between sessions.
#
#  Usage: make launch  (or run directly: bash scripts/launch.sh)
#  For double-click launching, use Play.command instead.
# ─────────────────────────────────────────────────────────────────────────────
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
    -device "ide-cd,bus=ide.1,unit=0,drive=cd0" \
    -drive  "id=cd0,file=${GAME_ISO},format=raw,if=none,media=cdrom,readonly=on,cache=unsafe" \
    -no-reboot
