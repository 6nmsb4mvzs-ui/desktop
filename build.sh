#!/bin/bash
set -euo pipefail

APP_NAME="VantaDesktop"
PROJECT="$APP_NAME.xcodeproj"
BUILD_DIR="build"
APP_PATH="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"
INSTALL_PATH="/Applications/$APP_NAME.app"

usage() {
    echo "Usage: ./build.sh [command]"
    echo ""
    echo "  (no command)   Build and launch"
    echo "  install        Build, copy to /Applications, launch"
    echo "  uninstall      Remove from /Applications"
    echo "  clean          Remove build artifacts"
    echo ""
}

do_build() {
    echo "Building $APP_NAME..."
    xcodebuild \
        -project "$PROJECT" \
        -scheme "$APP_NAME" \
        -configuration Release \
        -derivedDataPath "$BUILD_DIR" \
        build 2>&1 | tail -3
    if [ ! -d "$APP_PATH" ]; then
        echo "Build failed."
        exit 1
    fi
    echo "Built: $APP_PATH"
}

do_install() {
    if [ -d "$INSTALL_PATH" ]; then
        rm -rf "$INSTALL_PATH"
    fi
    cp -R "$APP_PATH" "$INSTALL_PATH"
    echo "Installed to $INSTALL_PATH"
}

do_launch() {
    local target="$INSTALL_PATH"
    [ ! -d "$target" ] && target="$APP_PATH"
    open "$target"
}

case "${1:-}" in
    install)
        do_build
        do_install
        do_launch
        ;;
    uninstall)
        [ -d "$INSTALL_PATH" ] && rm -rf "$INSTALL_PATH" && echo "Removed $INSTALL_PATH" || echo "Not installed."
        ;;
    clean)
        rm -rf "$BUILD_DIR"
        echo "Cleaned."
        ;;
    help|-h|--help)
        usage
        ;;
    *)
        do_build
        do_launch
        ;;
esac
