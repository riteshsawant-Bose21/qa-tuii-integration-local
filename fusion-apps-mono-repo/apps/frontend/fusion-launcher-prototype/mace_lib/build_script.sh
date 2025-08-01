#!/usr/bin/env bash
set -euo pipefail

# --- Configuration --------------------------------------------------------
MIN_MACOS="10.15"
MIN_IOS="11.0"
CXX=clang++
STD='-std=c++17'
SRC="mace_c_api.cpp"
INCLUDES=( -Iinclude -Iinclude/bose )
STATIC_DIR="lib"
BUILD="build"
FW="MaceAPI"
MAC_FW=( CoreFoundation Foundation CoreServices AppKit )

# clean
rm -rf "${BUILD}"
mkdir -p "${BUILD}/macos/arm64" "${BUILD}/ios/arm64"

# Build macOS arm64 dylib
OUT_MAC="${BUILD}/macos/arm64/lib${FW}.dylib"
echo "Building macOS arm64..."
"${CXX}" ${STD} -dynamiclib \
  -arch arm64 \
  -mmacosx-version-min="${MIN_MACOS}" \
  -isysroot "$(xcrun --sdk macosx --show-sdk-path)" \
  "${INCLUDES[@]}" \
  "${SRC}" \
  "${STATIC_DIR}/macos/arm64/libMACE.a" \
  -Wl,-force_load,"${STATIC_DIR}/macos/arm64/libMACE.a" \
  -install_name "@rpath/lib${FW}.dylib" \
  -o "${OUT_MAC}" \
  $(printf -- '-framework %s ' "${MAC_FW[@]}")
echo "  ⇢ ${OUT_MAC}"

# copy up for easy dlopen
cp "${OUT_MAC}" "${BUILD}/lib${FW}.dylib"
echo "✅ macOS arm64 dylib: ${BUILD}/lib${FW}.dylib"

# Build iOS arm64 dylib
SDK=iphoneos
SDK_PATH=$(xcrun --sdk ${SDK} --show-sdk-path)

OUT_IOS="${BUILD}/ios/arm64/lib${FW}.dylib"
echo "Building iOS arm64..."
"${CXX}" ${STD} \
  "${INCLUDES[@]}" \
  -dynamiclib \
  -arch arm64 \
  -miphoneos-version-min="${MIN_IOS}" \
  -isysroot "${SDK_PATH}" \
  "${SRC}" \
  "${STATIC_DIR}/ios/arm64/libMACE.a" \
  -Wl,-force_load,"${STATIC_DIR}/ios/arm64/libMACE.a" \
  -install_name "@rpath/${FW}.framework/${FW}" \
  -o "${OUT_IOS}" \
  -framework Foundation \
  -framework CoreFoundation

echo "  ⇢ ${OUT_IOS}"

# copy up for easy dlopen
cp "${OUT_IOS}" "${BUILD}/lib${FW}_ios.dylib"
echo "✅ iOS arm64 dylib: ${BUILD}/lib${FW}_ios.dylib"

# Wrap iOS dylib into a Framework
FRAMEWORK_DIR="${BUILD}/${FW}.framework"

# remove old framework if it exists
rm -rf "${FRAMEWORK_DIR}"

# create framework structure
mkdir -p "${FRAMEWORK_DIR}/Headers"

# copy binary (rename to framework name)
cp "${BUILD}/lib${FW}_ios.dylib" \
   "${FRAMEWORK_DIR}/${FW}"

# copy public headers
cp "include/bose/MACE.h" \
   "${FRAMEWORK_DIR}/Headers/"

# create module.modulemap
mkdir -p "${FRAMEWORK_DIR}/Modules"
cat > "${FRAMEWORK_DIR}/Modules/module.modulemap" <<EOF
framework module ${FW} {
  umbrella header "MACE.h"
  export *
  module * { export * }
}
EOF

# create Info.plist
cat > "${FRAMEWORK_DIR}/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundlePackageType</key>
  <string>FMWK</string>
  <!-- Must match the binary’s filename inside the .framework -->
  <key>CFBundleExecutable</key>
  <string>MaceAPI</string>
  <key>CFBundleName</key>
  <string>${FW}</string>
  <key>CFBundleIdentifier</key>
  <string>com.bosepro.${FW}</string>
  <key>CFBundleVersion</key>
  <string>1.0.0</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  <key>CFBundleSupportedPlatforms</key>
  <array>
    <string>iPhoneOS</string>
  </array>
</dict>
</plist>
EOF

echo "✅ iOS Framework created at: ${FRAMEWORK_DIR}"
