# Setup Guide

This guide walks through getting Mac OS 9 and Ferazel's Wand running from scratch
on an Apple Silicon Mac. All steps have been validated on a MacBook Air M2 running
QEMU 11.0.1 with Mac OS 9.2.2.

---

## Prerequisites

- Apple Silicon Mac (M1 / M2 / M3 / M4 or newer)
- macOS 13 Ventura or later
- [Homebrew](https://brew.sh) — needed once for the initial QEMU install; not required after `make vendor`
- A Mac OS 9 installation ISO (see [Obtaining Mac OS 9](#obtaining-mac-os-9) below)
- The Ferazel's Wand game files (see [Obtaining the Game](#obtaining-the-game) below)
- ~8 GB free disk space

---

## Step 1 — Install and vendor QEMU

```bash
make setup    # installs QEMU 11 via Homebrew
make vendor   # bundles QEMU binary + all dylibs into vendor/ for portability
```

After `make vendor`, `vendor/qemu/` is self-contained. Copy the entire repo to any
ARM64 Mac and everything still works — no Homebrew, no dependencies.

---

## Step 2 — Create the Mac OS 9 disk image

```bash
make create-disk
```

Creates `disks/macos9.img` — a 6 GB **raw** disk image. Raw format is required;
QCOW2 causes mac99's ATA driver in Mac OS 9 to fail device enumeration.
See `config/qemu.conf.sh` quirk #1 for details.

---

## Step 3 — Obtain Mac OS 9

> **Legal note:** Mac OS 9 is Apple proprietary software. You must own a valid
> license. See `docs/legal-notes.md`.

Download **Mac OS 9.2.2 Universal** and place the ISO at:

```
disks/macos9.iso
```

Mac OS 9.2.2 is the only version that has been tested with this setup.

---

## Step 4 — Install Mac OS 9

```bash
make install-os
```

A QEMU window will open. **The install flow is not obvious** — follow these steps
exactly:

### 4a — Wait for boot (~60 seconds)

OpenBIOS takes about 30 seconds before the grey Mac OS 9 boot screen appears.
Wait for the full desktop to appear before clicking anything.

### 4b — Run Drive Setup before the installer

The installer will open automatically and immediately say **"no volumes available"**.
This is expected — the blank disk has no Apple Partition Map yet and the installer
won't touch it. You must initialize the disk first:

1. Close or ignore the installer for now
2. On the desktop, double-click the installer CD icon
3. Open the **Utilities** folder inside the CD
4. Open **Drive Setup**
5. Drive Setup will list your blank disk — select it
6. Click **Initialize** and accept the default HFS+ (Mac OS Extended) format
7. Drive Setup writes an Apple Partition Map and formats the volume
8. Quit Drive Setup

### 4c — Run the installer

1. Open the Mac OS 9 Installer (either from the CD or the still-open window)
2. The formatted volume now appears as an installation target
3. Select it and click **Install**
4. Let the installation run to completion (~5–10 minutes)

### 4d — Shut down cleanly

When the installer finishes: **Special → Shut Down** from the Mac OS 9 menu bar.

> ⚠️ Do **not** click the red close button on the QEMU window. That kills QEMU
> abruptly without flushing the disk, which can corrupt the image. Always use
> Mac OS 9's own Shut Down.

---

## Step 5 — Verify the install boots

```bash
make launch
```

Mac OS 9 should boot from `disks/macos9.img` to the full desktop in ~60 seconds.
If you see the Mac OS 9 desktop, the install succeeded.

---

## Step 6 — Install Ferazel's Wand

Download the game from [Macintosh Garden](https://macintoshgarden.org/games/ferazels-wand).

**Use the no-gamma patched v1.0.3** — the standard binary has a gamma screen-fade
effect that crashes QEMU during gameplay (particularly when using the dagger).

### Transferring the game into the disk image

The easiest method is a small transfer disk image:

```bash
# Create a 256 MB HFS transfer disk on your Mac
vendor/qemu/bin/qemu-img create -f raw disks/transfer.img 256M
hdiutil attach disks/transfer.img   # mounts it in macOS Finder
# Drag the Ferazel's Wand .sit file onto the mounted volume in Finder
hdiutil detach /Volumes/...         # eject it
```

Then launch with the transfer disk attached as a second IDE drive:

```bash
QEMU="vendor/qemu/bin/qemu-system-ppc"
FW="vendor/qemu/share/qemu"
DISK="disks/macos9.img"
XFER="disks/transfer.img"

"${QEMU}" -L "${FW}" \
    -M mac99 -m 256 -cpu G4 \
    -device ide-hd,bus=ide.0,unit=0,drive=hd0 \
    -drive  id=hd0,file="${DISK}",format=raw,if=none \
    -device ide-hd,bus=ide.0,unit=1,drive=xfer \
    -drive  id=xfer,file="${XFER}",format=raw,if=none \
    -display cocoa,zoom-to-fit=on \
    -audiodev coreaudio,id=snd0 \
    -usb -device usb-mouse -device usb-kbd
```

Inside Mac OS 9, the transfer disk will appear on the desktop. Use StuffIt Expander
(should already be on the installer CD or in the Mac OS 9 system) to expand the
`.sit` archive, then drag the game folder to the hard disk.

---

## Step 7 — Play

```bash
make launch
# or double-click FerazelsWand.app
```

All game saves are written to `disks/macos9.img`. They survive reboots and travel
with the repo folder.

---

## Portability

After `make vendor`, the repo is fully self-contained:

```
ferazels-wand-emulator/
├── FerazelsWand.app        ← double-click to play
├── vendor/qemu/            ← QEMU binary + 28 dylibs + firmware (ARM64, ~320 MB)
├── disks/macos9.img        ← Mac OS 9 + game + saves (~6 GB raw image)
├── config/qemu.conf.sh     ← all QEMU flags + detailed quirk documentation
└── scripts/                ← setup and launch helpers
```

Copy the folder to any ARM64 Mac and double-click `FerazelsWand.app`.

---

## Obtaining Mac OS 9

- [Macintosh Garden](https://macintoshgarden.org) — community preservation archive
- [Internet Archive](https://archive.org) — search "Mac OS 9.2.2"
- Rip your own with Disk Utility if you own original retail media

**Tested version:** Mac OS 9.2.2 Universal (`macos-922-uni.iso`, 579 MB)

---

## Obtaining the Game

All versions at [Macintosh Garden — Ferazel's Wand](https://macintoshgarden.org/games/ferazels-wand):

| Version | Recommendation |
|---|---|
| v1.0.3 (no-gamma patch) | **Use this** — stable under QEMU, no gamma crash |
| v1.0.2 + 1.0.3 update | Works but requires patching manually |
| Prototype v1.0d6 / d7 | Historical interest only |

---

## Troubleshooting

**QEMU window is black / doesn't boot**
Mac OS 9 takes 30–60 s before anything appears. If it stays black past 90 s,
verify `disks/macos9.img` exists and is larger than a few MB.

**"No volumes available" in the installer**
Expected on a blank disk. Run Drive Setup from the CD's Utilities folder first
to initialize the disk, then re-run the installer. See Step 4b above.

**"Couldn't read big system resources" during install**
Caused by running with `via=pmu` or more than 256 MB RAM. Both are disabled
in the current config. If you see this, verify `config/qemu.conf.sh` has
`-M mac99` (no `via=pmu`) and `-m 256`.

**Audio doesn't work**
macOS may prompt for microphone/audio access on first launch. Allow it in
System Settings → Privacy & Security → Microphone.

**Game crashes when using the dagger**
You are using the standard v1.0.3 binary instead of the no-gamma patch.
The gamma fade on startup/death triggers a QEMU crash. Download the
`Ferazels_Wand_103_nogamma.sit` version from Macintosh Garden.

**`make vendor` fails: "declare: -A: invalid option"**
macOS ships bash 3.2 which doesn't support associative arrays. This was fixed
in `scripts/vendor-qemu.sh` — update to the latest version of this repo.
