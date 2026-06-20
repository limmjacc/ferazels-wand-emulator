# Ferazel's Wand — QEMU-PPC Emulator

Run the original 1999 Ambrosia Software Mac OS 9 game on Apple Silicon Macs.
Self-contained — no Homebrew or external dependencies after one-time setup.

---

## Play

After setup: **double-click `FerazelsWand.app`**.

All game saves live inside `disks/macos9.img` in this folder. They survive reboots
and move with the folder. Copy the whole repo to any ARM64 Mac and it just works.

---

## One-Time Setup

### Prerequisites

- Apple Silicon Mac (M1 / M2 / M3 / M4)
- macOS 13 Ventura or later
- [Homebrew](https://brew.sh) — used once to install QEMU; not needed after `make vendor`
- ~8 GB free disk space

### Files needed in `disks/`

Download and place these files before running the setup steps:

| File | Where to get it |
|---|---|
| `disks/macos9.iso` | Mac OS 9.2.2 Universal (Macintosh Garden / Internet Archive) |
| `disks/Ferazel's Wand 1.0.2.ISO` | [Macintosh Garden — Ferazel's Wand](https://macintoshgarden.org/games/ferazels-wand) |
| `disks/Ferazel's Wand 1.0.3 update.sit` | Same page |
| `disks/Ferazels_Wand_103_nogamma.sit` | Same page — **required for QEMU stability** |

### Setup commands

```bash
make setup          # 1. install QEMU + unar via Homebrew (one-time, needs internet)
make vendor         # 2. bundle into vendor/ — no Homebrew needed after this
make create-disk    # 3. create blank 6 GB Mac OS 9 disk image
make install-os     # 4. INTERACTIVE (~10 min): install Mac OS 9
make install-game   # 5. INTERACTIVE (~3 min):  run game CD installer, shut down
make apply-patches  # 6. AUTOMATED: apply v1.0.3 + no-gamma patches from macOS
make launch         # 7. play — or just double-click FerazelsWand.app
```

Steps 4 and 5 require brief interaction inside the emulated Mac OS 9 GUI.
Each prints step-by-step instructions in the terminal before opening the QEMU window.
Step 6 is fully automated — mounts the disk on macOS and applies patches without QEMU.

See **[docs/setup-guide.md](docs/setup-guide.md)** for the detailed walkthrough.

---

## How it Works

| Component | Detail |
|---|---|
| **Emulator** | QEMU 11 `qemu-system-ppc`, machine type `mac99` (Power Mac G4) |
| **OS** | Mac OS 9.2.2 Universal |
| **Game** | Ferazel's Wand v1.0.3, no-gamma patched executable |
| **Portability** | QEMU + unar + dylibs + firmware vendored into `vendor/qemu/` |
| **Saves** | Written to `disks/macos9.img` — persist and travel with the folder |
| **No-gamma patch** | Removes the gamma screen-fade that crashes QEMU when using the dagger |

---

## About the Game

**Ferazel's Wand** (1999) is a side-scrolling platformer by Ambrosia Software / Ben Spees.
Play as Ferazel, last of the Habnabits, fighting through 23 levels to recover a stolen wand.
Crystal-based progression, hidden passages, puzzle-based boss encounters. Rated 4.75/5 on
Macintosh Garden. Reviewed in *Macworld* (August 2000).

---

## Repo Structure

```
ferazels-wand-emulator/
├── FerazelsWand.app/         ← double-click to play
├── Makefile                  ← all commands, run 'make' for help
├── config/
│   └── qemu.conf.sh          ← QEMU flags + 9 documented bring-up quirks
├── scripts/
│   ├── setup.sh              ← brew install qemu unar
│   ├── vendor-qemu.sh        ← bundle binaries + dylibs into vendor/
│   ├── create-disk.sh        ← create blank raw disk image
│   ├── install-os.sh         ← interactive: Mac OS 9 install session
│   ├── install-game.sh       ← interactive: game CD installer session
│   ├── apply-patches.sh      ← automated: mount + patch from macOS host
│   └── launch.sh             ← normal gameplay launch
├── vendor/qemu/              ← self-contained QEMU (gitignored, built by make vendor)
├── disks/                    ← all disk images (gitignored, user-provided)
└── docs/
    ├── setup-guide.md        ← full walkthrough
    └── legal-notes.md
```

---

## Legal

- **Ferazel's Wand**: Copyright Ambrosia Software. Available on Macintosh Garden (abandonware).
- **Mac OS 9**: Apple proprietary. Requires a valid license.
- **QEMU**: GPL v2.

See [docs/legal-notes.md](docs/legal-notes.md).
