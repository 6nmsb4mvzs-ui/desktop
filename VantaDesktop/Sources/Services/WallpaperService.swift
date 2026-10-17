import Foundation
import AppKit
import AVFoundation
import Combine

@MainActor
class WallpaperService: ObservableObject {
    @Published var config: WallpaperConfiguration = .default
    @Published var isActive: Bool = false
    @Published var currentItem: CatalogueItem?

    private var videoWindows: [NSScreen: NSWindow] = [:]
    private var players: [NSScreen: AVQueuePlayer] = [:]
    private var loopers: [NSScreen: AVPlayerLooper] = [:]
    private var powerObserver: NSObjectProtocol?
    private var spaceObserver: NSObjectProtocol?

    private let configFile: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("VantaDesktop", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        self.configFile = appDir.appendingPathComponent("wallpaper_config.json")
        loadConfig()
        setupPowerObserver()
    }

    func setWallpaper(item: CatalogueItem) {
        teardownVideoWallpapers()
        currentItem = item
        config.activeItemID = item.id

        switch item.mediaType {
        case .image:
            setStaticWallpaper(url: item.fileURL)
        case .gif:
            setAnimatedWallpaper(url: item.fileURL)
        case .video:
            setVideoWallpaper(url: item.fileURL)
        }

        isActive = true
        saveConfig()
    }

    func stopWallpaper() {
        teardownVideoWallpapers()
        isActive = false
        currentItem = nil
        config.activeItemID = nil
        saveConfig()
    }

    private func setStaticWallpaper(url: URL) {
        guard let screen = NSScreen.main else { return }
        do {
            try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: [
                .imageScaling: displayModeToScaling(config.displayMode),
                .allowClipping: true
            ])
        } catch {
            print("Failed to set wallpaper: \(error)")
        }
    }

    private func setAnimatedWallpaper(url: URL) {
        for screen in NSScreen.screens {
            let window = createDesktopWindow(for: screen)

            let imageView = NSImageView()
            imageView.animates = true
            imageView.imageScaling = .scaleProportionallyUpOrDown
            imageView.image = NSImage(contentsOf: url)
            imageView.frame = window.contentView!.bounds
            imageView.autoresizingMask = [.width, .height]

            window.contentView?.addSubview(imageView)
            window.orderBack(nil)
            videoWindows[screen] = window
        }
    }

    private func setVideoWallpaper(url: URL) {
        for screen in NSScreen.screens {
            let window = createDesktopWindow(for: screen)
            let playerItem = AVPlayerItem(url: url)
            let player = AVQueuePlayer(playerItem: playerItem)
            player.isMuted = config.volume == 0
            player.volume = Float(config.volume)
            player.rate = Float(config.playbackSpeed)

            if config.loopVideo {
                let templateItem = AVPlayerItem(url: url)
                let looper = AVPlayerLooper(player: player, templateItem: templateItem)
                loopers[screen] = looper
            }

            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = window.contentView!.bounds
            playerLayer.videoGravity = displayModeToGravity(config.displayMode)
            playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]

            window.contentView?.wantsLayer = true
            window.contentView?.layer?.addSublayer(playerLayer)
            window.orderBack(nil)

            player.play()
            players[screen] = player
            videoWindows[screen] = window
        }
    }

    private func createDesktopWindow(for screen: NSScreen) -> NSWindow {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.isOpaque = true
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.backgroundColor = .black
        window.contentView = NSView(frame: screen.frame)
        return window
    }

    func teardownVideoWallpapers() {
        for (_, player) in players {
            player.pause()
        }
        players.removeAll()
        loopers.removeAll()

        for (_, window) in videoWindows {
            window.orderOut(nil)
        }
        videoWindows.removeAll()
    }

    func updatePlaybackSpeed(_ speed: Double) {
        config.playbackSpeed = speed
        for (_, player) in players {
            player.rate = Float(speed)
        }
        saveConfig()
    }

    func updateVolume(_ volume: Double) {
        config.volume = volume
        for (_, player) in players {
            player.volume = Float(volume)
            player.isMuted = volume == 0
        }
        saveConfig()
    }

    private func setupPowerObserver() {
        powerObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.pausePlayback()
            }
        }
    }

    private func pausePlayback() {
        for (_, player) in players {
            player.pause()
        }
    }

    func resumePlayback() {
        for (_, player) in players {
            player.play()
            player.rate = Float(config.playbackSpeed)
        }
    }

    private func displayModeToScaling(_ mode: DisplayMode) -> NSImageScaling {
        switch mode {
        case .fill: return .scaleProportionallyUpOrDown
        case .fit: return .scaleProportionallyDown
        case .stretch: return .scaleAxesIndependently
        case .center: return .scaleNone
        case .tile: return .scaleNone
        }
    }

    private func displayModeToGravity(_ mode: DisplayMode) -> AVLayerVideoGravity {
        switch mode {
        case .fill: return .resizeAspectFill
        case .fit: return .resizeAspect
        case .stretch: return .resize
        case .center: return .resizeAspect
        case .tile: return .resizeAspect
        }
    }

    private func saveConfig() {
        guard let data = try? JSONEncoder().encode(config) else { return }
        try? data.write(to: configFile)
    }

    private func loadConfig() {
        guard let data = try? Data(contentsOf: configFile),
              let loaded = try? JSONDecoder().decode(WallpaperConfiguration.self, from: data) else { return }
        config = loaded
    }
}
