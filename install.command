#!/bin/bash
set -euo pipefail

APP="VantaDesktop"
REPO="https://github.com/6nmsb4mvzs-ui/desktop.git"
DIR="$HOME/.$APP"
BUILD="$DIR/build"
APP_PATH="$BUILD/Build/Products/Release/$APP.app"
INSTALLED="/Applications/$APP.app"

echo "$APP — installing..."

if ! xcode-select -p &>/dev/null; then
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "Run this script again after the install finishes."
    exit 0
fi

if [ -d "$DIR/.git" ]; then
    echo "Updating..."
    git -C "$DIR" pull --ff-only origin main
else
    echo "Downloading..."
    rm -rf "$DIR"
    git clone --depth 1 "$REPO" "$DIR"
fi

echo "Building..."
xcodebuild \
    -project "$DIR/$APP.xcodeproj" \
    -scheme "$APP" \
    -configuration Release \
    -derivedDataPath "$BUILD" \
    build 2>&1 | grep -E '(BUILD|error:)' || true

if [ ! -d "$APP_PATH" ]; then
    echo "Build failed."
    exit 1
fi

[ -d "$INSTALLED" ] && rm -rf "$INSTALLED"
cp -R "$APP_PATH" "$INSTALLED"

echo "Installed to $INSTALLED"
open "$INSTALLED"
