#!/usr/bin/env bash
set -euo pipefail

BREW="/opt/homebrew/bin/brew"

echo "==> Ferazel's Wand Emulator — dependency setup"
echo ""

# Verify Apple Silicon
arch="$(uname -m)"
if [[ "${arch}" != "arm64" ]]; then
    echo "WARNING: Expected arm64, got ${arch}. This project targets Apple Silicon."
fi

# Verify Homebrew
if [[ ! -x "${BREW}" ]]; then
    echo "ERROR: Homebrew not found at ${BREW}"
    echo "       Install it from https://brew.sh, then re-run."
    exit 1
fi
echo "  Homebrew: $("${BREW}" --version | head -1)"

# Install QEMU
if "${BREW}" list qemu &>/dev/null; then
    echo "  QEMU: already installed ($("${BREW}" list --versions qemu))"
else
    echo "  Installing QEMU (this may take a few minutes)..."
    "${BREW}" install qemu
fi

QEMU_BIN="/opt/homebrew/bin/qemu-system-ppc"
if [[ ! -x "${QEMU_BIN}" ]]; then
    echo "ERROR: qemu-system-ppc not found after installation."
    exit 1
fi

echo "  QEMU binary: ${QEMU_BIN}"
echo "  QEMU version: $("${QEMU_BIN}" --version | head -1)"
echo ""
echo "==> Setup complete."
echo ""
echo "Next step: run 'make vendor' to bundle QEMU into this repo for portability."
