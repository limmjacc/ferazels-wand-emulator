# Legal Notes

---

## Ferazel's Wand

Ferazel's Wand was developed and published by **Ambrosia Software**, designed by Ben Spees.
Ambrosia Software shut down in 2017. The game is widely considered abandonware and is hosted
publicly on Macintosh Garden, but copyright technically still exists and was never formally
released into the public domain.

**Recommendation:** Obtain the game from [Macintosh Garden](https://macintoshgarden.org/games/ferazels-wand).
Do not redistribute the game files.

---

## Mac OS 9

Mac OS 9 is proprietary software owned by **Apple Inc.** It was never open-sourced or released
into the public domain. You need a valid license to use it — this typically means owning an
original retail copy or a Mac that shipped with Mac OS 9 pre-installed.

This project does not bundle Mac OS 9 and does not provide instructions for obtaining it
without a valid license.

---

## QEMU

QEMU is free and open-source software released under the **GNU General Public License v2**.
Source code is available at [https://www.qemu.org](https://www.qemu.org).

The binary bundled in `vendor/qemu/` is compiled from the
[mcayland/qemu screamer branch](https://github.com/mcayland/qemu/tree/screamer),
maintained by Mark Cave-Ayland. This fork adds emulation of the Apple Screamer (AWACS)
audio chip and a custom OpenBIOS build, both also under GPL v2.

---

## OpenBIOS

OpenBIOS is free and open-source software released under the **GNU General Public License v2**.
Source code is available at [https://openfirmware.info](https://openfirmware.info).

The `openbios-ppc` firmware bundled in `vendor/qemu/share/qemu/` is a modified build from
the mcayland/qemu screamer branch, which adds device-tree entries for the Screamer audio chip.

---

## The Unarchiver (unar)

`unar` is part of The Unarchiver, released under the **GNU General Public License v2**.
Source code is available at [https://theunarchiver.com](https://theunarchiver.com).

The `unar` binary bundled in `vendor/qemu/bin/` is an unmodified copy from Homebrew.

---

## This Project

This emulator project is an independent, community-built tool. It is not affiliated with
Ambrosia Software, Ben Spees, or Apple Inc. No copyrighted game data, OS images, or firmware
are bundled in this repository.

See [CREDITS.md](../CREDITS.md) for full attribution.
