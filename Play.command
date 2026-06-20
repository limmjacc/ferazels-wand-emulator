#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
source "${REPO_ROOT}/config/qemu.conf.sh"

if [[ ! -x "${QEMU_BIN:-}" ]]; then
    echo "ERROR: QEMU not found. Run 'make setup && make vendor' first."
    exit 1
fi

if [[ ! -f "${DISK_IMAGE}" ]]; then
    echo "ERROR: Disk image not found. Run 'make create-disk && make install-os && make install-game && make apply-patches' first."
    exit 1
fi

if pgrep -x qemu-system-ppc > /dev/null 2>&1; then
    echo "ERROR: Ferazel's Wand is already running. Close the existing QEMU window first."
    exit 1
fi

echo "Starting Ferazel's Wand..."

"${QEMU_BIN}" \
    "${QEMU_BASE_FLAGS[@]}" \
    -device "ide-cd,bus=ide.1,unit=0,drive=cd0" \
    -drive  "id=cd0,file=${GAME_ISO},format=raw,if=none,media=cdrom,readonly=on,cache=unsafe" \
    -no-reboot
