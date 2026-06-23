# Setup Guide

Full walkthrough for getting Ferazel's Wand running from scratch on an Apple Silicon Mac.
Validated on MacBook Air M2, QEMU 7.1.94 (mcayland screamer fork), Mac OS 9.2.2.

---

## Overview

| Step | Command | Type | Time |
|---|---|---|---|
| Install tools | `make setup` | Automated | ~2 min |
| Build QEMU | `make vendor` | Automated | ~10 min |
| Create disk | `make create-disk` | Automated | instant |
| Install Mac OS 9 | `make install-os` | Interactive QEMU | ~10 min |
| Install game | `make install-game` | Interactive QEMU | ~3 min |
| Apply patches | `make apply-patches` | Automated | ~30 sec |
| **Play** | `make launch` / double-click | **Forever** | instant |

Or run everything at once: **double-click `Setup.command`** (or `make bootstrap`).

---

## Prerequisites

- Apple Silicon Mac (M1 / M2 / M3 / M4)
- macOS 13 Ventura or later
- Xcode Command Line Tools: `xcode-select --install`
- [Homebrew](https://brew.sh) - needed once for `make setup`; not required after `make vendor`
- ~8 GB free disk space (plus ~800 MB temporary during build)

---

## Files Needed in `disks/`

Place these four files in the `disks/` folder before starting:

```
disks/
├── macos9.iso                          ← Mac OS 9.2.2 Universal installer
├── Ferazel's Wand 1.0.2.ISO            ← game CD image
├── Ferazel's Wand 1.0.3 update.sit     ← v1.0.3 patch
└── Ferazels_Wand_103_nogamma.sit       ← no-gamma patched executable (required)
```

All game files are at [Macintosh Garden - Ferazel's Wand](https://macintoshgarden.org/games/ferazels-wand).

> **The no-gamma patch is required.** The standard v1.0.3 executable has a gamma screen-fade
> effect that crashes QEMU when using the dagger weapon. The no-gamma patch removes it.

---

## Step 1 - Install Tools

```bash
make setup
```

Installs QEMU 11, unar, meson, ninja, and pkg-config via Homebrew. After `make vendor`
completes, Homebrew is no longer required at runtime.

---

## Step 2 - Build QEMU with Screamer Audio

```bash
make vendor
```

Builds `qemu-system-ppc` from source using the
[mcayland/qemu screamer branch](https://github.com/mcayland/qemu/tree/screamer),
which provides the Screamer (AWACS) audio chip emulation absent from all upstream QEMU
releases. The build:

1. Clones the screamer branch (shallow, ~120 MB download)
2. Patches `ui/cocoa.m` for zoom-to-fit fullscreen and black letterbox bars
3. Compiles the PowerPC-only target (~10 min on M2)
4. Bundles the binary, 24 dylib dependencies, and screamer-specific OpenBIOS firmware
5. Ad-hoc signs everything for Apple Silicon
6. Deletes the ~800 MB build directory

After this step, `vendor/qemu/` is fully self-contained - copy to any ARM64 Mac.

---

## Step 3 - Create Disk Image

```bash
make create-disk
```

Creates `disks/macos9.img` - a 6 GB blank raw disk image. Raw format is required;
QCOW2 causes Mac OS 9's ATA driver to fail device enumeration.

---

## Step 4 - Install Mac OS 9 (Interactive, ~10 min)

```bash
make install-os
```

Opens a QEMU window booting from the Mac OS 9 installer ISO using Homebrew QEMU 11.
The terminal prints step-by-step instructions. Summary:

### 4a - Wait for boot (~60 seconds)

OpenBIOS initializes, then Mac OS 9 boots from CD. Wait for the full desktop.

### 4b - Initialize the disk with Drive Setup

The installer opens automatically and says **"no volumes available"** - normal, the blank
disk has no Apple Partition Map yet. Close the installer and do this first:

1. Double-click the **installer CD** icon on the desktop
2. Open the **Utilities** folder
3. Launch **Drive Setup**
4. Select the blank disk → click **Initialize** → accept HFS+ format
5. Quit Drive Setup

### 4c - Run the installer

1. Re-open the Mac OS 9 Installer from the CD
2. Select the formatted "untitled" volume as the install destination
3. Click **Install** - takes 5–10 minutes

### 4d - Shut down cleanly

**Special → Shut Down** from the Mac OS 9 menu bar.

> Never click the red QEMU window button. That hard-kills QEMU without flushing the disk
> and will corrupt the image. Always shut down from within Mac OS 9.

---

## Step 5 - Install the Game (Interactive, ~3 min)

```bash
make install-game
```

Opens QEMU with the Ferazel's Wand game CD attached. Only 4 clicks required:

1. Double-click the **Ferazel's Wand** CD icon on the desktop
2. Double-click **Ferazel's Wand Installer**
3. Click **Easy Install** (~60 seconds)
4. Click **Quit** when done
5. **Special → Shut Down**

> The game uses Installer VISE (proprietary archive format). This is why installation
> must happen inside Mac OS 9 - no macOS tool can extract Installer VISE archives.

---

## Step 6 - Apply Patches (Automated)

```bash
make apply-patches
```

Fully automated - no QEMU, no Mac OS 9 interaction required. This script:

1. Mounts `disks/macos9.img` on macOS (`hdiutil attach`)
2. Extracts `Ferazel's Wand 1.0.3 update.sit` with `unar`
3. Extracts `Ferazels_Wand_103_nogamma.sit` with `unar`
4. Copies extracted files into the game folder with `ditto` (preserves resource forks)
5. Unmounts cleanly

Why `ditto` instead of `cp`: Classic Mac game data lives in resource forks. `unar`
extracts with resource fork metadata in AppleDouble format; `ditto` merges that into
native HFS+ resource forks on the mounted volume.

---

## Step 7 - Play

```bash
make launch
# or double-click Play.command
```

Mac OS 9 boots in ~60 seconds. The game is in the `Ferazel's Wand` folder on the hard disk.
Double-click **`Ferazel's Wand nogamma`** to launch.

All saves write to `disks/macos9.img` and persist between launches.

### Audio setup

On first boot, verify audio is working:

1. **Apple menu → Control Panels → Memory** - turn Virtual Memory **On** if it isn't already
   (required for Screamer audio to function)
2. **Apple menu → Control Panels → Sound** - Output tab should show
   "Spatializer Audio Laboratories" (confirms screamer-specific OpenBIOS is active)
3. Move the Alert volume slider - you should hear a preview tone

---

## Portability

After `make vendor`, the repo is fully self-contained:

```
ferazels-wand-emulator/
├── Play.command          ← double-click to play
├── vendor/qemu/          ← QEMU + unar + dylibs + firmware (ARM64, ~320 MB)
└── disks/macos9.img      ← Mac OS 9 + game + saves (~6 GB)
```

Copy the folder to any ARM64 Mac. No Homebrew, no QEMU install, no dependencies.

---

## Obtaining Mac OS 9

- [Macintosh Garden](https://macintoshgarden.org) - community preservation archive
- [Internet Archive](https://archive.org) - search "Mac OS 9.2.2 Universal"

**Tested version:** Mac OS 9.2.2 Universal (579 MB ISO)

> Apple proprietary software. You must own a valid license. See `docs/legal-notes.md`.

---

## Troubleshooting

**QEMU window is black for more than 90 seconds**
OpenBIOS normally takes 30–60 s. Verify `disks/macos9.img` exists and is > 1 MB,
and that `vendor/qemu/share/qemu/openbios-ppc` exists (run `make vendor` if not).

**"No volumes available" in the Mac OS 9 installer**
Expected on a blank disk. Run Drive Setup from the CD's Utilities folder first. See Step 4b.

**Installer hangs on "Updating Apple hard disk drivers"**
`install-os.sh` uses Homebrew QEMU 11 with `cache=unsafe` and `aio=threads` on the CD
drive to prevent this. If it still hangs, delete `disks/macos9.img`, run `make create-disk`,
and retry `make install-os`.

**No audio / Sound control panel shows only "Built-in"**
The screamer-specific `openbios-ppc` is not loaded. Delete `vendor/qemu/` and run
`make vendor` again to rebuild with the correct firmware overlay.

**No audio / Sound control panel shows "Spatializer Audio Laboratories" but silent**
Check that Virtual Memory is On (Apple menu → Control Panels → Memory). See
`docs/audio-architecture.md` for the full WAV capture diagnostic.

**Game not found in `make apply-patches`**
`apply-patches` looks for a folder named `Ferazel*` at the root of the Mac OS 9 volume.
Run `make install-game` first.

**Game crashes when using the dagger**
The no-gamma patch is not applied. Run `make apply-patches` and verify
`Ferazel's Wand nogamma` exists in the game folder.

**`make vendor` fails: "vendor/qemu/ already exists"**
Run `make clean` first, then `make vendor`.

**QEMU window closes immediately after boot**
The `-no-reboot` flag means QEMU exits on Mac OS 9 crash. This can happen if the disk
image was corrupted by a hard kill (red window button). Run `make reset-disk` and redo
from Step 3 - the image must be rebuilt from scratch.

**Apple Audio Extension crashes on boot**
Some QuickTime versions install an `AppleAudioExtension` that conflicts with Screamer
emulation. Boot with extensions disabled (hold Shift at startup) and remove or disable
it via Extensions Manager.
