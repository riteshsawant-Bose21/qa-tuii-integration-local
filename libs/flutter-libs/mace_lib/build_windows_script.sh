#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./build_windows_script.sh                 # defaults to ARCH=x86_64
#   ARCH=x86_64 ./build_windows_script.sh
#
# If ARCH=arm64 and you don't have aarch64-w64-mingw32-g++ in PATH,
# you can override with:
#   ARCH=arm64 CXX_ARM64="clang --target=aarch64-w64-mingw32" ./build_windows_script.sh

# --- Architecture selection ------------------------------------------------
ARCH="${ARCH:-x86_64}"   # x86_64 | arm64

# You can override these from the environment if needed
CXX_X86_64_DEFAULT="x86_64-w64-mingw32-g++"
CXX_ARM64_DEFAULT="aarch64-w64-mingw32-g++"   # override if you use clang/llvm-mingw

CXX_X86_64="${CXX_X86_64:-$CXX_X86_64_DEFAULT}"
CXX_ARM64="${CXX_ARM64:-$CXX_ARM64_DEFAULT}"

case "${ARCH}" in
  x86_64)
    TRIPLET="x86_64-w64-mingw32"
    LIB_SUBDIR="x86_64"
    CXX="${CXX_X86_64}"
    ;;
  arm64|aarch64)
    TRIPLET="aarch64-w64-mingw32"
    LIB_SUBDIR="arm64"
    CXX="${CXX_ARM64}"
    ;;
  *)
    echo "Unsupported ARCH: ${ARCH} (expected x86_64 or arm64)"
    exit 1
    ;;
esac

# Check compiler exists
if ! command -v ${CXX%% *} >/dev/null 2>&1; then
  echo "Error: compiler '${CXX}' not found in PATH for ARCH=${ARCH}."
  echo "Hints:"
  echo "  - Install the appropriate MinGW-w64 toolchain for ${TRIPLET}, OR"
  echo "  - Override via:"
  echo "      ARCH=${ARCH} CXX_${ARCH^^}=\"clang --target=${TRIPLET}\" ./build_windows_script.sh"
  exit 1
fi

STD='-std=c++17'

# --- Inputs ---------------------------------------------------------------
# Your Windows wrapper that includes "mace_c_api.h"
SRC="mace_c_windows_api.cpp"

INCLUDES=(
  -Iinclude
  -Iinclude/bose
  -I../../JuceLibraryCode
  -I../../../Libs/JUCE/modules
  -I../../Source
  -I../../Externals/Include
  -I../../../Libs
  # add more if needed, e.g.:
  # -I../../../Libs/MACE/include
)

# Use the MACE static lib built for this arch
STATIC_LIB="lib/windows/${LIB_SUBDIR}/libMACE.a"

FW="MaceAPI"
BUILD_BASE="build_win_dll"
BUILD="${BUILD_BASE}/${ARCH}"

# Windows system libs MACE + JUCE depend on
WIN_LIBS=(
  -lwinmm
  -lole32
  -luuid
  -lcomdlg32
  -lgdi32
  -lws2_32
  -ldsound
  -lwininet
  -lversion
  -lshlwapi
)

# Static MinGW runtime (no libstdc++-6.dll etc.)
RUNTIME_FLAGS=(
  -static-libgcc
  -static-libstdc++
  -Wl,-Bstatic -lwinpthread -Wl,-Bdynamic
)

# --- Prepare dirs ---------------------------------------------------------
rm -rf "${BUILD}"
mkdir -p "${BUILD}"

OUT_WIN="${BUILD}/${FW}.dll"
OUT_IMPLIB="${BUILD}/lib${FW}.a"

echo "Building Windows ${ARCH} DLL from ${STATIC_LIB} using compiler: ${CXX}"

"${CXX}" ${STD} -shared \
  "${INCLUDES[@]}" \
  "${SRC}" \
  -Wl,--whole-archive "${STATIC_LIB}" -Wl,--no-whole-archive \
  -Wl,--out-implib,"${OUT_IMPLIB}" \
  "${RUNTIME_FLAGS[@]}" \
  "${WIN_LIBS[@]}" \
  -o "${OUT_WIN}"

echo "  ⇢ ${OUT_WIN}"
echo "  ⇢ import lib: ${OUT_IMPLIB}"
echo "✅ Windows ${ARCH} DLL ready for Flutter FFI: ${OUT_WIN}"
