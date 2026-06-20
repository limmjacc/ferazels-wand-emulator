#!/usr/bin/env bash
# Bundle qemu-system-ppc, qemu-img, unar, their dylib dependencies, and QEMU
# firmware into vendor/qemu/ so the emulator is fully self-contained and
# portable to any ARM64 Mac without Homebrew.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

BREW_PREFIX="/opt/homebrew"
VENDOR="${REPO_ROOT}/vendor/qemu"
BIN_DIR="${VENDOR}/bin"
LIB_DIR="${VENDOR}/lib"
SHARE_DIR="${VENDOR}/share"

BINARIES=("qemu-system-ppc" "qemu-img" "unar")

# ── Preflight ────────────────────────────────────────────────────────────────

for bin in "${BINARIES[@]}"; do
    if [[ ! -x "${BREW_PREFIX}/bin/${bin}" ]]; then
        echo "ERROR: ${bin} not found in Homebrew. Run 'make setup' first."
        exit 1
    fi
done

if [[ -d "${VENDOR}/bin" ]]; then
    echo "vendor/qemu/ already exists. Run 'make clean' to rebuild."
    exit 0
fi

echo "==> Bundling QEMU + unar into vendor/qemu/ for portability..."
mkdir -p "${BIN_DIR}" "${LIB_DIR}" "${SHARE_DIR}"

# ── Dylib bundler ─────────────────────────────────────────────────────────────
# Recursively copies non-system dylibs and rewrites load paths so the binaries
# find their libraries via @loader_path regardless of where the repo lives.
# Uses file-existence check instead of associative array (macOS bash 3.2 compat
# — no declare -A). See config/qemu.conf.sh quirk #7.

bundle_dylibs() {
    local target="$1"
    local deps
    deps="$(otool -L "${target}" 2>/dev/null | tail -n +2 | awk '{print $1}')"

    while IFS= read -r dep; do
        [[ -z "${dep}" ]]                   && continue
        [[ "${dep}" == /usr/lib/* ]]        && continue
        [[ "${dep}" == /System/* ]]         && continue
        [[ "${dep}" == @rpath/* ]]          && continue
        [[ "${dep}" == @loader_path/* ]]    && continue
        [[ "${dep}" == @executable_path/* ]] && continue

        local libname
        libname="$(basename "${dep}")"
        local dest="${LIB_DIR}/${libname}"

        local new_ref
        if [[ "${target}" == "${BIN_DIR}/"* ]]; then
            new_ref="@loader_path/../lib/${libname}"
        else
            new_ref="@loader_path/${libname}"
        fi
        install_name_tool -change "${dep}" "${new_ref}" "${target}" 2>/dev/null || true

        if [[ ! -f "${dest}" ]]; then
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

# ── Copy binaries + dylibs ───────────────────────────────────────────────────

for bin in "${BINARIES[@]}"; do
    src="${BREW_PREFIX}/bin/${bin}"
    dst="${BIN_DIR}/${bin}"
    echo "  Bundling ${bin}..."
    cp "${src}" "${dst}"
    chmod 755 "${dst}"
    bundle_dylibs "${dst}"
    codesign --force --sign - "${dst}" 2>/dev/null || true
done

for lib in "${LIB_DIR}"/*.dylib; do
    [[ -f "${lib}" ]] || continue
    codesign --force --sign - "${lib}" 2>/dev/null || true
done

# ── Copy QEMU firmware ────────────────────────────────────────────────────────

echo "  Copying QEMU firmware data..."
cp -r "${BREW_PREFIX}/share/qemu" "${SHARE_DIR}/"

# ── Summary ──────────────────────────────────────────────────────────────────

lib_count="$(find "${LIB_DIR}" -name '*.dylib' | wc -l | tr -d ' ')"
share_size="$(du -sh "${SHARE_DIR}/qemu" 2>/dev/null | awk '{print $1}')"

echo ""
echo "==> vendor/qemu/ ready."
echo "    Binaries : ${#BINARIES[@]} (${BIN_DIR})"
echo "    Libraries: ${lib_count} dylibs (${LIB_DIR})"
echo "    Firmware : ${share_size} (${SHARE_DIR}/qemu)"
echo ""
echo "The repo is now self-contained. Copy to any ARM64 Mac — no Homebrew needed."
echo "Next: run 'make create-disk'."
