#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP="VantaDesktop"
PKG_DIR="$APP"
BUILD_DIR=".build-app"
APP_BUNDLE="$BUILD_DIR/$APP.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

if ! swift --version &>/dev/null; then
    echo "Swift not found. Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "Run this again after the install finishes."
    exit 0
fi

echo "Building $APP..."
cd "$PKG_DIR"
swift build -c release 2>&1
BINARY=".build/release/$APP"

if [ ! -f "$BINARY" ]; then
    echo "Build failed."
    exit 1
fi

cd ..
echo "Packaging $APP.app..."

rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS" "$RESOURCES"

cp "$PKG_DIR/.build/release/$APP" "$MACOS/$APP"
cp "$PKG_DIR/Info.plist" "$CONTENTS/Info.plist"

if [ -d "$PKG_DIR/Resources/Assets.xcassets" ]; then
    cp -R "$PKG_DIR/Resources/Assets.xcassets" "$RESOURCES/" 2>/dev/null || true
fi

echo "Launching..."
open "$APP_BUNDLE"
echo ""
echo "$APP is running."
echo "App bundle: $APP_BUNDLE"
