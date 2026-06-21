#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  bootstrap.sh  —  Full One-Shot Setup Pipeline
#
#  Runs all 6 setup steps in sequence from a clean repo to a playable game:
#    Step 1: Install Homebrew dependencies (setup.sh)
#    Step 2: Build QEMU with Screamer audio from source (build-qemu-screamer.sh)
#    Step 3: Create blank 6 GB disk image (create-disk.sh)
#    Step 4: Install Mac OS 9 - INTERACTIVE (install-os.sh)
#    Step 5: Install Ferazel's Wand - INTERACTIVE (install-game.sh)
#    Step 6: Apply v1.0.3 + no-gamma patches - automated (apply-patches.sh)
#
#  Steps 4 and 5 open a QEMU window and require brief Mac OS 9 interaction.
#  The script blocks until Mac OS 9 shuts down, then automatically resumes.
#  All other steps run without input.
#
#  Usage: make bootstrap  (or double-click Setup.command)
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

divider() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# ── Step 1: Install tools ─────────────────────────────────────────────────────

divider "Step 1 / 6 - Install tools (QEMU + unar via Homebrew)"
bash "${SCRIPT_DIR}/setup.sh"

# ── Step 2: Bundle QEMU into vendor/ ─────────────────────────────────────────

divider "Step 2 / 6 - Build QEMU with Screamer audio + bundle into vendor/ (~10 min)"
bash "${SCRIPT_DIR}/build-qemu-screamer.sh"

# ── Step 3: Create blank disk ─────────────────────────────────────────────────

divider "Step 3 / 6 - Create blank 6 GB disk image"
bash "${SCRIPT_DIR}/create-disk.sh"

# ── Step 4: Install Mac OS 9 (interactive) ───────────────────────────────────

divider "Step 4 / 6 - Install Mac OS 9  [INTERACTIVE - ~10 min]"
echo "  Instructions are printed below. QEMU opens next."
echo "  When Mac OS 9 finishes installing: Special → Shut Down"
echo "  This script resumes automatically after shutdown."
echo ""

bash "${SCRIPT_DIR}/install-os.sh"

echo ""
echo "  ✓ Step 4 complete."

# ── Step 5: Install game (interactive) ───────────────────────────────────────

divider "Step 5 / 6 - Install Ferazel's Wand  [INTERACTIVE - ~3 min]"
echo "  Instructions are printed below. QEMU opens next."
echo "  When the installer finishes: Special → Shut Down"
echo "  This script resumes automatically after shutdown."
echo ""

bash "${SCRIPT_DIR}/install-game.sh"

echo ""
echo "  ✓ Step 5 complete."

# ── Step 6: Apply patches (automated) ────────────────────────────────────────

divider "Step 6 / 6 - Apply patches  [automated]"
bash "${SCRIPT_DIR}/apply-patches.sh"

# ── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  All done! Ferazel's Wand is ready to play."
echo ""
echo "  Double-click Play.command"
echo "  - or -"
echo "  make launch"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
