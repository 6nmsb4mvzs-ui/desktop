import SwiftUI
import AVKit

struct WallpaperControlView: View {
    @EnvironmentObject var wallpaperService: WallpaperService
    @EnvironmentObject var catalogueManager: CatalogueManager

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                currentWallpaperSection
                displaySettingsSection
                playbackSection
                performanceSection
            }
            .padding(24)
        }
        .navigationTitle("Wallpaper")
    }

    private var currentWallpaperSection: some View {
        GroupBox {
            VStack(spacing: 16) {
                if let item = wallpaperService.currentItem {
                    HStack(spacing: 16) {
                        wallpaperPreview(item: item)
                            .frame(width: 200, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.name)
                                .font(.title3.bold())
                            Label(item.mediaType.displayName, systemImage: item.mediaType.icon)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 8) {
                                if item.mediaType == .video {
                                    Button("Pause") {
                                        wallpaperService.teardownVideoWallpapers()
                                    }
                                    Button("Resume") {
                                        wallpaperService.resumePlayback()
                                    }
                                }
                                Button("Stop", role: .destructive) {
                                    wallpaperService.stopWallpaper()
                                }
                            }
                        }

                        Spacer()
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "desktopcomputer")
                            .font(.system(size: 40))
                            .foregroundStyle(.tertiary)
                        Text("No active wallpaper")
                            .foregroundStyle(.secondary)
                        Text("Choose one from the catalogue")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
            .padding(4)
        } label: {
            Label("Current Wallpaper", systemImage: "display")
        }
    }

    @ViewBuilder
    private func wallpaperPreview(item: CatalogueItem) -> some View {
        if let thumbURL = item.thumbnailURL, let image = NSImage(contentsOf: thumbURL) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Rectangle()
                .fill(.quaternary)
                .overlay {
                    Image(systemName: item.mediaType.icon)
                        .foregroundStyle(.tertiary)
                }
        }
    }

    private var displaySettingsSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Display Mode", selection: $wallpaperService.config.displayMode) {
                    ForEach(DisplayMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(4)
        } label: {
            Label("Display", systemImage: "aspectratio")
        }
    }

    private var playbackSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Speed")
                    Slider(value: $wallpaperService.config.playbackSpeed, in: 0.25...4.0, step: 0.25) { _ in
                        wallpaperService.updatePlaybackSpeed(wallpaperService.config.playbackSpeed)
                    }
                    Text("\(wallpaperService.config.playbackSpeed, specifier: "%.2f")x")
                        .monospacedDigit()
                        .frame(width: 50)
                }

                HStack {
                    Text("Volume")
                    Slider(value: $wallpaperService.config.volume, in: 0...1) { _ in
                        wallpaperService.updateVolume(wallpaperService.config.volume)
                    }
                    Image(systemName: wallpaperService.config.volume > 0 ? "speaker.wave.2" : "speaker.slash")
                        .frame(width: 20)
                }

                Toggle("Loop Video", isOn: $wallpaperService.config.loopVideo)
            }
            .padding(4)
        } label: {
            Label("Video Playback", systemImage: "play.circle")
        }
    }

    private var performanceSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Pause on battery power", isOn: $wallpaperService.config.pauseOnBattery)
                Toggle("Pause when windows cover desktop", isOn: $wallpaperService.config.pauseWhenInactive)
            }
            .padding(4)
        } label: {
            Label("Performance", systemImage: "bolt")
        }
    }
}
