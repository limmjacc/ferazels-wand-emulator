# Screamer Audio Architecture

## Overview

Mac OS 9 audio in this emulator is provided by the **Screamer** chip — Apple's internal name
for the AWACS (Apple Workgroup Audio Controller System) codec used in Power Mac G4 hardware.
Screamer is absent from all upstream QEMU releases. This project builds from Mark Cave-Ayland's
`screamer` branch of mcayland/qemu, which adds it back.

## Why Screamer Is Not in Upstream QEMU

A formal patch series (by "Programmingkid", 4 revisions, Dec 2019 – Feb 2020) was submitted to
the qemu-devel mailing list. All four versions passed automated CI but received no maintainer
review. The patch was archived without acceptance or rejection. As of March 2025, a community
attempt to revive it against current QEMU was still flagged with unresolved issues (see
SCREAMER_BUFFER_SIZE below). It remains an out-of-tree fork indefinitely.

## Audio Pipeline

```
Mac OS 9 Sound Manager
        |
        v
AWACS/Screamer driver (Apple extension)
        |  programs DMA descriptor ring
        v
Screamer chip registers (hw/audio/screamer.c in QEMU)
        |  DBDMA channel 0x10 (output), 0x12 (input)
        v
QEMU DBDMA engine (macio DMA)
        |
        v
CoreAudio backend (coreaudio,id=snd0)
        |
        v
macOS audio output
```

## Required Conditions for Audio to Work

All of these must be true simultaneously. Any one missing = silence.

| Condition | How it is set | What breaks without it |
|-----------|---------------|------------------------|
| Screamer-specific `openbios-ppc` | Build copies from screamer source `pc-bios/` | OF device tree has no `sound` node; Mac OS 9 Sound Manager never binds the driver; Sound panel shows generic "Built-in" but DMA never fires |
| `-M mac99,via=pmu` in QEMU flags | `config/qemu.conf.sh` | PMU does not route Screamer DMA completion IRQs; Mac OS 9 queues audio DMA but never gets the completion callback; 0 bytes written to audio backend |
| Virtual Memory ON in Mac OS 9 | Apple menu → Control Panels → Memory → Virtual Memory: On | Sound output breaks; known Mac OS 9 + Screamer emulation requirement |
| RAM <= 896 MB | `config/qemu.conf.sh` `-m 256` | >1024 MB causes severely impaired sound and system instability in Mac OS 9 |
| `-audiodev "coreaudio,id=snd0"` | `config/qemu.conf.sh` | No CoreAudio backend available |
| `-global "screamer.audiodev=snd0"` | `config/qemu.conf.sh` | Screamer device falls back to deprecated default audiodev; may not produce output |

## Verification Checklist

After a new build, boot Mac OS 9 and open Apple menu → Control Panels → Sound:

- **Output tab should show "Spatializer Audio Laboratories"** — this confirms the
  screamer-specific openbios-ppc is active and the OF device tree correctly exposes
  the Screamer hardware. If it shows only "Built-in", the wrong openbios-ppc is loaded.
- Volume slider should respond and play a preview tone when moved.
- Virtual Memory should be On (check Memory control panel).

## Diagnostic: WAV Capture Test

To verify whether Mac OS 9 is sending audio to QEMU's Screamer at all, swap the CoreAudio
backend for a WAV file and check whether any bytes are written:

```bash
cd /path/to/ferazels-wand-emulator
vendor/qemu/bin/qemu-system-ppc \
  -L vendor/qemu/share/qemu \
  -M "mac99,via=pmu" -m 256 -cpu G4 \
  -device "ide-hd,bus=ide.0,unit=0,drive=hd0" \
  -drive  "id=hd0,file=disks/macos9.img,format=raw,if=none" \
  -display "cocoa,full-screen=on" \
  -audiodev "wav,id=snd0,path=/tmp/ferazel-audio-test.wav" \
  -global "screamer.audiodev=snd0" \
  -usb -device usb-mouse -device usb-kbd
```

