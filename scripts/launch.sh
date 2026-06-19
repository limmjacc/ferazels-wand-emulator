#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/qemu.conf.sh"

if [[ ! -f "${DISK_IMAGE}" ]]; then
    echo "ERROR: Disk image not found at: ${DISK_IMAGE}"
    echo "       Run 'make create-disk' and 'make install-os' first."
    exit 1
fi

echo "==> Launching Mac OS 9..."
[[ "${IS_VENDORED}" -eq 1 ]] && echo "    (self-contained vendored QEMU — no Homebrew required)"

# No CD attached at runtime. All saves write to disks/macos9.img which
# persists between launches and travels with the repo. See config/qemu.conf.sh
# for full documentation of the QEMU flags used here.
"${QEMU_BIN}" \
    "${QEMU_BASE_FLAGS[@]}" \
    -no-reboot
