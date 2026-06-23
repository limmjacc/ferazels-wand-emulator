#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  Setup.command  -  Ferazel's Wand One-Time Setup
#
#  Double-click this file in Finder to run the complete setup pipeline.
#  A Terminal window opens and walks through all 6 steps automatically.
#
#  Steps performed:
#    1. Install build tools via Homebrew (meson, ninja, pkg-config, qemu, unar)
#    2. Build QEMU with Screamer audio from source (~10 min) + bundle into vendor/
#    3. Create a blank 6 GB Mac OS 9 disk image
#    4. INTERACTIVE: boot Mac OS 9 installer, initialize disk, install OS (~10 min)
#    5. INTERACTIVE: boot with game CD, run installer, shut down (~3 min)
#    6. AUTOMATED: apply v1.0.3 + no-gamma patches from macOS
#
#  Steps 4 and 5 require brief interaction inside the QEMU window.
#  All other steps run without input.
#
#  Prerequisites:
#    - Place required disk images in disks/ before running (see README.md)
#    - Xcode Command Line Tools: xcode-select --install
#    (Homebrew is installed automatically if not already present)
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "${REPO_ROOT}"
make bootstrap
