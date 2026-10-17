import SwiftUI

struct MenuBarCustomizationView: View {
    @EnvironmentObject var menuBarManager: MenuBarCustomizationManager
    @State private var selectedTintColor: Color = .blue

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                menuBarPreview
                visibilitySection
                clockSection
                statusSection
                actionsSection
            }
            .padding(24)
        }
        .navigationTitle("Menu Bar")
    }

    private var menuBarPreview: some View {
        GroupBox {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 13))
                    Text("Finder")
                        .font(.system(size: 13, weight: .bold))
                    Text("File")
                        .font(.system(size: 13))
                    Text("Edit")
                        .font(.system(size: 13))
                    Text("View")
                        .font(.system(size: 13))
                }

                Spacer()

                HStack(spacing: 10) {
                    if menuBarManager.config.showBatteryPercentage {
                        HStack(spacing: 2) {
                            Text("87%")
                                .font(.system(size: 11))
                            Image(systemName: "battery.75")
                                .font(.system(size: 14))
                        }
                    }
                    Image(systemName: "wifi")
                        .font(.system(size: 12))

                    Text(formattedTime)
                        .font(.system(size: 13))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                menuBarManager.config.tintColor?.color.opacity(0.3) ?? Color.clear
            )
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .opacity(menuBarManager.config.transparency)
        } label: {
            Label("Preview", systemImage: "eye")
        }
    }

    private var formattedTime: String {
        var parts: [String] = []

        if menuBarManager.config.showDayOfWeek {
            parts.append("Wed")
        }
        if menuBarManager.config.showDate {
            parts.append("Oct 17")
        }

        let timePart = menuBarManager.config.use24HourClock ? "14:30" : "2:30 PM"
        parts.append(timePart)

        return parts.joined(separator: " ")
    }

    private var visibilitySection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Auto-hide menu bar", isOn: $menuBarManager.config.autoHide)
                    .onChange(of: menuBarManager.config.autoHide) { _ in
                        menuBarManager.hasChanges = true
                    }

                HStack {
                    Text("Transparency")
                    Slider(value: $menuBarManager.config.transparency, in: 0.2...1.0) { _ in
                        menuBarManager.hasChanges = true
                    }
                }

                HStack {
                    Text("Tint Color")
                    Spacer()
                    ColorPicker("", selection: $selectedTintColor)
                        .labelsHidden()
                        .onChange(of: selectedTintColor) { newColor in
                            let nsColor = NSColor(newColor)
                            menuBarManager.config.tintColor = CodableColor(color: nsColor)
                            menuBarManager.hasChanges = true
                        }

                    if menuBarManager.config.tintColor != nil {
                        Button("Clear") {
                            menuBarManager.config.tintColor = nil
                            menuBarManager.hasChanges = true
                        }
                        .font(.caption)
                    }
                }
            }
            .padding(4)
        } label: {
            Label("Appearance", systemImage: "paintbrush")
        }
    }

    private var clockSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Show date", isOn: $menuBarManager.config.showDate)
                Toggle("Show day of week", isOn: $menuBarManager.config.showDayOfWeek)
                Toggle("Use 24-hour clock", isOn: $menuBarManager.config.use24HourClock)
                Toggle("Flash time separators", isOn: $menuBarManager.config.flashDateSeparators)
            }
            .onChange(of: menuBarManager.config.showDate) { _ in menuBarManager.hasChanges = true }
            .onChange(of: menuBarManager.config.showDayOfWeek) { _ in menuBarManager.hasChanges = true }
            .onChange(of: menuBarManager.config.use24HourClock) { _ in menuBarManager.hasChanges = true }
            .onChange(of: menuBarManager.config.flashDateSeparators) { _ in menuBarManager.hasChanges = true }
            .padding(4)
        } label: {
            Label("Clock", systemImage: "clock")
        }
    }

    private var statusSection: some View {
        GroupBox {
            Toggle("Show battery percentage", isOn: $menuBarManager.config.showBatteryPercentage)
                .onChange(of: menuBarManager.config.showBatteryPercentage) { _ in
                    menuBarManager.hasChanges = true
                }
                .padding(4)
        } label: {
            Label("Status Items", systemImage: "battery.100")
        }
    }

    private var actionsSection: some View {
        HStack {
            Button("Reset to Defaults") {
                menuBarManager.resetToDefaults()
            }

            Spacer()

            Button("Reload from System") {
                menuBarManager.loadCurrentSettings()
            }

            Button("Apply Changes") {
                menuBarManager.applySettings()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!menuBarManager.hasChanges)
        }
    }
}
