#!/usr/bin/env bash
set -euo pipefail

# --- Configuration --------------------------------------------------------
CXX=x86_64-w64-mingw32-g++
STD='-std=c++17'

SRC="mace_c_api.cpp"      # your C API file
INCLUDES=(
  -Iinclude
  -Iinclude/bose
  -I../../JuceLibraryCode
  -I../../../Libs/JUCE/modules
  -I../../Source
  -I../../Externals/Include
  -I../../../Libs
)

# Use the MACE static lib built by the Makefile
STATIC_LIB="lib/windows/x86_64/libMACE.a"

BUILD="build_win_dll"
FW="MaceAPI"

# Windows system libs MACE depends on
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


# --- Clean + prepare dirs -------------------------------------------------
rm -rf "${BUILD}"
mkdir -p "${BUILD}"

OUT_WIN="${BUILD}/${FW}.dll"
OUT_IMPLIB="${BUILD}/lib${FW}.a"

echo "Building Windows x86_64 DLL from ${STATIC_LIB}..."

"${CXX}" ${STD} -shared \
  "${INCLUDES[@]}" \
  "${SRC}" \
  -Wl,--whole-archive "${STATIC_LIB}" -Wl,--no-whole-archive \
  -Wl,--out-implib,"${OUT_IMPLIB}" \
  "${WIN_LIBS[@]}" \
  -o "${OUT_WIN}"

echo "  ⇢ ${OUT_WIN}"
echo "  ⇢ import lib: ${OUT_IMPLIB}"

echo "✅ Windows x86_64 DLL ready for Flutter FFI: ${OUT_WIN}"