After booting, move the Sound control panel Alert volume slider, then Special → Shut Down.

```bash
ls -lh /tmp/ferazel-audio-test.wav
```

- **44 bytes** = WAV header only — Mac OS 9 sent zero audio data to QEMU. Check openbios-ppc
  and via=pmu.
- **> 1 KB** = audio data flowing from Mac OS 9 through Screamer to QEMU. If CoreAudio is
  still silent, the issue is in the macOS audio stack (permissions, device selection).

## The openbios-ppc Problem

The screamer fork ships a custom `pc-bios/openbios-ppc` that adds a `sound` node to the
OpenFirmware device tree under `/pci/mac-io`. This node maps the Screamer's DBDMA channel
addresses (0x10 output, 0x12 input) so Mac OS 9's AWACS driver can find and program them.

Standard `openbios-ppc` from Homebrew QEMU 11 (or any upstream QEMU) has no such node.
Without it, Mac OS 9 detects the Screamer device at the PCI level and shows "Built-in" in
the Sound control panel, but the AWACS driver cannot set up DMA — so the audio pipeline
exists but is never activated.

The build script (`scripts/build-qemu-screamer.sh`) uses a two-phase firmware copy:
1. Copy all option ROMs from Homebrew (vgabios, sgabios, efi-*.rom, etc.)
2. Overlay with the screamer source tree's `pc-bios/` — overwriting openbios-ppc with the
   screamer-specific build

## The via=pmu Problem

`-M mac99,via=pmu` wires up the VIA/PMU (Power Management Unit) chip. In real Power Mac G4
hardware, the PMU routes interrupt lines from the Screamer chip back to the CPU. QEMU's
mac99 machine exposes these interrupt lines only when `via=pmu` is set.

Without `via=pmu`, the Screamer device realizes correctly (no error), Mac OS 9's driver loads
and programs the DMA descriptor ring, but the DBDMA engine never fires the completion IRQ.
The result is confirmed silence: a WAV capture test shows exactly 44 bytes (header only).

`via=pmu` is intentionally omitted from `install-os.sh`, which uses Homebrew QEMU 11 for the
OS installation. PMU causes "couldn't read big system resources" failures in the Mac OS 9
installer under that QEMU version. The gameplay scripts (Play.command, launch.sh) use the
vendored screamer build where `via=pmu` works correctly.

## SCREAMER_BUFFER_SIZE

Both the `screamer` and `screamer-v9.1.0` branches define `SCREAMER_BUFFER_SIZE = 0x4000`.
A March 2025 qemu-ppc mailing list discussion identified that `0x8000` is needed for the Mac
ROM startup chord to play without crashing. This has not been fixed in the fork as of the
last update. If audio plays but is choppy or crashes on boot, patching this value in
`include/hw/audio/screamer.h` and rebuilding may help.

## Branch History

| Branch | QEMU base | Last commit | Status |
|--------|-----------|-------------|--------|
| `screamer` | 7.1.94 | December 2022 | Used by this project |
| `screamer-v9.1.0` | 9.1.0 | September 2024 | Newer rebase, same patches |

The `screamer-v9.1.0` branch has a smaller `openbios-ppc` (657 KB vs 1.7 MB in `screamer`).
Both have confirmed working audio reports from the community. This project uses the `screamer`
branch (7.1.94) because the Cocoa UI patches for zoom-to-fit and black background were
developed and tested against that version.

## Known Limitations

- Audio quality may include crackling or dropouts under heavy CPU load (TCG emulation, no
  hardware acceleration for PPC on Apple Silicon).
- The Apple Audio Extension (`AppleAudioExtension`) that ships with some QuickTime versions
  may crash on boot with the Screamer emulation. If extensions crash on startup, boot with
  extensions disabled (hold Shift at startup) and remove or disable it via Extensions Manager.
- USB audio (`-device usb-audio`) is not a viable alternative — it freezes after a few seconds.
- Screamer audio is not available in the `g3beige` machine type; mac99 only.
