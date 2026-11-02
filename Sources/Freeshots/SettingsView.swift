import SwiftUI
import ServiceManagement

private enum SettingsPane: String, CaseIterable, Identifiable {
    case general
    case appearance
    case shortcuts
    case permissions

    var id: Self { self }

    var title: String {
        switch self {
        case .general: "General"
        case .appearance: "Appearance"
        case .shortcuts: "Keyboard Shortcuts"
        case .permissions: "Permissions"
        }
    }

    var symbol: String {
        switch self {
        case .general: "gearshape"
        case .appearance: "paintpalette"
        case .shortcuts: "keyboard"
        case .permissions: "lock.shield"
        }
    }
}

struct SettingsView: View {
    @AppStorage("freeshots.settingsPane") private var selectedPane = SettingsPane.general.rawValue

    var body: some View {
        TabView(selection: $selectedPane) {
            GeneralSettingsPane()
                .tabItem { Label(SettingsPane.general.title, systemImage: SettingsPane.general.symbol) }
                .tag(SettingsPane.general.rawValue)

            AppearanceSettingsPane()
                .tabItem { Label(SettingsPane.appearance.title, systemImage: SettingsPane.appearance.symbol) }
                .tag(SettingsPane.appearance.rawValue)

            ShortcutSettingsPane()
                .tabItem { Label(SettingsPane.shortcuts.title, systemImage: SettingsPane.shortcuts.symbol) }
                .tag(SettingsPane.shortcuts.rawValue)

            PermissionSettingsPane()
                .tabItem { Label(SettingsPane.permissions.title, systemImage: SettingsPane.permissions.symbol) }
                .tag(SettingsPane.permissions.rawValue)
        }
        .frame(width: 560)
        .frame(minHeight: 600)
        .padding(20)
        .appAppearance()
    }
}

enum InterfaceAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: Self { self }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

private struct AppearanceSettingsPane: View {
    @AppStorage("freeshots.interfaceAppearance") private var selectedAppearance = InterfaceAppearance.system.rawValue

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Appearance", selection: $selectedAppearance) {
                    ForEach(InterfaceAppearance.allCases) { appearance in
                        Text(appearance.title).tag(appearance.rawValue)
                    }
                }
                .pickerStyle(.radioGroup)
            }
        }
        .formStyle(.grouped)
    }
}

private struct InterfaceAppearanceModifier: ViewModifier {
    @AppStorage("freeshots.interfaceAppearance") private var selectedAppearance = InterfaceAppearance.system.rawValue

    func body(content: Content) -> some View {
        content.preferredColorScheme(InterfaceAppearance(rawValue: selectedAppearance)?.colorScheme)
    }
}

extension View {
    func appAppearance() -> some View {
        modifier(InterfaceAppearanceModifier())
    }
}

private struct GeneralSettingsPane: View {
    @AppStorage("includeWindowShadow") private var includeWindowShadow = false
    @AppStorage("rememberLastScreenshot") private var rememberLastScreenshot = true
    @State private var loginItemStatus = SMAppService.mainApp.status
    @State private var loginItemError: String?

