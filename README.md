# Ferazel's Wand - QEMU PowerPC Emulator

Run the original 1999 Ambrosia Software Mac OS 9 classic on any Apple Silicon Mac.
Fully self-contained after one-time setup - no Homebrew or external dependencies at runtime.
Audio, saving, and gameplay all work.

---

## Play

After setup: **double-click `Play.command`**.

All game saves live inside `disks/macos9.img`. They survive reboots and travel with the folder.
Copy the whole repo to any ARM64 Mac and it works without reinstalling anything.

---

## One-Time Setup

### Prerequisites

- Apple Silicon Mac (M1 / M2 / M3 / M4)
- macOS 13 Ventura or later
- Xcode Command Line Tools: `xcode-select --install`
- [Homebrew](https://brew.sh) - used once during setup, not required after
- ~8 GB free disk space (plus ~800 MB temporary during build)

### Files needed in `disks/`

Place these before running setup:

| File | Where to get it |
|---|---|
| `disks/macos9.iso` | Mac OS 9.2.2 Universal (Macintosh Garden / Internet Archive) |
| `disks/Ferazel's Wand 1.0.2.ISO` | [Macintosh Garden - Ferazel's Wand](https://macintoshgarden.org/games/ferazels-wand) |
| `disks/Ferazel's Wand 1.0.3 update.sit` | Same page |
| `disks/Ferazels_Wand_103_nogamma.sit` | Same page - **required, removes a QEMU crash on dagger use** |

### Setup

Double-click **`Setup.command`** to run the full pipeline, or run each step manually:

```bash
make setup          # 1. install build tools via Homebrew (one-time)
make vendor         # 2. build QEMU with Screamer audio (~10 min) + bundle into vendor/
make create-disk    # 3. create blank 6 GB Mac OS 9 disk image
make install-os     # 4. INTERACTIVE (~10 min): install Mac OS 9
make install-game   # 5. INTERACTIVE (~3 min):  run game CD installer
make apply-patches  # 6. AUTOMATED: apply v1.0.3 + no-gamma patches
make launch         # 7. play  (or double-click Play.command)
```

Steps 4 and 5 open a QEMU window and print step-by-step instructions in the terminal.
Step 6 is fully automated - mounts the disk on macOS and applies patches without opening QEMU.

`make vendor` builds QEMU from source using the
[mcayland/qemu screamer branch](https://github.com/mcayland/qemu/tree/screamer),
compiles only the PowerPC target (~10 min), bundles the binary with all dylib dependencies
and screamer-specific firmware, then deletes the ~800 MB build directory automatically.

See **[docs/setup-guide.md](docs/setup-guide.md)** for the full walkthrough.

---

## How It Works

| Component | Detail |
|---|---|
| **Emulator** | QEMU 7.1.94 `qemu-system-ppc`, machine type `mac99,via=pmu` (Power Mac G4) |
| **Audio** | Screamer (AWACS codec) - mcayland/qemu screamer fork + screamer-specific OpenBIOS |
| **OS** | Mac OS 9.2.2 Universal |
| **Game** | Ferazel's Wand v1.0.3, no-gamma patched executable |
| **Display** | Cocoa fullscreen, zoom-to-fit patched into the build, black pillarbox bars |
| **Portability** | QEMU + unar + 24 dylibs + firmware vendored into `vendor/qemu/` |
| **Saves** | Written to `disks/macos9.img` - persist and travel with the folder |

### Emulation stack

```
Play.command (bash)
  └── vendor/qemu/bin/qemu-system-ppc   (mcayland screamer build, QEMU 7.1.94)
        └── -M mac99,via=pmu            (Power Mac G4 + PMU for Screamer DMA IRQs)
              └── Mac OS 9.2.2          (disks/macos9.img)
                    └── Ferazel's Wand nogamma
```

### Audio

Audio is provided by the **Screamer** chip (Apple AWACS codec, Power Mac G4 hardware).
Screamer is absent from all upstream QEMU releases - it was removed during an audio refactor
and never re-merged. This project builds from [mcayland/qemu screamer branch](https://github.com/mcayland/qemu/tree/screamer),
which adds it back.

Two things are required beyond just the Screamer binary:
- **Screamer-specific OpenBIOS** - the fork ships a custom `pc-bios/openbios-ppc` that adds
  Screamer DBDMA channel entries to the OpenFirmware device tree. Without it, Mac OS 9 detects
  the device but DMA never fires (complete silence). The build script copies this firmware
  from the screamer source tree, not from Homebrew.
- **`-M mac99,via=pmu`** - the PMU routes Screamer DMA completion interrupts. Without it,
  Mac OS 9 queues audio DMA but the callback never arrives, producing silence.

See **[docs/audio-architecture.md](docs/audio-architecture.md)** for the full technical breakdown.

### Why the game install is interactive

The game CD uses **Installer VISE** - all game files are packed in a proprietary archive
format embedded in the installer's data fork. No macOS tool can extract Installer VISE.
The install must happen inside Mac OS 9.

### Why patch application is automated

After installation, `disks/macos9.img` is an HFS+ volume macOS can mount directly with
`hdiutil attach`. `unar` extracts `.sit` patch archives with resource fork metadata in
AppleDouble format; `ditto` merges that into proper HFS+ resource forks on the mounted
volume - no QEMU needed.

### Resource forks

Classic Mac OS game data lives in resource forks, not data forks. The data fork of most
game files is 0 bytes. Always use `ditto` (not `cp`) when copying game files on macOS -
`cp` silently drops the resource fork.

---

## QEMU Bring-Up Quirks

All documented in `config/qemu.conf.sh`:

1. **Raw disk format required** - QCOW2 fails mac99 ATA enumeration during OS install
2. **Explicit IDE bus assignment** - QEMU auto-creates phantom IDE-CD devices without it, breaking Drive Setup
3. **`via=pmu` required for gameplay, not for installation** - PMU routes Screamer DMA completion IRQs; without it audio is silent. Omitted during `install-os` only (Homebrew QEMU 11 + via=pmu causes installer failures)
4. **256 MB RAM** - 512 MB causes installer instability; >896 MB breaks audio
5. **Screamer requires a custom QEMU build** - absent from all upstream QEMU releases; built from mcayland/qemu screamer branch
6. **`cache=unsafe` on CD during install** - prevents read stalls on large sequential CD blocks ("Big Morsels" error)
7. **bash 3.2 compatibility** - macOS ships bash 3.2 (GPLv2); no `declare -A` or bash 4+ features
8. **Game folder has a Unicode ƒ character** - `Ferazel's Wand 1.0.2 ƒ` (U+0192); use globs in scripts
9. **Game CD is plain HFS** - macOS Catalina+ dropped plain HFS support; access via QEMU's IDE-CD only
10. **`zoom-to-fit` is not a CLI flag in QEMU 7.x** - patched directly into `ui/cocoa.m` during `make vendor`

---

## What NOT to Do

- **Don't close QEMU with the red window button during setup** - hard-kills without flushing disk, corrupts the image. Always use Special → Shut Down inside Mac OS 9.
- **Don't increase RAM beyond 256 MB** - causes installer instability; >896 MB breaks audio
- **Don't use QCOW2** for the disk image
- **Don't use `cp` for game files** - use `ditto` to preserve resource forks
- **Don't turn off Virtual Memory in Mac OS 9** - breaks audio (Apple menu → Control Panels → Memory)

---

## Repo Structure

```
ferazels-wand-emulator/
├── Play.command              ← double-click to play
├── Setup.command             ← double-click to run full one-time setup
├── Makefile                  ← all commands; run 'make' for help
├── config/
│   └── qemu.conf.sh          ← shared QEMU flags + 10 documented bring-up quirks
├── scripts/
│   ├── bootstrap.sh          ← runs all 6 setup steps in sequence
│   ├── setup.sh              ← brew install: qemu, unar, meson, ninja, pkg-config
│   ├── build-qemu-screamer.sh ← build + vendor QEMU with Screamer audio from source
│   ├── create-disk.sh        ← create blank 6 GB raw disk image
│   ├── install-os.sh         ← interactive: Mac OS 9 install session (Homebrew QEMU 11)
│   ├── install-game.sh       ← interactive: game CD installer session
│   ├── apply-patches.sh      ← automated: mount disk + apply patches from macOS
│   └── launch.sh             ← normal gameplay launch (vendored screamer QEMU)
├── vendor/qemu/              ← self-contained QEMU build (gitignored, built by make vendor)
├── disks/                    ← disk images and ISOs (gitignored, user-provided)
└── docs/
    ├── setup-guide.md        ← full step-by-step walkthrough
    ├── audio-architecture.md ← Screamer audio pipeline, root causes, diagnostics
    └── legal-notes.md        ← copyright and license information
```

---

## About the Game

**Ferazel's Wand** was released December 23, 1999 by Ambrosia Software, developed by
Ben Spees. Widely regarded as one of the finest side-scrolling platformers on
the classic Macintosh.

### Story

The Habnabits are a race of tunnel-dwelling creatures skilled in magic, long living in
peace underground. That peace is shattered when a horde of goblins - led by the insectoid
Dread Queen Xichra and her Manditraki army - overruns their tunnels. You play as Ferazel,
the last of the free Habnabits, fighting through 23 levels across the Seven Lands of
Teraknorn to recover a stolen wand and defeat Xichra.

### Gameplay

A side-scrolling platformer with RPG-lite elements. Ferazel can cling to walls and ceilings,
opening up vertical traversal beyond the typical run-and-jump formula. Power comes from
collecting magical crystals. A growing arsenal of spells - fireball, V-Blade, Tree Trunk,
and more - unlocks through the game. Boss fights emphasize deduction over memorization.

The 23 levels span caves, ice fields, desert, and fire biomes with multiple exits per level,
end-of-level completion tracking, and 30 original musical tracks by Eric Speier.

**A gamepad is recommended.** The game has full InputSprocket support.

### Technical highlights (1999)

- Multi-layered parallax scrolling
- Particle system: torch sparks, rain, weapon impacts, ceiling debris
- Realistic physics: floating logs bob, splash volume scales with drop height
- Pseudo-3D effects: swinging mace balls grow as they approach
- Weather: thunderstorms with rain, wind, and lightning

### Reception

Reviewed in *Macworld* (April 2000): "Ambrosia's largest and most ambitious title to date."
Rated 4.75/5 on Macintosh Garden.

> *"Those that take the time to play through it will notice impressive particle and lighting
> effects... Lighting examples include explosions and flickering torches that make you think,
> 'Wow, the Mario brothers never did this.'"*
> - Andy Largent, Macworld, April 2000

---

## Credits

See **[CREDITS.md](CREDITS.md)** for full attribution.

---

## Legal

- **Ferazel's Wand**: Copyright Ambrosia Software. Available on Macintosh Garden (abandonware).
- **Mac OS 9**: Apple proprietary software. Requires a valid license.
- **QEMU**: GNU General Public License v2.

See [docs/legal-notes.md](docs/legal-notes.md).
