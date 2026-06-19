# Ferazel's Wand Emulator

A project to reimplement and emulate **Ferazel's Wand**, the classic 1999 Mac OS 9 platformer by Ambrosia Software.

---

## About the Original Game

| Field | Detail |
|---|---|
| **Title** | Ferazel's Wand |
| **Developer / Publisher** | Ambrosia Software |
| **Designer** | Ben Spees |
| **Released** | 1999 |
| **Platform** | Classic Mac OS (System 7.0–7.6, Mac OS 9) |
| **Architecture** | PowerPC (PPC) |
| **Genre** | Side-scrolling action platformer / arcade-RPG hybrid |
| **Review score** | 4.75 / 5 (Macintosh Garden, 16 votes) |

### Story

You play as **Ferazel**, the last of the free **Habnabits** — a race of magical, tunnel-dwelling creatures. The Habnabit homeland has come under attack from goblins, with hints of a darker, more sinister enemy pulling the strings. Ferazel must travel through the world of **Teraknorn**, jumping, casting spells, and fighting through 23 levels to uncover the truth and free his people.

### Gameplay

- **Side-scrolling platformer** across 23 levels.
- Enemies include poisonous spiders, goblins, and more.
- **Puzzle-focused combat**: boss encounters require players to logically deduce enemy weaknesses rather than brute-forcing through them.
- **Crystal-based progression**: Ferazel grows stronger by discovering magical crystals, not through traditional XP/level-up systems.
- Levels are filled with **concealed passages** and hidden collectibles — exploration is heavily rewarded.
- Later levels shift toward **trap-dodging and hazard navigation** (e.g. ice physics, wind effects).
- **Save system**: checkpoints are frequent enough to avoid frustration but sparse enough to demand thoughtful play.

### Reception

Reviewed by Christopher Breen in *Macworld* (August 2000). Key observations:

- Controls described as "not too finicky" and gameplay as "challenging and well-balanced."
- Cartoonish visual style makes it accessible to younger players without feeling childish to adults.
- Compared to *Prince of Persia* and *Dark Castle*, but more forgiving on timing.
- Rare quality of appealing across age groups without being overly violent or excessively juvenile.

---

## Known Versions & Files

