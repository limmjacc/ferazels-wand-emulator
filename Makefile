SHELL := /bin/bash
.PHONY: help setup vendor create-disk install-os launch clean

help:
	@echo ""
	@echo "Ferazel's Wand Emulator"
	@echo "========================"
	@echo ""
	@echo "After setup, just double-click FerazelsWand.app to play."
	@echo ""
	@echo "First-time setup (run once, in order):"
	@echo "  make setup         Install QEMU via Homebrew"
	@echo "  make vendor        Bundle QEMU into vendor/ — Homebrew not needed after this"
	@echo "  make create-disk   Create a blank Mac OS 9 disk image in disks/"
	@echo "  make install-os    Boot from Mac OS 9 ISO to install the OS"
	@echo ""
	@echo "Daily use:"
	@echo "  Double-click FerazelsWand.app  ← the normal way to play"
	@echo "  make launch                    ← same thing, from Terminal"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean         Remove vendored QEMU (re-run setup + vendor to rebuild)"
	@echo ""
	@echo "See docs/setup-guide.md for full instructions."
	@echo ""

setup:
	@bash scripts/setup.sh

vendor:
	@bash scripts/vendor-qemu.sh

create-disk:
	@bash scripts/create-disk.sh

install-os:
	@bash scripts/install-os.sh

launch:
	@bash scripts/launch.sh

clean:
	@echo "==> Removing vendor/qemu/ ..."
	@rm -rf vendor/qemu
	@echo "    Re-run 'make setup && make vendor' to rebuild."
