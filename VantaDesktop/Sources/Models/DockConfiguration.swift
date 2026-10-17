import Foundation
import SwiftUI

struct DockConfiguration: Codable {
    var tileSize: Double
    var magnification: Bool
    var magnificationSize: Double
    var position: DockPosition
    var minimizeEffect: MinimizeEffect
    var autohide: Bool
    var showRecents: Bool
    var showIndicators: Bool
    var minimizeToAppIcon: Bool

    static let `default` = DockConfiguration(
        tileSize: 48,
        magnification: true,
        magnificationSize: 64,
        position: .bottom,
        minimizeEffect: .genie,
        autohide: false,
        showRecents: true,
        showIndicators: true,
        minimizeToAppIcon: false
    )
}

enum DockPosition: String, Codable, CaseIterable {
    case left, bottom, right

    var displayName: String {
        rawValue.capitalized
    }
}

enum MinimizeEffect: String, Codable, CaseIterable {
    case genie, scale, suck

    var displayName: String {
        rawValue.capitalized
    }
}

struct MenuBarConfiguration: Codable {
    var autoHide: Bool
    var transparency: Double
    var tintColor: CodableColor?
    var showDate: Bool
    var showDayOfWeek: Bool
    var use24HourClock: Bool
    var flashDateSeparators: Bool
    var showBatteryPercentage: Bool

    static let `default` = MenuBarConfiguration(
        autoHide: false,
        transparency: 1.0,
        tintColor: nil,
        showDate: true,
        showDayOfWeek: true,
        use24HourClock: false,
        flashDateSeparators: true,
        showBatteryPercentage: true
    )
}

struct CodableColor: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    init(color: NSColor) {
        let converted = color.usingColorSpace(.sRGB) ?? color
        self.red = Double(converted.redComponent)
        self.green = Double(converted.greenComponent)
        self.blue = Double(converted.blueComponent)
        self.alpha = Double(converted.alphaComponent)
    }

    init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

struct WallpaperConfiguration: Codable {
    var activeItemID: UUID?
    var displayMode: DisplayMode
    var playbackSpeed: Double
    var volume: Double
    var loopVideo: Bool
    var pauseOnBattery: Bool
    var pauseWhenInactive: Bool

    static let `default` = WallpaperConfiguration(
        activeItemID: nil,
        displayMode: .fill,
        playbackSpeed: 1.0,
        volume: 0.0,
        loopVideo: true,
        pauseOnBattery: true,
        pauseWhenInactive: true
    )
}

enum DisplayMode: String, Codable, CaseIterable {
    case fill, fit, stretch, center, tile

    var displayName: String {
        rawValue.capitalized
    }
}
