#!/usr/bin/env bash
# Shared QEMU configuration — source this from other scripts.
# Prefers the self-contained vendored binary; falls back to Homebrew.
#
# ── QEMU 11 + mac99 + Mac OS 9.2.2 quirks discovered during bring-up ─────────
#
# 1. RAW disk format required.
#    QCOW2 works as a container but mac99's ATA Manager in Mac OS 9.2.2 fails
#    to enumerate the disk during installation when using qcow2. Raw format
#    passes cleanly. Disk image is disks/macos9.img (not .qcow2).
#
# 2. Explicit IDE bus assignment required.
#    QEMU 11 mac99 auto-creates phantom IDE-CD devices on ide.0 alongside your
#    hard disk, causing Drive Setup to fail. Fix: use `-device ide-hd,bus=ide.0`
#    and `-device ide-cd,bus=ide.1` explicitly rather than `-drive if=ide`.
#    The mac99 machine exposes two macio-ide controllers as ide.0 and ide.1.
#
# 3. Do NOT use -M mac99,via=pmu.
#    The PMU (Power Management Unit) option causes the Mac OS 9 installer to
#    fail with "couldn't read big system resources" errors partway through
#    installation. Drop via=pmu entirely for stable installs and gameplay.
#
# 4. 256 MB RAM — do not increase.
#    512 MB causes instability in the installer. Mac OS 9 is happy with 256 MB
#    and the game runs fine. Do not raise this without re-testing.
#
# 5. screamer audio device removed in QEMU 11.
#    In QEMU 8 and earlier, audio for mac99 required `-device screamer,audiodev=`.
#    In QEMU 11 the Screamer chip is built into the mac99 machine and
#    auto-connects to the first available audiodev. Just `-audiodev coreaudio`
#    is sufficient — adding -device screamer causes a fatal error.
#
# 6. cache=unsafe on the CD drive during installation.
#    The Mac OS 9.2.2 installer reads very large sequential blocks from CD.
#    Without cache=unsafe, QEMU's CD-ROM emulation stalls on those reads and
#    produces "couldn't read" installer errors. Only needed during install-os,
#    not during normal gameplay (no CD mounted at runtime).
#
# 7. macOS system bash is version 3.2 — no associative arrays.
#    macOS ships bash 3.2 (GPLv2). declare -A (bash 4+) fails. All scripts in
#    this repo avoid bash 4+ features. vendor-qemu.sh uses file-existence checks
#    instead of an associative array for the dedup set.
# ─────────────────────────────────────────────────────────────────────────────

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DISKS_DIR="${REPO_ROOT}/disks"
DISK_IMAGE="${DISKS_DIR}/macos9.img"   # raw format — see quirk #1 above
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

# Base flags used by launch.sh (gameplay). install-os.sh adds the CD drive on
# top of these. See numbered quirk notes at the top of this file.
QEMU_BASE_FLAGS=(
    "${QEMU_DATA_FLAGS[@]+"${QEMU_DATA_FLAGS[@]}"}"
    -M      mac99                              # no via=pmu — see quirk #3
    -m      256                                # 256 MB only — see quirk #4
    -cpu    G4
    -device "ide-hd,bus=ide.0,unit=0,drive=hd0"   # explicit bus — see quirk #2
    -drive  "id=hd0,file=${DISK_IMAGE},format=raw,if=none"  # raw — see quirk #1
    -display "cocoa,zoom-to-fit=on"
    -audiodev "coreaudio,id=snd0"              # no -device screamer — see quirk #5
    -usb
    -device  usb-mouse
    -device  usb-kbd
)
