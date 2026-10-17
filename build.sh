#!/bin/bash
set -euo pipefail

PROJECT="VantaDesktop.xcodeproj"
SCHEME="VantaDesktop"
BUILD_DIR="build"
CONFIG="Release"

echo "Building VantaDesktop..."

xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIG" \
    -derivedDataPath "$BUILD_DIR" \
    build

APP_PATH="$BUILD_DIR/Build/Products/$CONFIG/VantaDesktop.app"

if [ -d "$APP_PATH" ]; then
    echo ""
    echo "Build succeeded."
    echo "App: $APP_PATH"
    echo ""
    echo "To run: open \"$APP_PATH\""
else
    echo "Build failed — app not found at $APP_PATH"
    exit 1
fi
