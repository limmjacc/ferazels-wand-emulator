#!/usr/bin/env bash
# Build qemu-system-ppc from the mcayland/qemu screamer branch and vendor it
# into vendor/qemu/ for fully self-contained, audio-enabled operation.
#
# Why build from source?
#   The Homebrew QEMU 11 bottle does not include the Screamer audio chip
#   (Apple's AWACS Screamer codec, used in Power Mac G4). Screamer was removed
#   from upstream QEMU during the audio subsystem refactor and has not been
#   re-merged. Mark Cave-Ayland maintains a standalone "screamer" branch at
#   github.com/mcayland/qemu that adds it back. This script clones, builds,
#   and vendors that branch. The result replaces the Homebrew-based vendor step.
#
# What this script does (in order):
#   1. Checks that Xcode Command Line Tools are installed
#   2. Installs build-time tools via Homebrew (meson, ninja, pkg-config)
#      and ensures the QEMU runtime libraries are present
#   3. Shallow-clones the screamer branch into a temporary directory
#   4. Configures QEMU for PPC only (ppc-softmmu) - skips x86, ARM, etc.
#      to keep build time to ~10 minutes instead of 60+
#   5. Compiles using all available CPU cores
#   6. Creates vendor/qemu/{bin,lib,share}/
#   7. Copies the screamer qemu-system-ppc binary
#   8. Copies Homebrew's qemu-img (disk image tool, doesn't need Screamer)
#   9. Copies Homebrew's unar (for extracting .sit patch archives)
#  10. Recursively bundles all non-system dylib dependencies and rewrites
#      their load paths to @loader_path so the binaries are portable
#  11. Copies QEMU firmware files (OpenBIOS, option ROMs) from the build
#  12. Ad-hoc signs every binary and dylib (required on Apple Silicon)
#  13. Removes the temporary build directory to reclaim ~800 MB
#
# After this script completes, vendor/qemu/ is fully self-contained.
# No Homebrew, no QEMU installation, and no internet access is required
# to run the emulator on any ARM64 Mac.
#
# Usage:
#   bash scripts/build-qemu-screamer.sh
#   - or -
#   make vendor   (calls this script)
#
# Requirements (automatically installed by this script if missing):
#   - Xcode Command Line Tools   (xcode-select --install)
#   - Homebrew                   (https://brew.sh)
#   - meson, ninja, pkg-config   (installed via brew in this script)
#   - QEMU Homebrew runtime libs (glib, pixman, gnutls, etc.)
#
# Estimated time: ~10 minutes on M1/M2/M3/M4 (PPC-only build)
# Estimated disk: ~800 MB temporary (cleaned up); ~60 MB final vendor/
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

BREW_PREFIX="/opt/homebrew"
VENDOR="${REPO_ROOT}/vendor/qemu"
BIN_DIR="${VENDOR}/bin"
LIB_DIR="${VENDOR}/lib"
SHARE_DIR="${VENDOR}/share"

SCREAMER_REPO="https://github.com/mcayland/qemu.git"
SCREAMER_BRANCH="screamer"

# Build output goes to a temp dir (cleaned up at the end to save ~800 MB)
BUILD_TMP="${TMPDIR:-/tmp}/ferazel-qemu-screamer-build-$$"

# ── Step 0: already vendored? ─────────────────────────────────────────────────

if [[ -d "${VENDOR}/bin" ]]; then
    echo "vendor/qemu/ already exists. Run 'make clean' first to rebuild."
    exit 0
fi

# ── Step 1: check Xcode Command Line Tools ────────────────────────────────────

echo "==> Checking build prerequisites..."

if ! xcode-select -p &>/dev/null; then
    echo ""
    echo "ERROR: Xcode Command Line Tools are not installed."
    echo ""
    echo "Install them by running:"
    echo "  xcode-select --install"
    echo ""
    echo "Then re-run this script after installation completes."
    exit 1
fi

if ! command -v clang &>/dev/null; then
    echo "ERROR: clang not found. Xcode Command Line Tools may be incomplete."
    exit 1
fi

