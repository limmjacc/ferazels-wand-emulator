#!/usr/bin/env bash
# Shared QEMU configuration — source this from other scripts.
# Prefers the self-contained vendored binary; falls back to Homebrew.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DISKS_DIR="${REPO_ROOT}/disks"
DISK_IMAGE="${DISKS_DIR}/macos9.qcow2"
MACOS9_ISO="${DISKS_DIR}/macos9.iso"
DISK_SIZE="6G"

VENDOR_QEMU="${REPO_ROOT}/vendor/qemu"
BREW_QEMU="/opt/homebrew/bin"

if [[ -x "${VENDOR_QEMU}/bin/qemu-system-ppc" ]]; then
    QEMU_BIN="${VENDOR_QEMU}/bin/qemu-system-ppc"
    QEMU_IMG_BIN="${VENDOR_QEMU}/bin/qemu-img"
    QEMU_DATA_FLAGS=("-L" "${VENDOR_QEMU}/share/qemu")
    IS_VENDORED=1
elif [[ -x "${BREW_QEMU}/qemu-system-ppc" ]]; then
    QEMU_BIN="${BREW_QEMU}/qemu-system-ppc"
    QEMU_IMG_BIN="${BREW_QEMU}/qemu-img"
    QEMU_DATA_FLAGS=()
    IS_VENDORED=0
else
    echo "ERROR: qemu-system-ppc not found." >&2
    echo "       Run 'make setup' then 'make vendor'." >&2
    exit 1
fi

# QEMU flags common to all invocations
QEMU_BASE_FLAGS=(
    "${QEMU_DATA_FLAGS[@]+"${QEMU_DATA_FLAGS[@]}"}"
    -M      mac99,via=pmu
    -m      512
    -cpu    G4
    -drive  "file=${DISK_IMAGE},format=qcow2,media=disk,index=0"
    -display "cocoa,zoom-to-fit=on"
    -audiodev "coreaudio,id=snd0"
    -device  "screamer,audiodev=snd0"
    -usb
    -device  usb-mouse
    -device  usb-kbd
)
