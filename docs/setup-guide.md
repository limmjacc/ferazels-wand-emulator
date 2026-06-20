# Setup Guide

Full walkthrough for getting Ferazel's Wand running from scratch on an Apple Silicon Mac.
Validated on MacBook Air M2, QEMU 11.0.1, Mac OS 9.2.2.

---

## Overview

| Step | Command | Type | Time |
|---|---|---|---|
| Install tools | `make setup` | Automated | ~2 min |
| Bundle QEMU | `make vendor` | Automated | ~1 min |
| Create disk | `make create-disk` | Automated | instant |
| Install Mac OS 9 | `make install-os` | Interactive QEMU | ~10 min |
| Install game | `make install-game` | Interactive QEMU | ~3 min |
| Apply patches | `make apply-patches` | Automated | ~30 sec |
| **Play** | `make launch` / double-click | **Forever** | instant |

---

## Prerequisites

- Apple Silicon Mac (M1 / M2 / M3 / M4)
- macOS 13 Ventura or later
- [Homebrew](https://brew.sh) - needed once for `make setup`; not required after `make vendor`
- ~8 GB free disk space

---

## Files Needed in `disks/`

Place these four files in the `disks/` folder before starting:

```
disks/
├── macos9.iso                          ← Mac OS 9.2.2 Universal installer
├── Ferazel's Wand 1.0.2.ISO            ← game CD image
├── Ferazel's Wand 1.0.3 update.sit     ← v1.0.3 patch
└── Ferazels_Wand_103_nogamma.sit       ← no-gamma patched executable
```

All game files are at [Macintosh Garden - Ferazel's Wand](https://macintoshgarden.org/games/ferazels-wand).

> **The no-gamma patch is required.** The standard v1.0.3 executable has a gamma screen-fade
> that crashes QEMU when using the dagger weapon. The no-gamma patch removes it.

---

## Step 1 - Install Tools

```bash
make setup
```

Installs QEMU 11 and unar (The Unarchiver CLI) via Homebrew. After `make vendor` completes,
Homebrew is no longer required.

---

## Step 2 - Bundle QEMU

```bash
make vendor
```

Copies the QEMU binary, unar binary, all dylib dependencies, and QEMU firmware into
`vendor/qemu/`. After this, the repo is fully self-contained - copy it to any ARM64 Mac
and everything works without Homebrew.

---

## Step 3 - Create Disk Image

```bash
make create-disk
```

Creates `disks/macos9.img` - a 6 GB blank raw disk image. Raw format is required;
QCOW2 causes Mac OS 9's ATA driver to fail device enumeration (see `config/qemu.conf.sh`).

---

## Step 4 - Install Mac OS 9 (Interactive, ~10 min)

```bash
make install-os
```

Opens a QEMU window booting from the Mac OS 9 installer ISO.
The terminal prints step-by-step instructions. Summary:

### 4a - Wait for boot

OpenBIOS takes ~30 seconds. Wait for the full Mac OS 9 desktop before clicking anything.

### 4b - Initialize the disk with Drive Setup

The installer opens automatically and says **"no volumes available"**. This is expected -
the blank disk has no Apple Partition Map. Close the installer and do this first:

1. Double-click the **installer CD** icon on the desktop
2. Open the **Utilities** folder
3. Launch **Drive Setup**
4. Select the blank disk → click **Initialize** → accept HFS+ format
5. Quit Drive Setup

### 4c - Run the installer

1. Open the Mac OS 9 Installer
2. The formatted volume now appears as a target
3. Select it → click **Install** (~5–10 minutes)

### 4d - Shut down cleanly

**Special → Shut Down** from the menu bar.

> ⚠️ Never click the red QEMU window button. That kills QEMU without flushing the
> disk and can corrupt the image. Always use Mac OS 9's own Shut Down.

---

## Step 5 - Install the Game (Interactive, ~3 min)

```bash
make install-game
```

Opens QEMU with the Ferazel's Wand game CD attached. The terminal prints instructions.
Summary - **only 4 clicks required**:

1. Double-click the **Ferazel's Wand** CD icon on the desktop
2. Double-click **Ferazel's Wand Installer**
3. Click **Easy Install** - installs the full game to Macintosh HD (~60 seconds)
4. Click **Quit** when done
5. **Special → Shut Down**

> The game uses Installer VISE (proprietary archive format embedded in the installer's
> data fork). This is why the install must happen inside Mac OS 9 - there is no macOS
> tool that can extract Installer VISE archives.

---

## Step 6 - Apply Patches (Automated)

```bash
make apply-patches
```

Fully automated - no QEMU, no Mac OS 9. This script:

1. Mounts `disks/macos9.img` directly on macOS (it's HFS+, macOS can read/write it)
2. Uses vendored `unar` to extract `Ferazel's Wand 1.0.3 update.sit`
3. Uses vendored `unar` to extract `Ferazels_Wand_103_nogamma.sit`
4. Uses `ditto` to copy extracted files into the game folder, preserving Mac resource forks
5. Unmounts cleanly

Why `ditto` instead of `cp`: Classic Mac game data lives in resource forks. `unar` extracts
with resource fork metadata in AppleDouble format; `ditto` merges that back into native
HFS+ resource forks when writing to the mounted volume.

---

## Step 7 - Play

```bash
make launch
# or double-click FerazelsWand.app
```

Mac OS 9 boots in ~60 seconds. Navigate to the `Ferazel's Wand` folder on the hard disk
and double-click **`Ferazel's Wand nogamma`** to launch the game.

All saves are written to `disks/macos9.img`. They persist between launches and travel
with the repo folder.

---

## Portability

After `make vendor`, the repo is fully self-contained:

```
ferazels-wand-emulator/
├── FerazelsWand.app      ← double-click to play
├── vendor/qemu/          ← QEMU + unar + dylibs + firmware (ARM64, ~320 MB)
└── disks/macos9.img      ← Mac OS 9 + game + saves (~6 GB)
```

Copy the folder to any ARM64 Mac. No Homebrew, no QEMU, no dependencies.

---

## Obtaining Mac OS 9

- [Macintosh Garden](https://macintoshgarden.org) - community preservation archive
- [Internet Archive](https://archive.org) - search "Mac OS 9.2.2 Universal"

**Tested version:** Mac OS 9.2.2 Universal (`macos-922-uni.iso`, 579 MB)

> Apple proprietary software. You must own a valid license. See `docs/legal-notes.md`.

---

## Troubleshooting

**QEMU window is black for more than 90 seconds**
OpenBIOS normally takes 30–60 s. If longer, verify `disks/macos9.img` exists and is > 1 MB.

**"No volumes available" in the Mac OS 9 installer**
Expected on a blank disk. Run Drive Setup from the CD's Utilities folder first to
initialize the disk with an Apple Partition Map. See Step 4b above.

**"Couldn't read big system resources" during install**
Caused by `via=pmu` or more than 256 MB RAM. Both are disabled in the current config.
Verify `config/qemu.conf.sh` has `-M mac99` (not `mac99,via=pmu`) and `-m 256`.

**Game not found in `make apply-patches`**
`apply-patches` looks for a folder named `Ferazel*` at the root of the Mac OS 9 volume.
Run `make install-game` first (the interactive game CD installer session).

**Audio prompts on first launch**
macOS may ask for microphone access. Allow it in System Settings → Privacy & Security.

**Game crashes when using the dagger**
You are using the standard v1.0.3 binary. `make apply-patches` applies the no-gamma
patch automatically. Verify `Ferazel's Wand nogamma` exists in the game folder by
mounting `disks/macos9.img` in Finder and checking the game folder.

**`make vendor` fails: "declare: -A: invalid option"**
macOS ships bash 3.2 (GPLv2). `declare -A` is bash 4+. This was fixed - update to the
latest version of this repo.

**QEMU window closes immediately after boot**
The `-no-reboot` flag in launch.sh means QEMU exits if Mac OS 9 crashes on boot.
This can happen if the disk image was corrupted by a hard kill (red window button).
Run `make reset-disk` and redo the setup - unfortunately the image must be rebuilt.
