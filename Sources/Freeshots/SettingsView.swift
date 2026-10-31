import SwiftUI

struct SettingsView: View {
    @Environment(HotkeyCenter.self) private var hotkeys
    @State private var recordingMode: CaptureMode?
    @State private var screenRecordingAllowed = CGPreflightScreenCaptureAccess()
    @AppStorage("rememberLastScreenshot") private var rememberLastScreenshot = true

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
            Section("Editor") {
                Toggle("Remember Last Screenshot", isOn: $rememberLastScreenshot)
                Text("Keep the most recent capture on this Mac so it can be reopened from the menu bar.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Privacy") {
                Label(
                    screenRecordingAllowed ? "Screen Recording allowed" : "Screen Recording required",
                    systemImage: screenRecordingAllowed ? "checkmark.shield.fill" : "hand.raised.fill"
                )
                .foregroundStyle(screenRecordingAllowed ? Ink.accentText : Ink.warning)
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
        .padding(20)
        .frame(width: 440)
        .onChange(of: rememberLastScreenshot) { _, enabled in
            if !enabled { UserDefaults.standard.removeObject(forKey: "lastScreenshot") }
        }
        .task {
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
}
