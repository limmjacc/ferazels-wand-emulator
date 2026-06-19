# app/ — Native macOS App Wrapper (Planned)

This directory will contain a native macOS `.app` bundle that wraps the QEMU-based
emulator into a double-clickable application.

## Planned features

- SwiftUI wrapper that launches QEMU in-process or as a subprocess
- Bundled `vendor/qemu/` binaries inside the `.app` Resources
- First-run setup wizard (disk image creation, OS installation)
- Game save backup / restore
- Full-screen mode

## Current status

Not yet started. The `scripts/` + `Makefile` workflow in the repo root is the working
interface in the meantime.
