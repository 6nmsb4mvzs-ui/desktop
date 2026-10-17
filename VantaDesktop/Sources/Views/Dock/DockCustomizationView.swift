import SwiftUI

struct DockCustomizationView: View {
    @EnvironmentObject var dockManager: DockCustomizationManager

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                dockPreview
                sizeSection
                positionSection
                behaviorSection
                effectsSection
                actionsSection
            }
            .padding(24)
        }
        .navigationTitle("Dock")
    }

    private var dockPreview: some View {
        GroupBox {
            VStack(spacing: 8) {
                DockPreviewView(config: dockManager.config)
                    .frame(height: 80)
                    .padding(.vertical, 8)
                Text("Live Preview")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(4)
        } label: {
            Label("Preview", systemImage: "eye")
        }
    }

    private var sizeSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Icon Size")
                    Slider(value: $dockManager.config.tileSize, in: 16...128, step: 1) { _ in
                        dockManager.hasChanges = true
                    }
                    Text("\(Int(dockManager.config.tileSize))px")
                        .monospacedDigit()
                        .frame(width: 50)
                }

                Toggle("Magnification", isOn: $dockManager.config.magnification)
                    .onChange(of: dockManager.config.magnification) { _ in
                        dockManager.hasChanges = true
                    }

                if dockManager.config.magnification {
                    HStack {
                        Text("Magnification Size")
                        Slider(value: $dockManager.config.magnificationSize, in: 32...256, step: 1) { _ in
                            dockManager.hasChanges = true
                        }
                        Text("\(Int(dockManager.config.magnificationSize))px")
                            .monospacedDigit()
                            .frame(width: 50)
                    }
                }
            }
            .padding(4)
        } label: {
            Label("Size", systemImage: "arrow.up.left.and.arrow.down.right")
        }
    }

    private var positionSection: some View {
        GroupBox {
            Picker("Position", selection: $dockManager.config.position) {
                ForEach(DockPosition.allCases, id: \.self) { position in
                    Text(position.displayName).tag(position)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: dockManager.config.position) { _ in
                dockManager.hasChanges = true
            }
            .padding(4)
        } label: {
            Label("Position", systemImage: "rectangle.bottomhalf.inset.filled")
        }
    }

    private var behaviorSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Automatically hide and show the Dock", isOn: $dockManager.config.autohide)
                Toggle("Show recent applications", isOn: $dockManager.config.showRecents)
                Toggle("Show indicators for open applications", isOn: $dockManager.config.showIndicators)
                Toggle("Minimize windows into application icon", isOn: $dockManager.config.minimizeToAppIcon)
            }
            .onChange(of: dockManager.config.autohide) { _ in dockManager.hasChanges = true }
            .onChange(of: dockManager.config.showRecents) { _ in dockManager.hasChanges = true }
            .onChange(of: dockManager.config.showIndicators) { _ in dockManager.hasChanges = true }
            .onChange(of: dockManager.config.minimizeToAppIcon) { _ in dockManager.hasChanges = true }
            .padding(4)
        } label: {
            Label("Behavior", systemImage: "gearshape")
        }
    }

    private var effectsSection: some View {
        GroupBox {
            Picker("Minimize Effect", selection: $dockManager.config.minimizeEffect) {
                ForEach(MinimizeEffect.allCases, id: \.self) { effect in
                    Text(effect.displayName).tag(effect)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: dockManager.config.minimizeEffect) { _ in
                dockManager.hasChanges = true
            }
            .padding(4)
        } label: {
            Label("Effects", systemImage: "sparkles")
        }
    }

    private var actionsSection: some View {
        HStack {
            Button("Reset to Defaults") {
                dockManager.resetToDefaults()
            }

            Spacer()

            Button("Reload from System") {
                dockManager.loadCurrentDockSettings()
            }

            Button("Apply Changes") {
                dockManager.applyDockSettings()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!dockManager.hasChanges)
        }
    }
}

struct DockPreviewView: View {
    let config: DockConfiguration

    var body: some View {
        GeometryReader { geometry in
            let previewWidth = min(geometry.size.width * 0.7, 500)
            let iconSize = config.tileSize * 0.5

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .frame(width: previewWidth, height: iconSize + 16)

                HStack(spacing: iconSize * 0.3) {
                    ForEach(0..<8, id: \.self) { i in
                        RoundedRectangle(cornerRadius: iconSize * 0.2)
                            .fill(previewColors[i % previewColors.count])
                            .frame(width: iconSize, height: iconSize)
                    }

                    if config.showRecents {
                        Divider()
                            .frame(height: iconSize * 0.6)
                        ForEach(0..<2, id: \.self) { i in
                            RoundedRectangle(cornerRadius: iconSize * 0.2)
                                .fill(.tertiary)
                                .frame(width: iconSize, height: iconSize)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private let previewColors: [Color] = [
        .blue, .red, .green, .orange, .purple, .cyan, .pink, .yellow
    ]
}
