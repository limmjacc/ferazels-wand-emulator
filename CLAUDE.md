# Ferazel's Wand Emulator — Project Context

## What This Is

A fully self-contained QEMU-PPC emulator that runs the original 1999 Ferazel's Wand
game binary (Mac OS 9, Ambrosia Software) on Apple Silicon Macs. Single double-click
launch via a shell `.app` bundle. All game data and saves live inside `disks/macos9.img`.

## Critical Constraints

- **No Co-Authored-By lines in git commits** (user preference, strict)
- **No Homebrew at runtime** — QEMU and unar are vendored into `vendor/qemu/`
- **ARM64 only** — targets M1/M2/M3/M4 Macs
- **macOS bash is 3.2** — no `declare -A`, no bash 4+ features anywhere

## Architecture

### The Emulation Stack

```
FerazelsWand.app (shell .app bundle)
  └── FerazelsWand (bash script)
        └── vendor/qemu/bin/qemu-system-ppc
              └── -M mac99 (Power Mac G4)
                    └── Mac OS 9.2.2 on disks/macos9.img
                          └── Ferazel's Wand nogamma (game executable)
```

### Key Files

- `config/qemu.conf.sh` — central config, sourced by all scripts. Documents 9 QEMU quirks.
- `scripts/apply-patches.sh` — automated patch application; mounts disk on macOS, no QEMU needed
- `scripts/vendor-qemu.sh` — bundles QEMU + unar + dylibs using otool/install_name_tool
- `disks/macos9.img` — 6 GB raw HFS+ disk; holds OS + game + saves; gitignored

### Setup Flow

```
make setup          → brew install qemu unar
make vendor         → copy binaries + dylibs to vendor/qemu/, fix rpath with install_name_tool
make create-disk    → qemu-img create -f raw macos9.img 6G
make install-os     → INTERACTIVE QEMU: user does Drive Setup + Mac OS 9 install
make install-game   → INTERACTIVE QEMU: user runs Ferazel's Wand Installer from game CD
make apply-patches  → AUTOMATED: hdiutil attach + unar + ditto (no QEMU)
make launch         → normal gameplay
```

## Discovered QEMU Quirks (see config/qemu.conf.sh for full details)

1. Raw disk format required (QCOW2 fails mac99 ATA enumeration)
2. Explicit IDE bus assignment required (`-device ide-hd,bus=ide.0,unit=0`)
3. No `via=pmu` (causes installer failures)
4. 256 MB RAM only (512 MB unstable)
5. No `-device screamer` in QEMU 11 (now auto-connected)
6. `cache=unsafe` on CD during OS install (prevents read stalls)
7. macOS bash 3.2 — no associative arrays
8. Game folder name has U+0192 ƒ character — use globs
9. Game CD is plain HFS (macOS Catalina+ can't mount it) — use machfs or mac99's CD driver

## Why the Game Install Is Interactive

The game CD uses **Installer VISE** — all game files are packed in a proprietary format
inside the installer application's 67 MB data fork. There is no macOS extractor for
Installer VISE. The install **must** happen inside Mac OS 9.

## Why Patch Application Is Automated

After the Installer VISE session, `disks/macos9.img` is an HFS+ volume that macOS can
mount with `hdiutil attach`. Files are readable/writable including resource forks via
`filename/..namedfork/rsrc`. `unar` extracts StuffIt `.sit` archives with resource fork
metadata in AppleDouble format; `ditto` merges that into proper HFS+ resource forks.

## Resource Forks

Classic Mac OS apps store executable code in their resource fork (CODE resources).
Game data files (Backgrounds, Sounds, Sprites, Titles, World Data) also live in
resource forks. Data forks for these files are 0 bytes. `ditto` must be used instead
of `cp` when copying game files on macOS.

## Disk Image Notes

- `disks/macos9.img` — HFS+ (Apple Partition Map), mountable on macOS
- Volume name visible to macOS: "untitled" (Drive Setup default in Mac OS 9)
- Game installed at: `{volume}/Ferazel's Wand 1.0.2 ƒ/` (ƒ = U+0192)
- Game executable: `Ferazel's Wand nogamma` (post-patch)

## Vendoring

`scripts/vendor-qemu.sh` uses:
- `otool -L` to find dylib dependencies
- `install_name_tool -change` to rewrite paths to `@loader_path`
- `codesign --force --sign -` for ad-hoc re-signing after load command edits

Vendored binaries: `qemu-system-ppc`, `qemu-img`, `unar` + their dylibs.
QEMU firmware (OpenBIOS etc.) copied from `$(brew --prefix)/share/qemu`.

## What NOT to Do

- Don't close the QEMU window with the red button during setup — corrupts disk
- Don't increase RAM beyond 256 MB — causes installer instability
- Don't add `via=pmu` to the machine flags
- Don't use QCOW2 format for the disk image
- Don't use `cp` for game files — loses resource forks; use `ditto`
