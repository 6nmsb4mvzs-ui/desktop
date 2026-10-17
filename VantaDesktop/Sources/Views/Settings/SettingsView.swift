import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var wallpaperService: WallpaperService
    @EnvironmentObject var dockManager: DockCustomizationManager
    @EnvironmentObject var menuBarManager: MenuBarCustomizationManager
    @EnvironmentObject var updateManager: UpdateManager

    var body: some View {
        TabView {
            GeneralSettingsTab()
                .environmentObject(wallpaperService)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            UpdateSettingsTab()
                .environmentObject(updateManager)
                .tabItem {
                    Label("Updates", systemImage: "arrow.triangle.2.circlepath")
                }

            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettingsTab: View {
    @EnvironmentObject var wallpaperService: WallpaperService
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                Toggle("Show menu bar icon", isOn: $showMenuBarIcon)
            }

            Section("Performance") {
                Toggle("Pause video wallpapers on battery", isOn: $wallpaperService.config.pauseOnBattery)
                Toggle("Pause when windows cover desktop", isOn: $wallpaperService.config.pauseWhenInactive)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct UpdateSettingsTab: View {
    @EnvironmentObject var updateManager: UpdateManager

    var body: some View {
        Form {
            Section("Automatic Updates") {
                Toggle("Check for updates automatically", isOn: Binding(
                    get: { updateManager.autoCheckEnabled },
                    set: { updateManager.setAutoCheck($0) }
                ))
            }

            Section("Current Version") {
                LabeledContent("Version", value: updateManager.currentVersion)
                if let lastChecked = updateManager.lastChecked {
                    LabeledContent("Last Checked", value: lastChecked.formatted(date: .abbreviated, time: .shortened))
                }
                Button("Check Now") {
                    updateManager.checkForUpdates()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "display")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("VantaDesktop")
                .font(.title2.bold())

            Text("Desktop Customization for macOS")
                .foregroundStyle(.secondary)

            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Link("View on GitHub", destination: URL(string: "https://github.com/6nmsb4mvzs-ui/desktop")!)
                .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
