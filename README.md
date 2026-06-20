# Ferazel's Wand — QEMU-PPC Emulator

Run the original 1999 Ambrosia Software Mac OS 9 game on Apple Silicon Macs.
Self-contained — no Homebrew or external dependencies after one-time setup.

---

## Play

After setup: **double-click `Play.command`**.

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
make launch         # 7. play — or double-click Play.command
```

Steps 4 and 5 require brief interaction inside the emulated Mac OS 9 GUI.
Each prints step-by-step instructions in the terminal before opening the QEMU window.
Step 6 is fully automated — mounts the disk on macOS and applies patches without QEMU.

Alternatively, double-click **`Setup.command`** to run the full pipeline in a Terminal window.

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

### Emulation stack

```
Play.command (bash)
  └── vendor/qemu/bin/qemu-system-ppc
        └── -M mac99 (Power Mac G4)
              └── Mac OS 9.2.2 on disks/macos9.img
                    └── Ferazel's Wand nogamma (game executable)
```

### Why the game install is interactive

The game CD uses **Installer VISE** — all game files are packed in a proprietary format
inside the installer application's data fork. There is no macOS extractor for Installer
VISE. The install must happen inside Mac OS 9.

### Why patch application is automated

After installation, `disks/macos9.img` is an HFS+ volume macOS can mount directly with
`hdiutil attach`. `unar` extracts the `.sit` patch archives with resource fork metadata
in AppleDouble format; `ditto` merges that back into proper HFS+ resource forks on the
mounted volume — no QEMU needed.

### Resource forks

Classic Mac OS game data lives in resource forks, not data forks. The data fork of most
game files is 0 bytes. Always use `ditto` (not `cp`) when copying game files on macOS —
`cp` silently drops the resource fork.

### Disk image notes

- Volume name visible to macOS: `untitled` (Drive Setup default in Mac OS 9)
- Game installed at: `{volume}/Ferazel's Wand 1.0.2 ƒ/` (ƒ = U+0192)
- Game executable: `Ferazel's Wand nogamma` (post-patch)

---

## QEMU Bring-Up Quirks

Nine non-obvious issues discovered during bring-up, all handled in `config/qemu.conf.sh`:

1. **Raw disk format required** — QCOW2 fails mac99 ATA enumeration during OS install
2. **Explicit IDE bus assignment** — QEMU 11 creates phantom IDE-CD devices without it
3. **No `via=pmu`** — causes "couldn't read big system resources" installer failures
4. **256 MB RAM only** — 512 MB causes installer instability
5. **No `-device screamer`** — Screamer audio is auto-connected in QEMU 11; adding it explicitly causes a fatal error
6. **`cache=unsafe` on CD during install** — prevents read stalls on large sequential CD reads
7. **bash 3.2 compatibility** — macOS ships bash 3.2; no `declare -A` or other bash 4+ features
8. **Game folder has a ƒ character** — folder name is `Ferazel's Wand 1.0.2 ƒ` (U+0192); use globs not hardcoded paths
9. **Game CD is plain HFS** — macOS Catalina+ dropped plain HFS support; the CD must be accessed via QEMU's IDE-CD driver

---

## What NOT to Do

- **Don't close QEMU with the red window button during setup** — hard-kills without flushing the disk, corrupts the image. Always use Special → Shut Down inside Mac OS 9.
- **Don't increase RAM beyond 256 MB** — causes installer instability
- **Don't add `via=pmu`** to the machine flags
- **Don't use QCOW2** format for the disk image
- **Don't use `cp` for game files** — use `ditto` to preserve resource forks

---

## Repo Structure

```
ferazels-wand-emulator/
├── Play.command              ← double-click to play
├── Setup.command             ← double-click to run full setup
├── Makefile                  ← all commands, run 'make' for help
├── config/
│   └── qemu.conf.sh          ← QEMU flags + 9 documented bring-up quirks
├── scripts/
│   ├── bootstrap.sh          ← runs all setup steps in sequence
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

## About the Game

**Ferazel's Wand** (1999) is a side-scrolling platformer by Ambrosia Software / Ben Spees.
Play as Ferazel, last of the Habnabits, fighting through 23 levels to recover a stolen wand.
Crystal-based progression, hidden passages, puzzle-based boss encounters. Rated 4.75/5 on
Macintosh Garden. Reviewed in *Macworld* (August 2000).

---

## Legal

- **Ferazel's Wand**: Copyright Ambrosia Software. Available on Macintosh Garden (abandonware).
- **Mac OS 9**: Apple proprietary. Requires a valid license.
- **QEMU**: GPL v2.

See [docs/legal-notes.md](docs/legal-notes.md).