echo "  Xcode CLT: OK ($(clang --version 2>&1 | head -1))"

# ── Step 2: install build tools via Homebrew ─────────────────────────────────

if [[ ! -x "${BREW_PREFIX}/bin/brew" ]]; then
    echo ""
    echo "ERROR: Homebrew not found at ${BREW_PREFIX}."
    echo ""
    echo "Install Homebrew first:"
    echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    echo ""
    echo "Then re-run: make setup && make vendor"
    exit 1
fi

BREW="${BREW_PREFIX}/bin/brew"

echo ""
echo "==> Installing build tools (meson, ninja, pkg-config)..."

# These are build-time only; they are NOT bundled into vendor/
for pkg in meson ninja pkg-config; do
    if [[ ! -x "${BREW_PREFIX}/bin/${pkg}" ]] && \
       [[ ! -x "${BREW_PREFIX}/bin/pkgconf" ]]; then
        echo "  Installing ${pkg}..."
        "${BREW}" install "${pkg}" 2>&1 | grep -E "Pouring|Installing|Error" | head -3 || true
    fi
done

# Make sure the QEMU runtime libraries are installed (needed by qemu-img and unar)
echo ""
echo "==> Ensuring QEMU runtime libraries are present..."
if ! "${BREW}" list qemu &>/dev/null 2>&1; then
    echo "  Installing qemu (for qemu-img, unar, and runtime libs)..."
    "${BREW}" install qemu unar 2>&1 | grep -E "Pouring|Installing|Error" | head -5 || true
fi
if ! "${BREW}" list unar &>/dev/null 2>&1; then
    "${BREW}" install unar 2>&1 | grep -E "Pouring|Installing|Error" | head -3 || true
fi

# ── Step 3: clone screamer branch ─────────────────────────────────────────────

echo ""
echo "==> Cloning mcayland/qemu screamer branch (shallow)..."
echo "    Source: ${SCREAMER_REPO}"
echo "    Branch: ${SCREAMER_BRANCH}"
echo "    This downloads ~120 MB..."
echo ""

mkdir -p "${BUILD_TMP}"
git clone --depth=1 --recursive -b "${SCREAMER_BRANCH}" \
    "${SCREAMER_REPO}" \
    "${BUILD_TMP}/qemu-screamer" 2>&1 | grep -E "Cloning|Submodule|error" | head -20

QEMU_SRC="${BUILD_TMP}/qemu-screamer"
QEMU_BUILD="${QEMU_SRC}/build"

echo "  Cloned: QEMU $(cat "${QEMU_SRC}/VERSION") with Screamer audio"

# ── Step 3.5: patch cocoa.m for zoom-to-fit in fullscreen ─────────────────────
# QEMU 7.1.94 has no zoom-to-fit CLI flag - it only exists as a View menu item.
# The internal variable is `stretch_video` (a file-static bool). We set it to
# true immediately after toggleFullScreen: so every fullscreen launch scales to
# fill the display without any manual menu interaction.

echo ""
echo "==> Patching cocoa.m: zoom-to-fit in fullscreen..."
COCOA_M="${QEMU_SRC}/ui/cocoa.m"
python3 - "${COCOA_M}" <<'PYEOF'
import sys
path = sys.argv[1]
with open(path) as f:
    src = f.read()
old = '        [controller toggleFullScreen: nil];\n    }'
new = '        [controller toggleFullScreen: nil];\n        stretch_video = true; /* zoom-to-fit patch */\n    }'
if old not in src:
    print("  ERROR: patch target not found in cocoa.m - source may have changed")
    sys.exit(1)
patched = src.replace(old, new, 1)
with open(path, 'w') as f:
    f.write(patched)
print("  Patched: stretch_video=true on fullscreen launch")
PYEOF

# ── Step 3.6: patch cocoa.m for black letterbox/pillarbox background ──────────
# By default the NSWindow background is macOS beige/gray. On widescreen displays
# a 4:3 Mac OS 9 guest leaves pillarbox bars on the sides. Setting the window
# background to black makes those bars match the classic fullscreen look.
# (The fullscreen NSWindow already has this set; we mirror it for normalWindow.)

