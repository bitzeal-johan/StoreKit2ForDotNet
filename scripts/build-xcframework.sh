#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
SWIFT_DIR="$ROOT_DIR/swift"
BUILD_DIR="$ROOT_DIR/.build-xcframework"
OUTPUT_DIR="$ROOT_DIR/binding/SK2ForDotNet.Binding"

SCHEME="SK2ForDotNet"
FRAMEWORK_NAME="SK2ForDotNet"

echo "=== Building SK2ForDotNet.xcframework ==="
echo "Swift source: $SWIFT_DIR"
echo "Output: $OUTPUT_DIR/$FRAMEWORK_NAME.xcframework"

rm -rf "$BUILD_DIR"
rm -rf "$OUTPUT_DIR/$FRAMEWORK_NAME.xcframework"
mkdir -p "$BUILD_DIR"

cd "$SWIFT_DIR"

COMMON_BUILD_SETTINGS=(
    SKIP_INSTALL=NO
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES
    DEFINES_MODULE=YES
    SWIFT_INSTALL_OBJC_HEADER=YES
    INSTALL_PATH=/usr/local/lib
    OTHER_SWIFT_FLAGS="-no-verify-emitted-module-interface"
)

# Build for iOS device (arm64)
echo ""
echo "=== Building for iOS device (arm64) ==="
xcodebuild archive \
    -scheme "$SCHEME" \
    -destination "generic/platform=iOS" \
    -archivePath "$BUILD_DIR/ios-device.xcarchive" \
    -derivedDataPath "$BUILD_DIR/derived" \
    "${COMMON_BUILD_SETTINGS[@]}"

# Build for iOS Simulator (arm64 + x86_64)
echo ""
echo "=== Building for iOS Simulator ==="
xcodebuild archive \
    -scheme "$SCHEME" \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "$BUILD_DIR/ios-simulator.xcarchive" \
    -derivedDataPath "$BUILD_DIR/derived" \
    "${COMMON_BUILD_SETTINGS[@]}"

# Locate the built frameworks
echo ""
echo "=== Locating built frameworks ==="
DEVICE_FW=$(find "$BUILD_DIR/ios-device.xcarchive" -name "$FRAMEWORK_NAME.framework" -type d | head -1)
SIM_FW=$(find "$BUILD_DIR/ios-simulator.xcarchive" -name "$FRAMEWORK_NAME.framework" -type d | head -1)

if [ -z "$DEVICE_FW" ] || [ -z "$SIM_FW" ]; then
    echo "ERROR: Could not find built frameworks"
    find "$BUILD_DIR" -name "*.framework" -type d
    exit 1
fi

echo "Device framework: $DEVICE_FW"
echo "Simulator framework: $SIM_FW"

# Check if Headers exist; if not, copy them from the build intermediates
for FW in "$DEVICE_FW" "$SIM_FW"; do
    if [ ! -d "$FW/Headers" ]; then
        echo "Headers missing in $FW, searching build intermediates..."
        HEADER_FILE=$(find "$BUILD_DIR" -path "*/Objects-normal/arm64/$FRAMEWORK_NAME-Swift.h" | head -1)
        MODULE_DIR=$(find "$BUILD_DIR" -path "*/$FRAMEWORK_NAME.swiftmodule" -type d | head -1)
        if [ -n "$HEADER_FILE" ]; then
            mkdir -p "$FW/Headers"
            cp "$HEADER_FILE" "$FW/Headers/$FRAMEWORK_NAME-Swift.h"
            echo "Copied header to $FW/Headers/"
        fi
        if [ -n "$MODULE_DIR" ] && [ ! -d "$FW/Modules" ]; then
            mkdir -p "$FW/Modules"
            cp -R "$MODULE_DIR" "$FW/Modules/"
            echo "Copied modules to $FW/Modules/"
        fi
    fi
done

echo ""
echo "=== Framework contents ==="
echo "Device:"
ls -la "$DEVICE_FW/" 2>/dev/null
ls -la "$DEVICE_FW/Headers/" 2>/dev/null || echo "(no Headers)"
echo ""
echo "Simulator:"
ls -la "$SIM_FW/" 2>/dev/null
ls -la "$SIM_FW/Headers/" 2>/dev/null || echo "(no Headers)"

# Create xcframework
echo ""
echo "=== Creating xcframework ==="
xcodebuild -create-xcframework \
    -framework "$DEVICE_FW" \
    -framework "$SIM_FW" \
    -output "$OUTPUT_DIR/$FRAMEWORK_NAME.xcframework"

# Clean up
rm -rf "$BUILD_DIR"

echo ""
echo "=== Done ==="
echo "XCFramework: $OUTPUT_DIR/$FRAMEWORK_NAME.xcframework"

# Show the generated ObjC header for verification
HEADER=$(find "$OUTPUT_DIR/$FRAMEWORK_NAME.xcframework" -name "$FRAMEWORK_NAME-Swift.h" | head -1)
if [ -n "$HEADER" ]; then
    echo ""
    echo "=== Generated ObjC Header ==="
    cat "$HEADER"
else
    echo ""
    echo "WARNING: No ObjC header found in xcframework"
fi
