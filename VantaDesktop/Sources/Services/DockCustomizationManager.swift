import Foundation
import AppKit
import Combine

@MainActor
class DockCustomizationManager: ObservableObject {
    @Published var config: DockConfiguration = .default
    @Published var hasChanges: Bool = false

    private let configFile: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("VantaDesktop", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        self.configFile = appDir.appendingPathComponent("dock_config.json")
        loadCurrentDockSettings()
    }

    func loadCurrentDockSettings() {
        config.tileSize = readDockDefault("tilesize") as? Double ?? 48
        config.magnification = (readDockDefault("magnification") as? Bool) ?? true
        config.magnificationSize = readDockDefault("largesize") as? Double ?? 64
        config.autohide = (readDockDefault("autohide") as? Bool) ?? false
        config.showRecents = (readDockDefault("show-recents") as? Bool) ?? true
        config.showIndicators = (readDockDefault("show-process-indicators") as? Bool) ?? true
        config.minimizeToAppIcon = (readDockDefault("minimize-to-application") as? Bool) ?? false

        if let orientation = readDockDefault("orientation") as? String {
            config.position = DockPosition(rawValue: orientation) ?? .bottom
        }
        if let effect = readDockDefault("mineffect") as? String {
            config.minimizeEffect = MinimizeEffect(rawValue: effect) ?? .genie
        }

        hasChanges = false
    }

    func applyDockSettings() {
        writeDockDefault("tilesize", value: config.tileSize)
        writeDockDefault("magnification", value: config.magnification)
        writeDockDefault("largesize", value: config.magnificationSize)
        writeDockDefault("orientation", value: config.position.rawValue)
        writeDockDefault("mineffect", value: config.minimizeEffect.rawValue)
        writeDockDefault("autohide", value: config.autohide)
        writeDockDefault("show-recents", value: config.showRecents)
        writeDockDefault("show-process-indicators", value: config.showIndicators)
        writeDockDefault("minimize-to-application", value: config.minimizeToAppIcon)

        restartDock()
        hasChanges = false
        saveConfig()
    }

    func resetToDefaults() {
        config = .default
        applyDockSettings()
    }

    private func readDockDefault(_ key: String) -> Any? {
        UserDefaults(suiteName: "com.apple.dock")?.object(forKey: key)
    }

    private func writeDockDefault(_ key: String, value: Any) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["write", "com.apple.dock", key] + formatArgs(value)
        try? process.run()
        process.waitUntilExit()
    }

    private func formatArgs(_ value: Any) -> [String] {
        switch value {
        case let bool as Bool: return ["-bool", bool ? "true" : "false"]
        case let double as Double: return ["-float", "\(double)"]
        case let string as String: return ["-string", string]
        case let int as Int: return ["-int", "\(int)"]
        default: return ["\(value)"]
        }
    }

    private func restartDock() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = ["Dock"]
        try? process.run()
        process.waitUntilExit()
    }

    private func saveConfig() {
        guard let data = try? JSONEncoder().encode(config) else { return }
        try? data.write(to: configFile)
    }
}
