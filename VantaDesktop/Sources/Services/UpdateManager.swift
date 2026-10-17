import Foundation
import AppKit
import Combine

@MainActor
class UpdateManager: ObservableObject {
    @Published var currentVersion: String = ""
    @Published var latestVersion: String = ""
    @Published var updateAvailable: Bool = false
    @Published var isChecking: Bool = false
    @Published var lastChecked: Date?
    @Published var releaseNotes: String = ""
    @Published var downloadURL: String = ""
    @Published var autoCheckEnabled: Bool = true

    private let repoOwner = "6nmsb4mvzs-ui"
    private let repoName = "desktop"
    private let configFile: URL
    private var checkTimer: Timer?

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("VantaDesktop", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        self.configFile = appDir.appendingPathComponent("update_config.json")

        currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        loadConfig()
        if autoCheckEnabled {
            scheduleAutoCheck()
        }
    }

    func checkForUpdates() {
        Task {
            await performUpdateCheck()
        }
    }

    func performUpdateCheck() async {
        isChecking = true
        defer { isChecking = false }

        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest"
        guard let url = URL(string: urlString) else { return }

        do {
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }

            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            latestVersion = release.tagName.replacingOccurrences(of: "v", with: "")
            releaseNotes = release.body ?? ""
            lastChecked = Date()

            if let asset = release.assets.first(where: { $0.name.hasSuffix(".dmg") || $0.name.hasSuffix(".zip") }) {
                downloadURL = asset.browserDownloadURL
            }

            updateAvailable = isNewer(latestVersion, than: currentVersion)
            saveConfig()
        } catch {
            print("Update check failed: \(error)")
        }
    }

    func downloadUpdate() {
        guard !downloadURL.isEmpty, let url = URL(string: downloadURL) else { return }
        NSWorkspace.shared.open(url)
    }

    func openReleasesPage() {
        guard let url = URL(string: "https://github.com/\(repoOwner)/\(repoName)/releases") else { return }
        NSWorkspace.shared.open(url)
    }

    private func isNewer(_ remote: String, than local: String) -> Bool {
        let remoteParts = remote.split(separator: ".").compactMap { Int($0) }
        let localParts = local.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(remoteParts.count, localParts.count) {
            let r = i < remoteParts.count ? remoteParts[i] : 0
            let l = i < localParts.count ? localParts[i] : 0
            if r > l { return true }
            if r < l { return false }
        }
        return false
    }

    private func scheduleAutoCheck() {
        checkTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performUpdateCheck()
            }
        }
    }

    func setAutoCheck(_ enabled: Bool) {
        autoCheckEnabled = enabled
        checkTimer?.invalidate()
        checkTimer = nil
        if enabled { scheduleAutoCheck() }
        saveConfig()
    }

    private func saveConfig() {
        let config = UpdateConfig(autoCheck: autoCheckEnabled, lastChecked: lastChecked)
        guard let data = try? JSONEncoder().encode(config) else { return }
        try? data.write(to: configFile)
    }

    private func loadConfig() {
        guard let data = try? Data(contentsOf: configFile),
              let config = try? JSONDecoder().decode(UpdateConfig.self, from: data) else { return }
        autoCheckEnabled = config.autoCheck
        lastChecked = config.lastChecked
    }
}

private struct UpdateConfig: Codable {
    let autoCheck: Bool
    let lastChecked: Date?
}

struct GitHubRelease: Codable {
    let tagName: String
    let name: String?
    let body: String?
    let assets: [GitHubAsset]
    let htmlURL: String

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name, body, assets
        case htmlURL = "html_url"
    }
}

struct GitHubAsset: Codable {
    let name: String
    let browserDownloadURL: String
    let size: Int

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
        case size
    }
}
