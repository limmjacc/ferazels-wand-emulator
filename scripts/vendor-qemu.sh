#!/usr/bin/env bash
# Bundle qemu-system-ppc, qemu-img, their dylib dependencies, and QEMU firmware
# data files into vendor/qemu/ so the emulator is fully self-contained and
# portable to any ARM64 Mac without requiring Homebrew or QEMU installed.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

BREW_PREFIX="/opt/homebrew"
BREW="${BREW_PREFIX}/bin/brew"
VENDOR="${REPO_ROOT}/vendor/qemu"
BIN_DIR="${VENDOR}/bin"
LIB_DIR="${VENDOR}/lib"
SHARE_DIR="${VENDOR}/share"

BINARIES=("qemu-system-ppc" "qemu-img")

# ── Preflight ────────────────────────────────────────────────────────────────

if [[ ! -x "${BREW_PREFIX}/bin/qemu-system-ppc" ]]; then
    echo "ERROR: qemu-system-ppc not found in Homebrew. Run 'make setup' first."
    exit 1
fi

if [[ -d "${VENDOR}/bin" ]]; then
    echo "vendor/qemu/ already exists. Remove it with 'make clean' to re-vendor."
    exit 0
fi

echo "==> Bundling QEMU into vendor/qemu/ for portability..."
mkdir -p "${BIN_DIR}" "${LIB_DIR}" "${SHARE_DIR}"

# ── Dylib bundler ────────────────────────────────────────────────────────────
# Recursively copies non-system dylibs and rewrites load paths so the binaries
# find their libraries via @loader_path regardless of where the repo lives.

declare -A BUNDLED=()

bundle_dylibs() {
    local target="$1"

    local deps
    deps="$(otool -L "${target}" 2>/dev/null | tail -n +2 | awk '{print $1}')"

    while IFS= read -r dep; do
        [[ -z "${dep}" ]] && continue
        # Skip system libraries — they're guaranteed on every macOS install
        [[ "${dep}" == /usr/lib/* ]]    && continue
        [[ "${dep}" == /System/* ]]     && continue
        [[ "${dep}" == @rpath/* ]]      && continue
        [[ "${dep}" == @loader_path/* ]] && continue
        [[ "${dep}" == @executable_path/* ]] && continue

        local libname
        libname="$(basename "${dep}")"
        local dest="${LIB_DIR}/${libname}"

        # Rewrite the reference in the current target
        local new_ref
        if [[ "${target}" == "${BIN_DIR}/"* ]]; then
            new_ref="@loader_path/../lib/${libname}"
        else
            new_ref="@loader_path/${libname}"
        fi
        install_name_tool -change "${dep}" "${new_ref}" "${target}" 2>/dev/null || true

        # Copy and recurse if not already handled
        if [[ -z "${BUNDLED[${libname}]+x}" ]]; then
            BUNDLED["${libname}"]=1
            if [[ -f "${dep}" ]]; then
                echo "    + ${libname}"
                cp "${dep}" "${dest}"
                chmod 755 "${dest}"
                install_name_tool -id "@loader_path/${libname}" "${dest}" 2>/dev/null || true
                bundle_dylibs "${dest}"
            fi
        fi
    done <<< "${deps}"
}

# ── Copy and fix binaries ────────────────────────────────────────────────────

for bin in "${BINARIES[@]}"; do
    src="${BREW_PREFIX}/bin/${bin}"
    dst="${BIN_DIR}/${bin}"
    echo "  Copying ${bin}..."
    cp "${src}" "${dst}"
    chmod 755 "${dst}"
    bundle_dylibs "${dst}"
    # Re-sign with ad-hoc signature after modifying load commands
    codesign --force --sign - "${dst}" 2>/dev/null || true
done

# Re-sign all bundled dylibs
for lib in "${LIB_DIR}"/*.dylib; do
    [[ -f "${lib}" ]] || continue
    codesign --force --sign - "${lib}" 2>/dev/null || true
done

# ── Copy QEMU firmware data ──────────────────────────────────────────────────
# QEMU needs OpenBIOS (for mac99), VGA BIOS, and other firmware blobs.
# These are pointed to at runtime via the -L flag in launch.sh.

echo "  Copying QEMU firmware data..."
cp -r "${BREW_PREFIX}/share/qemu" "${SHARE_DIR}/"

# ── Summary ──────────────────────────────────────────────────────────────────

bin_count="${#BINARIES[@]}"
lib_count="$(find "${LIB_DIR}" -name '*.dylib' | wc -l | tr -d ' ')"
share_size="$(du -sh "${SHARE_DIR}/qemu" 2>/dev/null | awk '{print $1}')"

echo ""
echo "==> vendor/qemu/ is ready."
echo "    Binaries : ${bin_count} (${BIN_DIR})"
echo "    Libraries: ${lib_count} dylibs (${LIB_DIR})"
echo "    Firmware : ${share_size} (${SHARE_DIR}/qemu)"
echo ""
echo "The repo is now fully self-contained."
echo "Copy it to any ARM64 Mac and run 'make launch' — no Homebrew required."
