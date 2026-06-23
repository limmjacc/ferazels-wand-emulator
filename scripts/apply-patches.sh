#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  apply-patches.sh  -  Automated Patch Application
#
#  Applies the v1.0.3 update and no-gamma patch to the installed game.
#  Runs entirely on macOS - no QEMU, no Mac OS 9 interaction required.
#
#  After 'make install-game', this script:
#    1. Mounts disks/macos9.img directly on macOS (hdiutil attach)
#    2. Extracts the v1.0.3 update .sit archive using unar
#    3. Extracts the no-gamma patched executable .sit archive using unar
#    4. Copies all extracted files into the game folder using ditto
#       (ditto preserves Mac resource forks on HFS+ volumes)
#    5. Unmounts cleanly
#
#  Why ditto instead of cp:
#    Classic Mac game data lives in resource forks (data fork is 0 bytes).
#    unar extracts StuffIt archives with resource fork metadata in AppleDouble
#    format; ditto merges that back into native HFS+ resource forks on the
#    mounted volume. cp silently drops resource forks.
#
#  Why no-gamma:
#    The standard v1.0.3 executable triggers a gamma screen-fade when using
#    the dagger weapon. QEMU's gamma ramp API is unimplemented, causing an
#    immediate crash. The no-gamma patch removes this effect entirely.
#
#  Usage: make apply-patches  (automated, no interaction required)
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/qemu.conf.sh"

# ── Preflight ────────────────────────────────────────────────────────────────

if [[ -z "${UNAR_BIN}" ]]; then
    echo "ERROR: unar not found."
    echo "       Run 'make setup' to install it, then optionally 'make vendor' to bundle it."
    exit 1
fi

for f in "${SIT_103}" "${SIT_NOGAMMA}"; do
    if [[ ! -f "${f}" ]]; then
        echo "ERROR: Missing patch file: $(basename "${f}")"
        echo "       Download from https://macintoshgarden.org/games/ferazels-wand"
        echo "       and place in disks/"
        exit 1
    fi
done

if [[ ! -f "${DISK_IMAGE}" ]]; then
    echo "ERROR: ${DISK_IMAGE} not found."
    echo "       Run 'make create-disk', 'make install-os', 'make install-game' first."
    exit 1
fi

echo "==> Applying patches to $(basename "${DISK_IMAGE}")..."

# ── Mount the disk (read-write) ───────────────────────────────────────────────

ATTACH_OUT=$(hdiutil attach "${DISK_IMAGE}" 2>&1)
MACOS9_VOLUME=$(echo "${ATTACH_OUT}" | awk '/Apple_HFS/{print $NF}' | head -1)
HFS_DEV=$(echo "${ATTACH_OUT}" | awk '/Apple_HFS/{print $1}' | head -1)

if [[ -z "${MACOS9_VOLUME}" ]] || [[ ! -d "${MACOS9_VOLUME}" ]]; then
    echo "ERROR: Failed to mount ${DISK_IMAGE}."
    echo "       Make sure Mac OS 9 (QEMU) is not currently running."
    exit 1
fi
echo "    Mounted: ${DISK_IMAGE} → ${MACOS9_VOLUME}"

WORK=$(mktemp -d /tmp/fw_patches_XXXXX)

cleanup() {
    rm -rf "${WORK}" 2>/dev/null || true
    if [[ -n "${HFS_DEV:-}" ]]; then
        hdiutil detach "${HFS_DEV}" 2>/dev/null || true
        echo "    Unmounted: ${MACOS9_VOLUME}"
    fi
}
trap cleanup EXIT

# ── Find the game installation folder ─────────────────────────────────────────
# Installer VISE names the folder "Ferazel's Wand 1.0.2 ƒ" (ƒ = U+0192).
# Use a glob rather than hardcoding. See config/qemu.conf.sh quirk #8.

GAME_FOLDER=$(find "${MACOS9_VOLUME}" -maxdepth 1 -name "Ferazel*" -type d | head -1)

if [[ -z "${GAME_FOLDER}" ]]; then
    echo ""
    echo "ERROR: Ferazel's Wand installation not found on ${MACOS9_VOLUME}."
    echo "       Run 'make install-game' first:"
    echo "         boot Mac OS 9, run the Ferazel's Wand Installer, shut down."
    exit 1
fi
echo "    Game folder: $(basename "${GAME_FOLDER}")"

# ── Extract and apply v1.0.3 update ──────────────────────────────────────────

echo ""
echo "    Extracting v1.0.3 update..."
mkdir -p "${WORK}/update"
"${UNAR_BIN}" -o "${WORK}/update" "${SIT_103}" 1>/dev/null

# The .sit contains a wrapper folder - find it
UPDATE_SUBFOLDER=$(find "${WORK}/update" -mindepth 1 -maxdepth 1 -type d | head -1)

if [[ -n "${UPDATE_SUBFOLDER}" ]]; then
    ditto "${UPDATE_SUBFOLDER}/" "${GAME_FOLDER}/"
    echo "    Applied:  $(basename "${UPDATE_SUBFOLDER}") → $(basename "${GAME_FOLDER}")"
else
    ditto "${WORK}/update/" "${GAME_FOLDER}/"
    echo "    Applied:  v1.0.3 files → $(basename "${GAME_FOLDER}")"
fi

# ── Extract and apply no-gamma patch ─────────────────────────────────────────

echo "    Extracting no-gamma patch..."
mkdir -p "${WORK}/nogamma"
"${UNAR_BIN}" -o "${WORK}/nogamma" "${SIT_NOGAMMA}" 1>/dev/null

# Find the extracted application (skip AppleDouble ._sidecar files)
NOGAMMA_APP=$(find "${WORK}/nogamma" \( -name "*nogamma*" -o -name "*nogamma*" \) \
    ! -name "._*" ! -type d | head -1)

if [[ -z "${NOGAMMA_APP}" ]]; then
    # Fallback: grab the first non-directory, non-AppleDouble file
    NOGAMMA_APP=$(find "${WORK}/nogamma" -maxdepth 2 ! -type d ! -name "._*" | head -1)
fi

if [[ -z "${NOGAMMA_APP}" ]]; then
    echo "ERROR: Could not find the no-gamma application after extraction."
    echo "       unar output:"
    find "${WORK}/nogamma" | sed 's/^/  /'
    exit 1
fi

ditto "${NOGAMMA_APP}" "${GAME_FOLDER}/Ferazel's Wand nogamma"
echo "    Applied:  no-gamma executable → $(basename "${GAME_FOLDER}")"

# ── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo "==> Patches applied successfully."
echo ""
echo "    $(basename "${GAME_FOLDER}") now contains:"
ls "${GAME_FOLDER}" | sed 's/^/      /'
echo ""
echo "Setup complete. Run 'make launch' or double-click FerazelsWand.app to play."