echo ""
echo "==> Patching cocoa.m: black window background..."
python3 - "${COCOA_M}" <<'PYEOF'
import sys
path = sys.argv[1]
with open(path) as f:
    src = f.read()
old = '        [normalWindow setAcceptsMouseMovedEvents:YES];\n        [normalWindow setTitle:@"QEMU"];\n        [normalWindow setContentView:cocoaView];\n        [normalWindow makeKeyAndOrderFront:self];\n        [normalWindow center];\n        [normalWindow setDelegate: self];'
new = '        [normalWindow setBackgroundColor:[NSColor blackColor]]; /* black sidebar patch */\n        [normalWindow setAcceptsMouseMovedEvents:YES];\n        [normalWindow setTitle:@"QEMU"];\n        [normalWindow setContentView:cocoaView];\n        [normalWindow makeKeyAndOrderFront:self];\n        [normalWindow center];\n        [normalWindow setDelegate: self];'
if old not in src:
    print("  ERROR: patch target not found in cocoa.m - source may have changed")
    sys.exit(1)
patched = src.replace(old, new, 1)
with open(path, 'w') as f:
    f.write(patched)
print("  Patched: black window background for pillarbox/letterbox bars")
PYEOF

# ── Step 4: configure ─────────────────────────────────────────────────────────

echo ""
echo "==> Configuring QEMU (ppc-softmmu target only)..."
echo "    Skipping x86, ARM, MIPS, etc. to keep build time to ~10 minutes."
echo ""

PKG_CONFIG_PATH="${BREW_PREFIX}/opt/ncurses/lib/pkgconfig:${BREW_PREFIX}/lib/pkgconfig"

cd "${QEMU_SRC}" && \
    PATH="${BREW_PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PKG_CONFIG_PATH}" \
    PKG_CONFIG="${BREW_PREFIX}/bin/pkg-config" \
    ./configure \
        --target-list="ppc-softmmu" \
        --disable-docs \
        --disable-guest-agent \
        2>&1 | grep -E "Audio drivers|CoreAudio|Error|WARNING" | head -10

echo "  Configuration complete."

# ── Step 5: build ─────────────────────────────────────────────────────────────

NCPUS=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)

echo ""
echo "==> Building qemu-system-ppc with ${NCPUS} cores..."
echo "    Expected time: ~8-15 minutes depending on your Mac."
echo "    (M1 Pro ~8 min, M1 base ~12 min)"
echo ""

PATH="${BREW_PREFIX}/bin:${PATH}" \
    "${BREW_PREFIX}/bin/ninja" -C "${QEMU_BUILD}" -j"${NCPUS}" qemu-system-ppc 2>&1 \
    | grep -E "^\[|error:|warning:|ld:" \
    | grep -v "duplicate libraries" \
    | tail -5

echo ""
echo "  Build complete: $(ls -lh "${QEMU_BUILD}/qemu-system-ppc" | awk '{print $5}')"

# Verify Screamer was compiled in (CONFIG_SCREAMER=y in build config)
SCREAMER_CONFIG="${QEMU_BUILD}/ppc-softmmu-config-devices.h"
if [[ -f "${SCREAMER_CONFIG}" ]] && grep -q "CONFIG_SCREAMER 1" "${SCREAMER_CONFIG}" 2>/dev/null; then
    echo "  Screamer audio: CONFIG_SCREAMER confirmed in build"
else
    echo "  WARNING: Could not verify CONFIG_SCREAMER - continuing anyway"
fi

# ── Step 6: create vendor directories ─────────────────────────────────────────

echo ""
echo "==> Creating vendor/qemu/ structure..."

mkdir -p "${BIN_DIR}" "${LIB_DIR}" "${SHARE_DIR}"

# ── Step 7: dylib bundler ─────────────────────────────────────────────────────
# Recursively copies non-system dylibs referenced by a binary and rewrites
# their load paths to @loader_path so they're found relative to the binary.
# Works on binaries (BIN_DIR) and dylibs (LIB_DIR) alike.
# Uses file-existence checks instead of associative arrays (bash 3.2 compat -
# macOS system bash doesn't support declare -A. See qemu.conf.sh quirk #7).

