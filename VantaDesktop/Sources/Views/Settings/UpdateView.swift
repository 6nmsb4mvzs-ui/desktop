import SwiftUI

struct UpdateView: View {
    @EnvironmentObject var updateManager: UpdateManager

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                currentVersionSection
                if updateManager.updateAvailable {
                    updateAvailableSection
                }
                checkSection
            }
            .padding(24)
        }
        .navigationTitle("Updates")
    }

    private var currentVersionSection: some View {
        GroupBox {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("VantaDesktop")
                        .font(.headline)
                    Text("Version \(updateManager.currentVersion)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if updateManager.updateAvailable {
                    Label("Update Available", systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                } else {
                    Label("Up to Date", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }
            .padding(4)
        } label: {
            Label("Current Version", systemImage: "info.circle")
        }
    }

    private var updateAvailableSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Version \(updateManager.latestVersion)")
                            .font(.title3.bold())
                        Text("A new version is available")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Download Update") {
                        updateManager.downloadUpdate()
                    }
                    .buttonStyle(.borderedProminent)
                }

                if !updateManager.releaseNotes.isEmpty {
                    Divider()
                    Text("Release Notes")
                        .font(.subheadline.bold())
                    Text(updateManager.releaseNotes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
            .padding(4)
        } label: {
            Label("New Version", systemImage: "arrow.down.circle")
        }
    }

    private var checkSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Automatically check for updates", isOn: Binding(
                    get: { updateManager.autoCheckEnabled },
                    set: { updateManager.setAutoCheck($0) }
                ))

                if let lastChecked = updateManager.lastChecked {
                    Text("Last checked: \(lastChecked.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                HStack {
                    Button("Check for Updates") {
                        updateManager.checkForUpdates()
                    }
                    .disabled(updateManager.isChecking)

                    if updateManager.isChecking {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Spacer()

                    Button("View Releases on GitHub") {
                        updateManager.openReleasesPage()
                    }
                }
            }
            .padding(4)
        } label: {
            Label("Update Settings", systemImage: "gearshape")
        }
    }
}