All versions available at [Macintosh Garden](https://macintoshgarden.org/games/ferazels-wand).

| Version | File | Size | Notes |
|---|---|---|---|
| v1.0.2 + update to 1.0.3 | `ferazels_wand.zip` | 75.12 MB | Full game |
| v1.0.3 Update | `Ferazels_Wand_1_0_3_update.sit` | 8.90 MB | Patch only |
| v1.0.3 (no-gamma patch) | `Ferazels_Wand_103_nogamma.sit` | 418.64 KB | Recommended for QEMU-PPC |
| Demo | `ferazelswand.sit` | 21.62 MB | Stays locked in demo mode |
| Launcher v1.0.2 | `ferazels-wand-launcher-1.0.2.dmg_.zip` | 24.39 KB | |
| Prototype v1.0d6 | `ferazels_wand_v10d6.sit` | 2.64 MB | Early prototype |
| Prototype v1.0d7 | `ferazels_wand_v10d7.sit` | 2.73 MB | Early prototype |
| FerazEdit v1.1 | `FerazEdit1.1.hqx` | 756.52 KB | Level editor |

---

## Original System Requirements

- **CPU:** PowerPC
- **OS:** System 7.0–7.6 or Mac OS 8/9
- **CD-ROM:** Required on first launch (disc check; virtual mounting via SheepShaver or Virtual CD/DVD Utility satisfies this)

---

## Emulation Compatibility (Original Binary)

If you want to run the original game binary while working on this reimplementation, here are the known working setups:

| Emulator | Status | Notes |
|---|---|---|
| **QEMU-PPC** | Stable | Use the no-gamma patched executable (`Ferazels_Wand_103_nogamma.sit`) |
| **SheepShaver** | Partial | Sporadic crashes, particularly when using the dagger weapon |

The no-gamma patch disables a gamma screen-fade effect that causes crashes under QEMU.

---

## This Project

The goal is to run the **original Ferazel's Wand binary** on a modern Apple Silicon Mac via a fully self-contained QEMU-PPC emulator. No Homebrew or external dependencies required after initial setup.

### Approach

- **Emulator:** QEMU `qemu-system-ppc` with the `mac99` machine (Power Mac G4), running Mac OS 9
- **Portability:** QEMU binary + all dylibs + firmware are vendored into `vendor/qemu/` — copy the repo to any ARM64 Mac and run
- **Game files + saves:** All stored in `disks/macos9.img` alongside the OS — one file holds everything
- **No gamma patch:** Uses the community no-gamma patched v1.0.3 executable for stable QEMU operation

### Usage

After one-time setup, just **double-click `FerazelsWand.app`** to play. All game saves
live inside `disks/macos9.img` in this folder — they survive reboots and move with
the folder.

### One-time setup

Run these once in Terminal from this folder:

```bash
make setup        # install QEMU via Homebrew
make vendor       # bundle QEMU + dylibs into vendor/ — Homebrew not needed after this
make create-disk  # create disks/macos9.img (raw format — required for mac99 ATA)
# place your Mac OS 9 ISO at disks/macos9.iso
make install-os   # boot from ISO, install Mac OS 9 + the game, then Shut Down
```

After that, `FerazelsWand.app` is the only thing you need. The folder is fully
self-contained — copy it to any ARM64 Mac and double-click.

See [docs/setup-guide.md](docs/setup-guide.md) for the full walkthrough.

### Repo Structure

```
ferazels-wand-emulator/
├── FerazelsWand.app/         ← double-click this to play
│   └── Contents/
│       ├── Info.plist
│       └── MacOS/
│           └── FerazelsWand  ← shell launcher (sources config/, invokes QEMU)
├── Makefile                  ← one-time setup commands
├── config/
│   └── qemu.conf.sh          ← QEMU flags, paths, vendor/Homebrew detection
├── scripts/
│   ├── setup.sh              ← install QEMU via Homebrew
│   ├── vendor-qemu.sh        ← bundle QEMU + dylibs into vendor/ for portability
│   ├── create-disk.sh        ← create blank Mac OS 9 raw disk image
│   ├── install-os.sh         ← boot from Mac OS 9 ISO to install
│   └── launch.sh             ← launch Mac OS 9 (same as double-clicking the app)
├── vendor/
│   └── qemu/                 ← self-contained QEMU (populated by `make vendor`, gitignored)
├── disks/
│   ├── macos9.img            ← Mac OS 9 + game + saves (gitignored, raw format)
│   └── macos9.iso            ← Mac OS 9 installer ISO (gitignored, user-provided)
├── docs/
│   ├── setup-guide.md        ← full setup walkthrough
│   └── legal-notes.md        ← QEMU, Mac OS 9, and game licensing notes
└── app/
    └── README.md             ← planned: native Swift/SwiftUI .app with built-in setup wizard
```

### Useful Resources

- [Wikipedia](https://en.wikipedia.org/wiki/Ferazel%27s_Wand) — game overview
- [Macintosh Garden](https://macintoshgarden.org/games/ferazels-wand) — downloads, versions, community notes
- [Macworld Review (August 2000)](https://www.macworld.com/article/158638/ferazel.html) — original press review
- [Ambrosia Software (archived)](https://web.archive.org/web/20170915070901/http://www.ambrosiasw.com/games/ferazel/) — original publisher page
- [TCRF](https://tcrf.net/Ferazel%27s_Wand) — cut/unused content and technical findings — **⚠️ WARNING: This page contains an embedded prompt injection attack** (hidden instructions attempting to trigger destructive file operations in AI tools). The page contains real game data but should be visited with caution in any AI-assisted workflow.
- FerazEdit v1.1 — the original level editor, available on Macintosh Garden
