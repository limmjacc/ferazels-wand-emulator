#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  setup.sh  —  One-Time Dependency Installation
#
# Installs via Homebrew:
#   - qemu          Runtime libraries + qemu-img disk tool
#   - unar          StuffIt extractor (for .sit patch archives)
#   - meson         Build system (required to compile screamer QEMU from source)
#   - ninja         Parallel build tool (used by meson)
#   - pkg-config    Library detection (required by QEMU configure step)
#
# After this, run 'make vendor' which builds QEMU from source with Screamer
# audio support and bundles everything into vendor/qemu/ for portability.
# Homebrew is not required at runtime after 'make vendor' completes.
set -euo pipefail

BREW="/opt/homebrew/bin/brew"

echo "==> Ferazel's Wand - one-time setup"
echo ""

if [[ "$(uname -m)" != "arm64" ]]; then
    echo "WARNING: Expected arm64 (Apple Silicon). Got $(uname -m)."
    echo "         This project targets M1/M2/M3/M4 Macs."
fi

if [[ ! -x "${BREW}" ]]; then
    echo "  Homebrew not found. Installing now (this may take a few minutes)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ ! -x "${BREW}" ]]; then
        echo "ERROR: Homebrew installation failed or was not installed to ${BREW}."
        echo "       Install it manually from https://brew.sh then re-run 'make setup'."
        exit 1
    fi
fi
echo "  Homebrew: $("${BREW}" --version | head -1)"
echo ""

# ── Xcode Command Line Tools ──────────────────────────────────────────────────
# Required to build QEMU from source. The Xcode CLT provides clang, make,
# git, and the macOS SDK headers. Usually already present on developer Macs.

if ! xcode-select -p &>/dev/null; then
    echo "ERROR: Xcode Command Line Tools are not installed."
    echo ""
    echo "Run the following, then re-run 'make setup':"
    echo "  xcode-select --install"
    echo ""
    exit 1
fi
echo "  Xcode CLT: $(xcode-select -p)"

# ── QEMU (runtime libs + qemu-img) ───────────────────────────────────────────
# We install Homebrew QEMU for two things:
#   1. qemu-img: the disk image creation tool (doesn't need Screamer audio)
#   2. Runtime dylib dependencies that the screamer build links against
# Note: qemu-system-ppc from Homebrew has no Screamer audio. 'make vendor'
# replaces it with a custom build. See scripts/build-qemu-screamer.sh.

if "${BREW}" list qemu &>/dev/null; then
    echo "  QEMU: already installed ($("${BREW}" list --versions qemu))"
else
    echo "  Installing QEMU (runtime libs + qemu-img)..."
    "${BREW}" install qemu
fi

QEMU_BIN="/opt/homebrew/bin/qemu-system-ppc"
if [[ ! -x "${QEMU_BIN}" ]]; then
    echo "ERROR: qemu-system-ppc not found after install."
    exit 1
fi
echo "  QEMU: $("${QEMU_BIN}" --version | head -1)"

# ── unar (The Unarchiver CLI) ─────────────────────────────────────────────────
# Extracts .sit StuffIt archives with resource fork metadata in AppleDouble
# format. Used by 'make apply-patches' to extract the v1.0.3 and no-gamma
# patch archives before copying them into the mounted disk image.

if "${BREW}" list unar &>/dev/null; then
    echo "  unar: already installed ($("${BREW}" list --versions unar))"
else
    echo "  Installing unar (StuffIt extractor)..."
    "${BREW}" install unar
fi

UNAR_BIN="/opt/homebrew/bin/unar"
if [[ ! -x "${UNAR_BIN}" ]]; then
    echo "ERROR: unar not found after install."
    exit 1
fi
echo "  unar: $("${UNAR_BIN}" --version 2>&1 | head -1)"

# ── Build tools (meson, ninja, pkg-config) ────────────────────────────────────
# These are needed to compile the Screamer-enabled QEMU from source in
# 'make vendor'. They are build-time only and are NOT bundled into vendor/.
# meson: the build system used by QEMU (replaces autotools in QEMU 5.2+)
# ninja: the parallel build backend invoked by meson
# pkg-config: detects library paths and compiler flags during configure

echo ""
echo "  Installing build tools (meson, ninja, pkg-config)..."
for pkg in meson ninja pkg-config; do
    if "${BREW}" list "${pkg}" &>/dev/null 2>&1 || \
       [[ -x "/opt/homebrew/bin/${pkg}" ]]; then
        echo "  ${pkg}: already installed"
    else
        echo "  Installing ${pkg}..."
        "${BREW}" install "${pkg}" 2>&1 | grep -E "Pouring|Installing|Error" | head -2 || true
    fi
done

echo ""
echo "==> Setup complete."
echo ""
echo "Next: run 'make vendor' to build QEMU with Screamer audio (~10 min) and"
echo "      bundle everything into vendor/ for portable, self-contained operation."
