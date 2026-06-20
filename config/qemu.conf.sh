#!/usr/bin/env bash
# Shared QEMU configuration — source this from all scripts.
# Prefers the self-contained vendored binary; falls back to Homebrew.
#
# ── QEMU 11 + mac99 + Mac OS 9.2.2 bring-up quirks ───────────────────────────
#
# 1. RAW disk format required.
#    mac99's ATA Manager in Mac OS 9.2.2 fails to enumerate QCOW2 disks during
#    installation. Raw format passes cleanly. All images use .img (not .qcow2).
#
# 2. Explicit IDE bus assignment required.
#    QEMU 11 mac99 auto-creates phantom IDE-CD devices on ide.0 alongside the
#    hard disk, causing Drive Setup to fail. Fix: assign every drive explicitly:
#      -device ide-hd,bus=ide.0,unit=0   (hard disk)
#      -device ide-cd,bus=ide.1,unit=0   (any CD-ROM)
#    The mac99 machine exposes two macio-ide controllers: ide.0 and ide.1.
#
# 3. Do NOT use -M mac99,via=pmu.
#    PMU causes "couldn't read big system resources" installer failures.
#
# 4. 256 MB RAM only — do not increase.
#    512 MB causes installer instability. Game runs fine at 256 MB.
#
# 5. screamer audio removed in QEMU 11.
#    In QEMU 8, audio for mac99 required -device screamer,audiodev=...
#    In QEMU 11 Screamer is built into mac99 and auto-connects to the first
#    audiodev. Adding -device screamer causes a fatal "not a valid device" error.
#
# 6. cache=unsafe on CD during Mac OS 9 installation.
#    The installer reads large sequential blocks from CD. Without cache=unsafe,
#    QEMU stalls on those reads and produces "couldn't read" errors mid-install.
#    Only needed during install-os, not during gameplay.
#
# 7. macOS system bash is version 3.2 — no associative arrays.
#    macOS ships bash 3.2 (GPLv2). declare -A fails. All scripts use
#    file-existence checks instead.
#
# 8. Game folder name contains a Unicode ƒ character.
#    Installer VISE names the game folder "Ferazel's Wand 1.0.2 ƒ" where ƒ is
#    U+0192. Use shell globs (Ferazel*) rather than hardcoded paths.
#
# 9. Game CD is plain HFS (not HFS+) — macOS Catalina+ cannot mount it.
#    The CD image uses raw HFS with 1536-byte allocation blocks and no partition
#    map. Modern macOS dropped plain HFS support. machfs (pip3) can read it;
#    Mac OS 9 reads it natively as a CD-ROM via ide-cd.
# ─────────────────────────────────────────────────────────────────────────────

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DISKS_DIR="${REPO_ROOT}/disks"
DISK_IMAGE="${DISKS_DIR}/macos9.img"   # raw format — quirk #1
MACOS9_ISO="${DISKS_DIR}/macos9.iso"
GAME_ISO="${DISKS_DIR}/Ferazel's Wand 1.0.2.ISO"
SIT_103="${DISKS_DIR}/Ferazel's Wand 1.0.3 update.sit"
SIT_NOGAMMA="${DISKS_DIR}/Ferazels_Wand_103_nogamma.sit"
DISK_SIZE="6G"

VENDOR_QEMU="${REPO_ROOT}/vendor/qemu"
BREW_PREFIX="/opt/homebrew"

# ── QEMU binary ───────────────────────────────────────────────────────────────

if [[ -x "${VENDOR_QEMU}/bin/qemu-system-ppc" ]]; then
    QEMU_BIN="${VENDOR_QEMU}/bin/qemu-system-ppc"
    QEMU_IMG_BIN="${VENDOR_QEMU}/bin/qemu-img"
    QEMU_DATA_FLAGS=("-L" "${VENDOR_QEMU}/share/qemu")
    IS_VENDORED=1
elif [[ -x "${BREW_PREFIX}/bin/qemu-system-ppc" ]]; then
    QEMU_BIN="${BREW_PREFIX}/bin/qemu-system-ppc"
    QEMU_IMG_BIN="${BREW_PREFIX}/bin/qemu-img"
    QEMU_DATA_FLAGS=()
    IS_VENDORED=0
else
    echo "ERROR: qemu-system-ppc not found. Run 'make setup' then 'make vendor'." >&2
    exit 1
fi

# ── unar binary (for apply-patches) ──────────────────────────────────────────

if [[ -x "${VENDOR_QEMU}/bin/unar" ]]; then
    UNAR_BIN="${VENDOR_QEMU}/bin/unar"
elif [[ -x "${BREW_PREFIX}/bin/unar" ]]; then
    UNAR_BIN="${BREW_PREFIX}/bin/unar"
else
    UNAR_BIN=""
fi

# ── Base QEMU flags (gameplay) ────────────────────────────────────────────────
# install-os.sh adds a CD on ide.1 unit 0.
# install-game.sh adds a CD on ide.1 unit 0.
# launch.sh uses these flags as-is (no CD at runtime).

QEMU_BASE_FLAGS=(
    "${QEMU_DATA_FLAGS[@]+"${QEMU_DATA_FLAGS[@]}"}"
    -M      mac99                              # no via=pmu — quirk #3
    -m      256                                # 256 MB only — quirk #4
    -cpu    G4
    -device "ide-hd,bus=ide.0,unit=0,drive=hd0"   # explicit bus — quirk #2
    -drive  "id=hd0,file=${DISK_IMAGE},format=raw,if=none"
    -display "cocoa,zoom-to-fit=on,full-screen=on"
    -audiodev "coreaudio,id=snd0"              # no -device screamer — quirk #5
    -usb
    -device  usb-mouse
    -device  usb-kbd
)
