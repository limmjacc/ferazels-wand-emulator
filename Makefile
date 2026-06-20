SHELL := /bin/bash
.PHONY: help bootstrap setup vendor create-disk install-os install-game apply-patches launch clean reset-disk

help:
	@echo ""
	@echo "Ferazel's Wand - QEMU-PPC Emulator for Apple Silicon"
	@echo "======================================================"
	@echo ""
	@echo "After setup, just double-click Play.command to play."
	@echo ""
	@echo "QUICKSTART - run all setup steps in one command:"
	@echo ""
	@echo "  make bootstrap      Full pipeline: setup → vendor → OS install → game install → patch"
	@echo ""
	@echo "  (Two interactive QEMU windows open during bootstrap."
	@echo "   The script resumes automatically each time you shut down Mac OS 9.)"
	@echo ""
	@echo "OR run each step individually:"
	@echo ""
	@echo "  1.  make setup          Install build deps via Homebrew (needs internet)"
	@echo "  2.  make vendor         Build QEMU with Screamer audio (~10 min) + bundle into vendor/"
	@echo "  3.  make create-disk    Create a blank 6 GB Mac OS 9 disk image"
	@echo ""
	@echo "  Place these files in disks/ before continuing:"
	@echo "    disks/macos9.iso                       Mac OS 9.2.2 installer ISO"
	@echo "    disks/Ferazel's Wand 1.0.2.ISO         Game CD image"
	@echo "    disks/Ferazel's Wand 1.0.3 update.sit  v1.0.3 patch"
	@echo "    disks/Ferazels_Wand_103_nogamma.sit    No-gamma patch (required for QEMU)"
	@echo ""
	@echo "  4.  make install-os     INTERACTIVE (~10 min): boot ISO, install Mac OS 9"
	@echo "  5.  make install-game   INTERACTIVE (~3 min):  run game CD installer, shut down"
	@echo "  6.  make apply-patches  AUTOMATED: apply v1.0.3 + no-gamma from macOS"
	@echo ""
	@echo "Daily use:"
	@echo "  Double-click Play.command   ← recommended"
	@echo "  make launch                 ← same thing from Terminal"
	@echo ""
	@echo "Maintenance:"
	@echo "  make reset-disk   Wipe disks/macos9.img and start over (destructive)"
	@echo "  make clean        Remove vendor/qemu/ (re-run setup + vendor to rebuild)"
	@echo ""
	@echo "See docs/setup-guide.md for the full walkthrough."
	@echo ""

# ── Full bootstrap (all steps in sequence) ───────────────────────────────────

bootstrap:
	@bash scripts/bootstrap.sh

# ── One-time setup ────────────────────────────────────────────────────────────

setup:
	@bash scripts/setup.sh

vendor:
	@bash scripts/build-qemu-screamer.sh

create-disk:
	@bash scripts/create-disk.sh

# ── Interactive sessions ──────────────────────────────────────────────────────

install-os:
	@bash scripts/install-os.sh

install-game:
	@bash scripts/install-game.sh

# ── Automated patch application ───────────────────────────────────────────────

apply-patches:
	@bash scripts/apply-patches.sh

# ── Daily use ─────────────────────────────────────────────────────────────────

launch:
	@bash scripts/launch.sh

# ── Maintenance ───────────────────────────────────────────────────────────────

reset-disk:
	@echo "WARNING: This permanently destroys disks/macos9.img."
	@read -r -p "Type 'yes' to confirm: " c && [ "$$c" = "yes" ] || { echo "Aborted."; exit 1; }
	@rm -f disks/macos9.img
	@echo "Deleted disks/macos9.img. Run 'make create-disk' to start fresh."

clean:
	@echo "==> Removing vendor/qemu/ ..."
	@rm -rf vendor/qemu
	@echo "    Re-run 'make setup && make vendor' to rebuild."
