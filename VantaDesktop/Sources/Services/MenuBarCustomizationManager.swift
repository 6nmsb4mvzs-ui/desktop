import Foundation
import AppKit
import Combine

@MainActor
class MenuBarCustomizationManager: ObservableObject {
    @Published var config: MenuBarConfiguration = .default
    @Published var hasChanges: Bool = false

    private let configFile: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("VantaDesktop", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        self.configFile = appDir.appendingPathComponent("menubar_config.json")
        loadCurrentSettings()
    }

    func loadCurrentSettings() {
        let menuExtras = UserDefaults(suiteName: "com.apple.menuextra.clock")

        config.autoHide = (UserDefaults(suiteName: "NSGlobalDomain")?.bool(forKey: "_HIHideMenuBar")) ?? false

        if let transparency = UserDefaults.standard.object(forKey: "AppleEnableMenuBarTransparency") as? Bool {
            config.transparency = transparency ? 1.0 : 0.5
        }

        config.showDate = menuExtras?.bool(forKey: "ShowDate") ?? true
        config.showDayOfWeek = menuExtras?.bool(forKey: "ShowDayOfWeek") ?? true
        config.use24HourClock = (menuExtras?.object(forKey: "DateFormat") as? String)?.contains("HH") ?? false
        config.flashDateSeparators = menuExtras?.bool(forKey: "FlashDateSeparators") ?? true
        config.showBatteryPercentage = (UserDefaults(suiteName: "com.apple.menuextra.battery")?.bool(forKey: "ShowPercent")) ?? true

        hasChanges = false
    }

    func applySettings() {
        writeDefault(domain: "NSGlobalDomain", key: "_HIHideMenuBar", boolValue: config.autoHide)
        writeDefault(domain: "NSGlobalDomain", key: "AppleEnableMenuBarTransparency", boolValue: config.transparency >= 0.8)

        if let tint = config.tintColor {
            let archiveData = try? NSKeyedArchiver.archivedData(
                withRootObject: NSColor(red: tint.red, green: tint.green, blue: tint.blue, alpha: tint.alpha),
                requiringSecureCoding: false
            )
            if let data = archiveData {
                UserDefaults(suiteName: "NSGlobalDomain")?.set(data, forKey: "AppleAccentColor")
            }
        }

        writeDefault(domain: "com.apple.menuextra.clock", key: "ShowDate", boolValue: config.showDate)
        writeDefault(domain: "com.apple.menuextra.clock", key: "ShowDayOfWeek", boolValue: config.showDayOfWeek)
        writeDefault(domain: "com.apple.menuextra.clock", key: "FlashDateSeparators", boolValue: config.flashDateSeparators)

        let format = config.use24HourClock ? "HH:mm" : "h:mm a"
        writeDefault(domain: "com.apple.menuextra.clock", key: "DateFormat", stringValue: format)

        writeDefault(domain: "com.apple.menuextra.battery", key: "ShowPercent", boolValue: config.showBatteryPercentage)

        restartSystemUI()
        hasChanges = false
        saveConfig()
    }

    func resetToDefaults() {
        config = .default
        applySettings()
    }

    private func writeDefault(domain: String, key: String, boolValue: Bool) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["write", domain, key, "-bool", boolValue ? "true" : "false"]
        try? process.run()
        process.waitUntilExit()
    }

    private func writeDefault(domain: String, key: String, stringValue: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["write", domain, key, "-string", stringValue]
        try? process.run()
        process.waitUntilExit()
    }

    private func restartSystemUI() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = ["SystemUIServer"]
        try? process.run()
        process.waitUntilExit()
    }

    private func saveConfig() {
        guard let data = try? JSONEncoder().encode(config) else { return }
        try? data.write(to: configFile)
    }
}
