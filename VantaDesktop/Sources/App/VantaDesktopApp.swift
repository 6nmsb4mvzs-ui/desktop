import SwiftUI

@main
struct VantaDesktopApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var catalogueManager = CatalogueManager()
    @StateObject private var wallpaperService = WallpaperService()
    @StateObject private var dockManager = DockCustomizationManager()
    @StateObject private var menuBarManager = MenuBarCustomizationManager()
    @StateObject private var updateManager = UpdateManager()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(catalogueManager)
                .environmentObject(wallpaperService)
                .environmentObject(dockManager)
                .environmentObject(menuBarManager)
                .environmentObject(updateManager)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    updateManager.checkForUpdates()
                }
            }
        }

        Settings {
            SettingsView()
                .environmentObject(wallpaperService)
                .environmentObject(dockManager)
                .environmentObject(menuBarManager)
                .environmentObject(updateManager)
        }

        MenuBarExtra("VantaDesktop", systemImage: "display") {
            MenuBarView()
                .environmentObject(wallpaperService)
                .environmentObject(catalogueManager)
                .environmentObject(updateManager)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