bundle_dylibs() {
    local target="$1"
    local deps
    deps="$(otool -L "${target}" 2>/dev/null | tail -n +2 | awk '{print $1}')"

    while IFS= read -r dep; do
        [[ -z "${dep}" ]]                    && continue
        [[ "${dep}" == /usr/lib/* ]]         && continue
        [[ "${dep}" == /System/* ]]          && continue
        [[ "${dep}" == @rpath/* ]]           && continue
        [[ "${dep}" == @loader_path/* ]]     && continue
        [[ "${dep}" == @executable_path/* ]] && continue

        local libname
        libname="$(basename "${dep}")"
        local dest="${LIB_DIR}/${libname}"

        local new_ref
        if [[ "${target}" == "${BIN_DIR}/"* ]]; then
            new_ref="@loader_path/../lib/${libname}"
        else
            new_ref="@loader_path/${libname}"
        fi
        install_name_tool -change "${dep}" "${new_ref}" "${target}" 2>/dev/null || true

        if [[ ! -f "${dest}" ]]; then
            if [[ -f "${dep}" ]]; then
                echo "    + ${libname}"
                cp "${dep}" "${dest}"
                chmod 755 "${dest}"
                install_name_tool -id "@loader_path/${libname}" "${dest}" 2>/dev/null || true
                bundle_dylibs "${dest}"
            fi
        fi
    done <<< "${deps}"
}

# ── Step 8: copy qemu-system-ppc (screamer build) ─────────────────────────────

echo ""
echo "==> Bundling qemu-system-ppc (screamer build)..."
cp "${QEMU_BUILD}/qemu-system-ppc" "${BIN_DIR}/qemu-system-ppc"
chmod 755 "${BIN_DIR}/qemu-system-ppc"
bundle_dylibs "${BIN_DIR}/qemu-system-ppc"

# ── Step 9: copy qemu-img (from Homebrew) ─────────────────────────────────────
# qemu-img creates and converts disk images. It doesn't need Screamer, so we
# use the Homebrew QEMU package's qemu-img rather than building it from scratch.

echo ""
echo "==> Bundling qemu-img (from Homebrew QEMU)..."
if [[ -x "${BREW_PREFIX}/bin/qemu-img" ]]; then
    cp "${BREW_PREFIX}/bin/qemu-img" "${BIN_DIR}/qemu-img"
    chmod 755 "${BIN_DIR}/qemu-img"
    bundle_dylibs "${BIN_DIR}/qemu-img"
else
    echo "  WARNING: qemu-img not found in Homebrew. Disk creation may fail."
    echo "           Run 'brew install qemu' and then 'make vendor' again."
fi

# ── Step 10: copy unar (from Homebrew) ────────────────────────────────────────
# unar extracts .sit archives with resource fork metadata (AppleDouble format),
# required for applying the v1.0.3 and no-gamma patches to the game binary.

echo ""
echo "==> Bundling unar (from Homebrew)..."
if [[ -x "${BREW_PREFIX}/bin/unar" ]]; then
    cp "${BREW_PREFIX}/bin/unar" "${BIN_DIR}/unar"
    chmod 755 "${BIN_DIR}/unar"
    bundle_dylibs "${BIN_DIR}/unar"
else
    echo "  WARNING: unar not found in Homebrew. Patch application will fall back"
    echo "           to the Homebrew unar if available on PATH."
fi

# ── Step 11: copy QEMU firmware ───────────────────────────────────────────────
# Two-phase firmware copy:
#   Phase A: copy all option ROMs from Homebrew QEMU (provides vgabios, sgabios,
#            efi-*.rom, etc. that are not in the screamer source tree).
#   Phase B: overwrite with the screamer source tree's pc-bios/ files -
#            critically openbios-ppc, which is a custom build that includes
#            Screamer DBDMA device-tree entries. Using Homebrew's standard
#            openbios-ppc silently breaks audio: Mac OS 9 detects the Screamer
#            device but the DMA channels are never mapped, so no audio ever plays.

echo ""
echo "==> Copying QEMU firmware..."
FIRMWARE_SRC="${BREW_PREFIX}/share/qemu"
mkdir -p "${SHARE_DIR}/qemu"
if [[ -d "${FIRMWARE_SRC}" ]]; then
    cp -r "${FIRMWARE_SRC}/." "${SHARE_DIR}/qemu/"
    echo "  Phase A: Homebrew option ROMs copied"
else
    echo "  ERROR: Homebrew QEMU firmware not found at ${FIRMWARE_SRC}."
    echo "         Run 'brew install qemu' and retry."
    exit 1
fi

# Phase B: overwrite with screamer-specific firmware from the source tree
SCREAMER_BIOS="${QEMU_SRC}/pc-bios"
if [[ -d "${SCREAMER_BIOS}" ]]; then
    find "${SCREAMER_BIOS}" -maxdepth 1 -type f | while read -r rom; do
        cp "${rom}" "${SHARE_DIR}/qemu/"
    done
    echo "  Phase B: screamer pc-bios/ overlay applied (includes custom openbios-ppc)"
else
    echo "  WARNING: screamer pc-bios/ not found at ${SCREAMER_BIOS} - using Homebrew openbios-ppc"
    echo "           Audio DMA will likely not work without the screamer-specific OpenBIOS."
fi

if [[ ! -f "${SHARE_DIR}/qemu/openbios-ppc" ]]; then
    echo "  ERROR: openbios-ppc missing. mac99 will not boot."
    exit 1
fi
echo "  openbios-ppc: $(du -h "${SHARE_DIR}/qemu/openbios-ppc" | awk '{print $1}') (screamer build)"
echo "  Firmware total: $(du -sh "${SHARE_DIR}/qemu" | awk '{print $1}')"

# ── Step 12: sign everything ──────────────────────────────────────────────────
# Apple Silicon requires code signatures on executables and dylibs. We use
# ad-hoc signing (no Apple Developer account needed). This is the same
# approach used by Homebrew for its own QEMU builds.

echo ""
echo "==> Ad-hoc signing binaries and libraries..."
for f in "${BIN_DIR}"/*; do
    [[ -f "${f}" ]] || continue
    codesign --force --sign - "${f}" 2>/dev/null || true
    echo "  Signed: $(basename "${f}")"
done
for f in "${LIB_DIR}"/*.dylib; do
    [[ -f "${f}" ]] || continue
    codesign --force --sign - "${f}" 2>/dev/null || true
done
echo "  Signed: $(find "${LIB_DIR}" -name '*.dylib' | wc -l | tr -d ' ') dylibs"

# ── Step 13: clean up build directory ─────────────────────────────────────────
# The build directory is ~800 MB. Remove it to reclaim space.
# The final vendor/qemu/ is ~60 MB.

echo ""
echo "==> Cleaning up build directory (~800 MB)..."
rm -rf "${BUILD_TMP}"
echo "  Removed: ${BUILD_TMP}"

# ── Summary ───────────────────────────────────────────────────────────────────

lib_count="$(find "${LIB_DIR}" -name '*.dylib' | wc -l | tr -d ' ')"
share_size="$(du -sh "${SHARE_DIR}/qemu" 2>/dev/null | awk '{print $1}')"
qemu_ver="$("${BIN_DIR}/qemu-system-ppc" --version 2>/dev/null | head -1)"

echo ""
echo "==> vendor/qemu/ ready."
echo ""
echo "    QEMU   : ${qemu_ver}"
echo "    Audio  : Screamer (AWACS codec for mac99 / Power Mac G4)"
echo "    Bins   : $(ls "${BIN_DIR}" | tr '\n' ' ')"
echo "    Dylibs : ${lib_count} (${LIB_DIR})"
echo "    Firmware: ${share_size} (${SHARE_DIR}/qemu)"
echo ""
echo "    The repo is now self-contained with audio."
echo "    Copy to any ARM64 Mac - no Homebrew, no internet needed."
echo ""
echo "Next: run 'make create-disk' (or 'make bootstrap' for the full setup)."
