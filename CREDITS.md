# Credits

---

## Ferazel's Wand

**Developed and published by [Ambrosia Software](https://www.ambrosiasw.com)**

- **Ben Spees** — game design and programming
- **Eric Speier** — original soundtrack (30 tracks)
- Ambrosia Software shut down in 2017. Ferazel's Wand is preserved on
  [Macintosh Garden](https://macintoshgarden.org/games/ferazels-wand).

---

## Mac OS 9

**Apple Inc.**

Mac OS 9 is proprietary software owned by Apple Inc. This project does not distribute
Mac OS 9 and does not endorse obtaining it without a valid license.

---

## QEMU

**The QEMU Project** — [qemu.org](https://www.qemu.org)

QEMU is free and open-source software released under the GNU General Public License v2.
This project builds from the `screamer` branch of
[mcayland/qemu](https://github.com/mcayland/qemu), maintained by **Mark Cave-Ayland**,
which adds emulation of the Apple Screamer (AWACS) audio chip for the mac99 machine type.
Without this fork, Mac OS 9 audio would be completely absent.

Original Screamer patch series submitted to qemu-devel by **John Arbuckle (programmingkid)**
(December 2019 – February 2020), upon whose work mcayland's branch is built.

---

## OpenBIOS

**The OpenBIOS Project** — [openfirmware.info](https://openfirmware.info)

OpenBIOS is the open-source OpenFirmware implementation used to boot the mac99 machine.
The `screamer` branch of mcayland/qemu includes a modified OpenBIOS build that adds
Screamer DBDMA device-tree entries required for Mac OS 9 audio. Without this custom
firmware, the audio pipeline is silently non-functional even when QEMU's Screamer device
is present.

---

## The Unarchiver (unar)

**Dag Agren and The Unarchiver Project** — [theunarchiver.com](https://theunarchiver.com)

`unar` is the command-line interface for The Unarchiver, an open-source multi-format
archive extractor. This project uses it to extract StuffIt `.sit` patch archives with
resource fork metadata preserved, enabling the automated patch application step without
requiring Mac OS 9 to be running.

---

## Macintosh Garden

**The Macintosh Garden community** — [macintoshgarden.org](https://macintoshgarden.org)

Macintosh Garden is a community preservation archive for classic Macintosh software.
Ferazel's Wand, the v1.0.3 update, and the no-gamma patch are all hosted there and would
otherwise be effectively lost. This project would not exist without their preservation work.

---

## The Cutting Room Floor

**TCRF contributors** — [tcrf.net/Ferazel%27s_Wand](https://tcrf.net/Ferazel%27s_Wand)

Documentation of unused and cut content in Ferazel's Wand referenced in this project's
README was researched and written by contributors to The Cutting Room Floor wiki.

---

## Homebrew

**The Homebrew Project** — [brew.sh](https://brew.sh)

Homebrew is used during the one-time setup step to install build dependencies and QEMU
runtime libraries. It is not required at runtime after `make vendor` completes.

---

## This Project

This emulator project is an independent, community-built tool. It is not affiliated with
Ambrosia Software, Ben Spees, Eric Speier, or Apple Inc.
