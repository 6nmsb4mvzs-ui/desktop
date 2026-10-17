# VantaDesktop

A macOS desktop customization app — wallpaper engine, dock styling, menu bar mods, and a built-in media catalogue.

## Features

### Wallpaper Engine
- Set images, GIFs, and videos as your desktop wallpaper
- Videos play live on your desktop with full AVFoundation rendering
- Adjustable playback speed, volume, looping
- Display modes: fill, fit, stretch, center, tile
- Battery-aware — pauses video playback on battery power
- Multi-display support

### Media Catalogue
- Import images, GIFs, and videos into your personal library
- Auto-generated thumbnails for all media types
- Tag system for organization
- Collections for grouping related media
- Favorites for quick access
- Search and filter by media type

### Dock Customization
- Icon size and magnification controls
- Position: left, bottom, right
- Minimize effects: genie, scale, suck
- Toggle auto-hide, recent apps, process indicators
- Live preview of changes
- One-click apply with automatic Dock restart

### Menu Bar Customization
- Auto-hide toggle
- Transparency control
- Tint color picker
- Clock format: 12/24 hour, date, day of week
- Battery percentage toggle
- Live preview

### Auto-Updates
- Checks GitHub releases for new versions
- Download updates directly from the app
- Configurable automatic update checks (hourly)
- Release notes display

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0+ for building

## Build

### Xcode
1. Open `VantaDesktop.xcodeproj` in Xcode
2. Select the VantaDesktop scheme
3. Build and Run (Cmd+R)

### Command Line
```bash
./build.sh
```

The built app will be at `build/Build/Products/Release/VantaDesktop.app`.

## Architecture

```
VantaDesktop/
├── Sources/
│   ├── App/                    # App entry point, AppDelegate
│   ├── Models/                 # Data models (CatalogueItem, configurations)
│   ├── Services/               # Business logic
│   │   ├── CatalogueManager    # Media import, storage, thumbnails
│   │   ├── WallpaperService    # Desktop wallpaper rendering
│   │   ├── DockCustomization   # Dock defaults manipulation
│   │   ├── MenuBarCustomization # Menu bar defaults
│   │   └── UpdateManager       # GitHub release checking
│   └── Views/                  # SwiftUI views
│       ├── Catalogue/          # Media browser, detail view
│       ├── Wallpaper/          # Playback controls
│       ├── Dock/               # Dock + menu bar settings
│       └── Settings/           # App settings, updates
└── Resources/
    └── Assets.xcassets         # App icon, accent color
```

## How It Works

### Video Wallpapers
Video wallpapers are rendered using `AVQueuePlayer` with `AVPlayerLooper` for seamless looping. The video plays in a borderless `NSWindow` set to the desktop window level, positioned behind all other windows and across all Spaces.

### Dock Customization
Dock settings are read and written via `com.apple.dock` defaults domain using `UserDefaults` and the `defaults` CLI. After writing, the Dock process is restarted to apply changes.

### Menu Bar Customization
Menu bar settings are managed through `NSGlobalDomain` and `com.apple.menuextra.*` defaults domains. Changes restart SystemUIServer to take effect.

### Updates
The app checks the GitHub Releases API for `6nmsb4mvzs-ui/desktop`. When a new version tag is found, it compares semver with the current bundle version and offers a download link to the release asset (.dmg or .zip).

## License

MIT
