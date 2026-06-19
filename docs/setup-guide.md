# Setup Guide

This guide walks through getting Ferazel's Wand running from scratch on an Apple Silicon Mac.

## Prerequisites

- Apple Silicon Mac (M1 / M2 / M3 / M4 or newer)
- macOS 13 Ventura or later
- [Homebrew](https://brew.sh) (needed once, for the initial QEMU build — not required after vendoring)
- A Mac OS 9 installation ISO (see [Obtaining Mac OS 9](#obtaining-mac-os-9) below)
- The Ferazel's Wand game files (see [Obtaining the Game](#obtaining-the-game) below)
- ~8 GB free disk space

---

## Step 1 — Install and vendor QEMU

```bash
make setup    # installs QEMU via Homebrew
make vendor   # copies QEMU + all dylibs into vendor/ — no Homebrew needed after this
```

After `make vendor`, the `vendor/qemu/` directory is fully self-contained. You can copy
the entire repo to any ARM64 Mac and run it without installing anything.

---

## Step 2 — Create the Mac OS 9 disk image

```bash
make create-disk
```

This creates `disks/macos9.qcow2` — a 6 GB QCOW2 disk image that will hold Mac OS 9
and all game files. The QCOW2 format is sparse (it only uses real space for written data)
and contains all saves automatically.

---

## Step 3 — Obtain Mac OS 9

> **Legal note:** Mac OS 9 is Apple proprietary software. You must own a license
> (e.g. an original retail copy or a Mac that shipped with it). See `docs/legal-notes.md`.

Place your Mac OS 9 installation ISO at:

```
disks/macos9.iso
```

Mac OS 9.0, 9.1, 9.2, and 9.2.2 all work. 9.2.2 is recommended for best
application compatibility.

---

## Step 4 — Install Mac OS 9

```bash
make install-os
```

A QEMU window will open booting from the Mac OS 9 installer CD. Follow the on-screen
instructions:

1. The installer will ask you to initialise a disk — choose the blank `Mac OS 9` disk.
2. Complete the installation.
3. **Important:** when done, choose **Special → Shut Down**, not Restart.
   The emulator exits on shutdown.

---

## Step 5 — Install Ferazel's Wand

Download the game from [Macintosh Garden](https://macintoshgarden.org/games/ferazels-wand).
The recommended version is **v1.0.3 (no-gamma patch)** — it runs stably under QEMU.

To copy the game into the disk image:

1. Run `make launch` to boot into Mac OS 9.
2. Under the **Apple** menu, open **Networking** or use a shared folder approach,
   **or** use the steps below to mount an HFS transfer disk.

### Transferring files via a transfer disk image

```bash
# Create a small FAT32/HFS transfer image on the host
/opt/homebrew/bin/qemu-img create -f raw disks/transfer.img 512M
# Format and populate it (use Disk Utility or hdiutil on the host)
hdiutil create -size 512m -fs HFS+ -volname Transfer -o disks/transfer disks/transfer.img
# Then copy game files into it via Finder, then launch with the extra disk attached
```

Add this flag to `scripts/launch.sh` temporarily:
```
-drive "file=${DISKS_DIR}/transfer.img,format=raw,media=disk,index=1"
```

---

## Step 6 — Launch the game

```bash
make launch
```

Mac OS 9 boots from `disks/macos9.qcow2`. All saves are written to this same image,
so they're portable with the repo.

---

## Portability

After `make vendor`, the entire repo is self-contained:

```
ferazels-wand-emulator/
├── vendor/qemu/        ← QEMU binary + dylibs + firmware (ARM64)
├── disks/macos9.qcow2  ← Mac OS 9 + game + saves
├── scripts/
└── config/
```

Copy the folder to any ARM64 Mac and `make launch` works with no installation required.

---

## Obtaining Mac OS 9

Mac OS 9 ISOs are widely available for preservation purposes. A few pointers:

- [Macintosh Garden](https://macintoshgarden.org) hosts community-preserved Mac OS releases.
- The Internet Archive has archived Apple system software.
- If you own original retail media, you can rip it with Disk Utility.

Recommended: **Mac OS 9.2.2** (latest release, best compatibility).

---

## Obtaining the Game

All versions are available at [Macintosh Garden — Ferazel's Wand](https://macintoshgarden.org/games/ferazels-wand).

| Version | Recommendation |
|---|---|
| v1.0.3 (no-gamma patch) | **Use this** — stable under QEMU |
| v1.0.2 + 1.0.3 update | Works but requires patching |
| Prototype v1.0d6 / d7 | Historical interest only |

---

## Troubleshooting

**QEMU window is black / doesn't boot**
- Mac OS 9 takes 30–60 seconds to reach the grey screen on first boot.
- If it stays black, OpenBIOS may not be finding the disk. Verify `disks/macos9.qcow2` exists.

**Audio doesn't work**
- macOS may prompt for microphone/audio access the first time. Allow it in System Settings.

**Crashes when using the dagger in Ferazel's Wand**
- Make sure you are using the **no-gamma patched** executable (v1.0.3 no-gamma).
  The standard binary has a gamma fade effect that crashes QEMU.

**`make vendor` fails with codesign errors**
- This can happen if Gatekeeper blocks ad-hoc signing. Run:
  ```bash
  sudo spctl --master-disable   # temporarily disable Gatekeeper
  make vendor
  sudo spctl --master-enable
  ```