    var body: some View {
        Form {
            Section("Capture") {
                Toggle("Include Window Shadow", isOn: $includeWindowShadow)
                    .controlSize(.mini)
                Text("Add the macOS window shadow to window captures.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Editor") {
                Toggle("Remember Last Screenshot", isOn: $rememberLastScreenshot)
                    .controlSize(.mini)
                Text("Keep the most recent capture on this Mac so it can be reopened from the menu bar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Startup") {
                Toggle("Start Freeshots at Login", isOn: Binding(
                    get: { loginItemStatus == .enabled || loginItemStatus == .requiresApproval },
                    set: setLoginItemEnabled
                ))
                .controlSize(.mini)

                LabeledContent("Status", value: loginItemStatusDescription)

                if loginItemStatus == .requiresApproval {
                    Button("Open Login Items Settings") {
                        SMAppService.openSystemSettingsLoginItems()
                    }
                }

                if let loginItemError {
                    Text(loginItemError)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: rememberLastScreenshot) { _, enabled in
            if !enabled { UserDefaults.standard.removeObject(forKey: "lastScreenshot") }
        }
        .task { await pollLoginItemStatus() }
    }

    private func pollLoginItemStatus() async {
        while !Task.isCancelled {
            refreshLoginItemStatus()
            do {
                try await Task.sleep(for: .seconds(loginItemStatus == .requiresApproval ? 2 : 20))
            } catch {
                break
            }
        }
    }

    private var loginItemStatusDescription: String {
        switch loginItemStatus {
        case .notRegistered: "Not enabled"
        case .enabled: "Enabled"
        case .requiresApproval: "Approval required"
        case .notFound: "Unavailable"
        @unknown default: "Unknown"
        }
    }

    private func setLoginItemEnabled(_ enabled: Bool) {
        loginItemError = nil
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            refreshLoginItemStatus()
        } catch {
            refreshLoginItemStatus()
            loginItemError = "Unable to update the login item. \(error.localizedDescription) Try again."
        }
    }

    private func refreshLoginItemStatus() {
        loginItemStatus = SMAppService.mainApp.status
    }
}

private struct ShortcutSettingsPane: View {
    @Environment(HotkeyCenter.self) private var hotkeys
    @State private var recordingMode: CaptureMode?

    var body: some View {
        Form {
            Section("Keyboard Shortcuts") {
                ForEach(CaptureMode.allCases) { mode in
                    HStack {
                        Text(mode.title)
                        Spacer(minLength: 12)
                        VStack(alignment: .leading, spacing: 4) {
                            ShortcutCaptureField(
                                isRecording: recordingMode == mode,
                                binding: hotkeys.bindings[mode] ?? ShortcutBinding.defaults[mode]!,
                                onChange: { binding in
                                    hotkeys.set(binding, for: mode)
                                    if hotkeys.errors[mode] == nil { recordingMode = nil }
                                },
                                onCancel: { recordingMode = nil }
                            )
                            .frame(width: 150, height: 28)
                            .background(Ink.surface, in: RoundedRectangle(cornerRadius: 7))
                            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Ink.divider, lineWidth: 1))
                            if let error = hotkeys.errors[mode] {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        Button(recordingMode == mode ? "Listening…" : "Record") {
                            recordingMode = recordingMode == mode ? nil : mode
                        }
                        .buttonStyle(.borderless)
                        .frame(width: 82, alignment: .trailing)
                    }
                }
                Button("Restore Defaults") {
                    hotkeys.restoreDefaults()
                    recordingMode = nil
                }
            }
        }
        .formStyle(.grouped)
    }
}

private struct PermissionSettingsPane: View {
    @State private var screenRecordingAllowed = CGPreflightScreenCaptureAccess()

    var body: some View {
        Form {
            Section("Screen Recording") {
                Label(
                    screenRecordingAllowed ? "Screen Recording allowed" : "Screen Recording required",
                    systemImage: screenRecordingAllowed ? "checkmark.shield.fill" : "hand.raised.fill"
                )
                .foregroundStyle(screenRecordingAllowed ? Ink.accentText : Ink.warning)

                Button("Check Permissions Again") {
                    screenRecordingAllowed = CGPreflightScreenCaptureAccess()
                }
                if !screenRecordingAllowed {
                    Button("Open Screen Recording Settings") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .task { await pollScreenRecordingPermission() }
    }

    private func pollScreenRecordingPermission() async {
        while !Task.isCancelled {
            screenRecordingAllowed = CGPreflightScreenCaptureAccess()
            do {
                try await Task.sleep(for: .seconds(screenRecordingAllowed ? 20 : 2))
            } catch {
                break
            }
        }
    }
}
