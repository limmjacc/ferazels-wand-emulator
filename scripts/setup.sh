#!/usr/bin/env bash
# One-time dependency setup — installs QEMU and unar via Homebrew.
# After this, run 'make vendor' to bundle everything so Homebrew is not
# required at runtime.
set -euo pipefail

BREW="/opt/homebrew/bin/brew"

echo "==> Ferazel's Wand — one-time setup"
echo ""

if [[ "$(uname -m)" != "arm64" ]]; then
    echo "WARNING: Expected arm64 (Apple Silicon). Got $(uname -m)."
    echo "         This project targets M1/M2/M3/M4 Macs."
fi

if [[ ! -x "${BREW}" ]]; then
    echo "ERROR: Homebrew not found at ${BREW}."
    echo "       Install it from https://brew.sh then re-run 'make setup'."
    exit 1
fi
echo "  Homebrew: $("${BREW}" --version | head -1)"
echo ""

# ── QEMU ─────────────────────────────────────────────────────────────────────

if "${BREW}" list qemu &>/dev/null; then
    echo "  QEMU: already installed ($("${BREW}" list --versions qemu))"
else
    echo "  Installing QEMU (this may take a few minutes)..."
    "${BREW}" install qemu
fi

QEMU_BIN="/opt/homebrew/bin/qemu-system-ppc"
if [[ ! -x "${QEMU_BIN}" ]]; then
    echo "ERROR: qemu-system-ppc not found after install."
    exit 1
fi
echo "  QEMU: $("${QEMU_BIN}" --version | head -1)"

# ── unar (The Unarchiver CLI) ─────────────────────────────────────────────────
# Used by 'make apply-patches' to extract .sit StuffIt archives on macOS.

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

echo ""
echo "==> Setup complete."
echo ""
echo "Next: run 'make vendor' to bundle QEMU + unar into vendor/ for portability."
