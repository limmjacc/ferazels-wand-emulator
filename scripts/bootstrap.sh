#!/usr/bin/env bash
# Full one-shot setup from a clean repo to a playable game.
#
# The two interactive QEMU sessions (install-os, install-game) block here.
# The script resumes automatically when you shut down Mac OS 9 each time.
# Everything else is fully automated.
#
# Usage: make bootstrap
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

divider "Step 1 / 6 — Install tools (QEMU + unar via Homebrew)"
bash "${SCRIPT_DIR}/setup.sh"

# ── Step 2: Bundle QEMU into vendor/ ─────────────────────────────────────────

divider "Step 2 / 6 — Bundle QEMU into vendor/ (self-contained)"
bash "${SCRIPT_DIR}/vendor-qemu.sh"

# ── Step 3: Create blank disk ─────────────────────────────────────────────────

divider "Step 3 / 6 — Create blank 6 GB disk image"
bash "${SCRIPT_DIR}/create-disk.sh"

# ── Step 4: Install Mac OS 9 (interactive) ───────────────────────────────────

divider "Step 4 / 6 — Install Mac OS 9  [INTERACTIVE — ~10 min]"
echo "  Instructions are printed below. QEMU opens next."
echo "  When Mac OS 9 finishes installing: Special → Shut Down"
echo "  This script resumes automatically after shutdown."
echo ""

bash "${SCRIPT_DIR}/install-os.sh"

echo ""
echo "  ✓ Step 4 complete."

# ── Step 5: Install game (interactive) ───────────────────────────────────────

divider "Step 5 / 6 — Install Ferazel's Wand  [INTERACTIVE — ~3 min]"
echo "  Instructions are printed below. QEMU opens next."
echo "  When the installer finishes: Special → Shut Down"
echo "  This script resumes automatically after shutdown."
echo ""

bash "${SCRIPT_DIR}/install-game.sh"

echo ""
echo "  ✓ Step 5 complete."

# ── Step 6: Apply patches (automated) ────────────────────────────────────────

divider "Step 6 / 6 — Apply patches  [automated]"
bash "${SCRIPT_DIR}/apply-patches.sh"

# ── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  All done! Ferazel's Wand is ready to play."
echo ""
echo "  Double-click FerazelsWand.app"
echo "  — or —"
echo "  make launch"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
