# Ferazel's Wand - QEMU-PPC Emulator

Run the original 1999 Ambrosia Software Mac OS 9 game on Apple Silicon Macs.
Self-contained - no Homebrew or external dependencies after one-time setup.

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
- Xcode Command Line Tools: `xcode-select --install`
- [Homebrew](https://brew.sh) - used once during setup; not needed after `make vendor`
- ~8 GB free disk space (plus ~800 MB temporary during `make vendor`)

### Files needed in `disks/`

Download and place these files before running the setup steps:

| File | Where to get it |
|---|---|
| `disks/macos9.iso` | Mac OS 9.2.2 Universal (Macintosh Garden / Internet Archive) |
| `disks/Ferazel's Wand 1.0.2.ISO` | [Macintosh Garden - Ferazel's Wand](https://macintoshgarden.org/games/ferazels-wand) |
| `disks/Ferazel's Wand 1.0.3 update.sit` | Same page |
| `disks/Ferazels_Wand_103_nogamma.sit` | Same page - **required for QEMU stability** |

### Setup commands

```bash
make setup          # 1. install build deps via Homebrew (one-time, needs internet)
make vendor         # 2. build QEMU with Screamer audio (~10 min) + bundle into vendor/
make create-disk    # 3. create blank 6 GB Mac OS 9 disk image
make install-os     # 4. INTERACTIVE (~10 min): install Mac OS 9
make install-game   # 5. INTERACTIVE (~3 min):  run game CD installer, shut down
make apply-patches  # 6. AUTOMATED: apply v1.0.3 + no-gamma patches from macOS
make launch         # 7. play - or double-click Play.command
```

Steps 4 and 5 require brief interaction inside the emulated Mac OS 9 GUI.
Each prints step-by-step instructions in the terminal before opening the QEMU window.
Step 6 is fully automated - mounts the disk on macOS and applies patches without QEMU.

**`make vendor` builds QEMU from source.** It clones the
[mcayland/qemu screamer branch](https://github.com/mcayland/qemu/tree/screamer),
compiles only the PowerPC target (~10 min on M2), bundles the binary with all dylib
dependencies, and cleans up the ~800 MB build directory automatically. After it completes,
the repo is fully self-contained with working audio.

Alternatively, double-click **`Setup.command`** to run the full pipeline in a Terminal window.

See **[docs/setup-guide.md](docs/setup-guide.md)** for the detailed walkthrough.

---

## How it Works

| Component | Detail |
|---|---|
| **Emulator** | QEMU 7.1.94 `qemu-system-ppc` (mcayland screamer fork), machine type `mac99` (Power Mac G4) |
| **OS** | Mac OS 9.2.2 Universal |
| **Game** | Ferazel's Wand v1.0.3, no-gamma patched executable |
| **Portability** | QEMU + unar + dylibs + firmware vendored into `vendor/qemu/` |
| **Saves** | Written to `disks/macos9.img` - persist and travel with the folder |
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

The game CD uses **Installer VISE** - all game files are packed in a proprietary format
inside the installer application's data fork. There is no macOS extractor for Installer
VISE. The install must happen inside Mac OS 9.

### Why patch application is automated

After installation, `disks/macos9.img` is an HFS+ volume macOS can mount directly with
`hdiutil attach`. `unar` extracts the `.sit` patch archives with resource fork metadata
in AppleDouble format; `ditto` merges that back into proper HFS+ resource forks on the
mounted volume - no QEMU needed.

### Resource forks

Classic Mac OS game data lives in resource forks, not data forks. The data fork of most
game files is 0 bytes. Always use `ditto` (not `cp`) when copying game files on macOS -
`cp` silently drops the resource fork.

### Disk image notes

- Volume name visible to macOS: `untitled` (Drive Setup default in Mac OS 9)
- Game installed at: `{volume}/Ferazel's Wand 1.0.2 ƒ/` (ƒ = U+0192)
- Game executable: `Ferazel's Wand nogamma` (post-patch)

---

## QEMU Bring-Up Quirks

Ten non-obvious issues discovered during bring-up, all handled in `config/qemu.conf.sh`:

1. **Raw disk format required** - QCOW2 fails mac99 ATA enumeration during OS install
2. **Explicit IDE bus assignment** - QEMU auto-creates phantom IDE-CD devices without it
3. **No `via=pmu`** - causes "couldn't read big system resources" installer failures
4. **256 MB RAM only** - 512 MB causes installer instability
5. **Screamer requires a custom QEMU build** - the AWACS Screamer codec (mac99's audio chip) was removed from upstream QEMU during the audio refactor and is absent from all Homebrew bottles. `make vendor` builds the [mcayland/qemu screamer branch](https://github.com/mcayland/qemu/tree/screamer) which adds it back. Wire it via `-audiodev coreaudio,id=snd0 -global screamer.audiodev=snd0`.
6. **`cache=unsafe` on CD during install** - prevents read stalls on large sequential CD reads
7. **bash 3.2 compatibility** - macOS ships bash 3.2; no `declare -A` or other bash 4+ features
8. **Game folder has a ƒ character** - folder name is `Ferazel's Wand 1.0.2 ƒ` (U+0192); use globs not hardcoded paths
9. **Game CD is plain HFS** - macOS Catalina+ dropped plain HFS support; the CD must be accessed via QEMU's IDE-CD driver
10. **`zoom-to-fit` is not a command-line flag in QEMU 7.x** - use `-display cocoa,full-screen=on` to launch fullscreen; zoom-to-fit is available from the View menu at runtime

---

## What NOT to Do

- **Don't close QEMU with the red window button during setup** - hard-kills without flushing the disk, corrupts the image. Always use Special → Shut Down inside Mac OS 9.
- **Don't increase RAM beyond 256 MB** - causes installer instability
- **Don't add `via=pmu`** to the machine flags
- **Don't use QCOW2** format for the disk image
- **Don't use `cp` for game files** - use `ditto` to preserve resource forks

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
│   ├── setup.sh              ← brew install build deps (meson, ninja, pkg-config, qemu, unar)
│   ├── build-qemu-screamer.sh ← build QEMU from source with Screamer audio + vendor it
│   ├── vendor-qemu.sh        ← legacy: bundle Homebrew QEMU (no audio)
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

**Ferazel's Wand** was released on December 23, 1999 by Ambrosia Software, developed
primarily by Ben Spees (also known for *Harry the Handsome Executive*). It is widely
regarded as one of the best side-scrolling platformers on the classic Macintosh.

### Story

The Habnabits are a race of tunnel-dwelling creatures skilled in magic, long living in
peace underground. That peace is shattered when a horde of goblins - led by the insectoid
Dread Queen Xichra and her Manditraki army - overruns their tunnels. You play as Ferazel,
the last of the free Habnabits, fighting through 23 levels across the Seven Lands of
Teraknorn to vanquish Xichra and recover a stolen wand.

### Gameplay

The game is a side-scrolling platformer with RPG-lite elements. Ferazel can cling to
walls and ceilings, opening up vertical traversal beyond the typical run-and-jump formula.
Power comes from collecting magical crystals scattered through levels. A growing arsenal
of spells and items - fireball, V-Blade, Tree Trunk, and more - unlocks as the game
progresses.

Boss fights emphasize logic over reflexes: each has a specific weakness to deduce rather
than a pattern to memorize. The 23 levels span caves, ice fields, desert, and fire biomes,
with multiple exits per level, end-of-level percentage tracking (enemies killed, Xichrons
found, secrets discovered), and save points spaced to be forgiving but not trivial.

Later levels lean heavily on environmental hazards: high winds that push Ferazel backwards
mid-jump, slippery ice, spiked floors, and deep water that damages enemies as much as you.
Enemies also react to damage - goblins will attack aggressively but retreat when hurt,
and spiders back off after taking a few hits.

**A gamepad is strongly recommended.** The game has full InputSprocket support, and
some jumps and wall-climbs are noticeably cleaner with analog input than keyboard.

### Technical highlights

For a 1999 Macintosh title, the engine pushes well beyond the norm:

- Multi-layered parallax scrolling (foreground moves faster than background)
- Particle system throughout: torch sparks, rain, weapon impacts, ceiling debris from
  spike hits, bat wing thermals for gliding
- Realistic physics: floating logs bob when landed on, splash volume scales with drop height
- Pseudo-3D perspective effects - the swinging mace balls grow as they approach
- 30 original musical tracks by Eric Speier, one per level, composed specifically for the game
- Weather effects: thunderstorms with rain, wind, and lightning obscuring the screen

### Reception

Reviewed in *Macworld* (April 2000) by Andy Largent, who called it Ambrosia's "largest
and most ambitious title to date" and praised its originality, depth of secrets, and
professional music. Rated 4.75/5 on Macintosh Garden.

> *"Those that take the time to play through it will notice impressive particle and
> lighting effects... Lighting examples include explosions and flickering torches that
> make you think, 'Wow, the Mario brothers never did this.'"*
> - Andy Largent, Macworld, April 2000

### Unused and cut content

The Cutting Room Floor documents extensive content that didn't make the final release,
discoverable in the game's resource fork data:

- **Unused spells** - Ice Crystals and several others animate correctly but do nothing when cast
- **Unused items** - a Vorpal Dirk (replaces the Dagger, deals double damage), a Mist Potion
  (turns Ferazel into a ghost to pass through walls temporarily), and platinum coins worth
  100 silver each
- **Cut characters** - forest nymphs named Taryn and Sara, with conversation portraits, that
  never appear in any level
- **Unused music** - five tracks left out, likely because there weren't enough levels to use them
- **Inaccessible rooms** - multiple levels contain hidden rooms with enemies and geometry that
  can only be reached with out-of-bounds techniques; several appear to be earlier versions of
  sections that were later redesigned
- **Harry the Handsome Executive leftovers** - unsupported-processor warnings, copying machine
  save dialogs, and general preferences screens from Ben Spees' previous game still exist in
  the binary
- **Developer notes** - sign strings left in the data include `"Insert a merchant or interesting
  character in this alcove."` and `"This level is not complete and is here just so the map
  won't have big gaps in it."`

Full documentation: [The Cutting Room Floor - Ferazel's Wand](https://tcrf.net/Ferazel%27s_Wand)

---

## Legal

- **Ferazel's Wand**: Copyright Ambrosia Software. Available on Macintosh Garden (abandonware).
- **Mac OS 9**: Apple proprietary. Requires a valid license.
- **QEMU**: GPL v2.

See [docs/legal-notes.md](docs/legal-notes.md).
