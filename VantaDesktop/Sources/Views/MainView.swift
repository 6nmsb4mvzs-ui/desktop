import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case catalogue = "Catalogue"
    case wallpaper = "Wallpaper"
    case dock = "Dock"
    case menuBar = "Menu Bar"
    case updates = "Updates"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .catalogue: return "photo.on.rectangle.angled"
        case .wallpaper: return "desktopcomputer"
        case .dock: return "dock.rectangle"
        case .menuBar: return "menubar.rectangle"
        case .updates: return "arrow.triangle.2.circlepath"
        }
    }
}

struct MainView: View {
    @State private var selectedItem: SidebarItem = .catalogue
    @EnvironmentObject var catalogueManager: CatalogueManager
    @EnvironmentObject var wallpaperService: WallpaperService
    @EnvironmentObject var dockManager: DockCustomizationManager
    @EnvironmentObject var menuBarManager: MenuBarCustomizationManager
    @EnvironmentObject var updateManager: UpdateManager

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selectedItem) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
            .listStyle(.sidebar)

            Divider()

            VStack(spacing: 8) {
                if wallpaperService.isActive, let current = wallpaperService.currentItem {
                    HStack(spacing: 8) {
                        Image(systemName: current.mediaType.icon)
                            .foregroundStyle(.secondary)
                        Text(current.name)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                }

                HStack(spacing: 12) {
                    Text("\(catalogueManager.items.count) items")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    if updateManager.updateAvailable {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption2)
                    }
                }
            }
            .padding(.bottom, 8)
        } detail: {
            switch selectedItem {
            case .catalogue:
                CatalogueView()
            case .wallpaper:
                WallpaperControlView()
            case .dock:
                DockCustomizationView()
            case .menuBar:
                MenuBarCustomizationView()
            case .updates:
                UpdateView()
            }
        }
    }
}

struct MenuBarView: View {
    @EnvironmentObject var wallpaperService: WallpaperService
    @EnvironmentObject var catalogueManager: CatalogueManager
    @EnvironmentObject var updateManager: UpdateManager

    var body: some View {
        VStack {
            if wallpaperService.isActive, let item = wallpaperService.currentItem {
                Text("Active: \(item.name)")
                    .font(.caption)
                Divider()
                Button("Pause") { wallpaperService.stopWallpaper() }
            } else {
                Text("No active wallpaper")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            if !catalogueManager.favoriteItems.isEmpty {
                Text("Favorites").font(.caption2).foregroundStyle(.secondary)
                ForEach(catalogueManager.favoriteItems.prefix(5)) { item in
                    Button(item.name) {
                        wallpaperService.setWallpaper(item: item)
                    }
                }
                Divider()
            }

            if updateManager.updateAvailable {
                Button("Update Available (\(updateManager.latestVersion))") {
                    updateManager.downloadUpdate()
                }
                Divider()
            }

            Button("Open VantaDesktop") {
                NSApp.activate(ignoringOtherApps: true)
            }
            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
        .padding(4)
    }
}
