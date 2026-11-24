import AppKit
import SwiftUI

private let accessibilitySettings = URL(
    string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
)!

struct MouseView: View {
    @EnvironmentObject private var extras: ExtrasModel

    var body: some View {
        ExtrasPage(
            title: "Mouse",
            subtitle: "Your trackpad and Magic Mouse stay as they are. Only mice with clicking wheels change."
        ) {
            FeatureToggle(
                "Reverse scroll wheel", detail: "Wheel down scrolls the page down, like on Windows.",
                isOn: extras.reverseWheel, set: extras.setReverseWheel
            )

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ToggleLabel(title: "Wheel speed", detail: "How far one click of the wheel scrolls.")
                    Spacer()
                    Text(extras.wheelSpeed, format: .number.precision(.fractionLength(1)))
                        .font(.body.monospacedDigit()) + Text("×")
                }
                Slider(
                    value: Binding(get: { extras.wheelSpeed }, set: extras.setWheelSpeed),
                    in: 1...4, step: 0.5
                ) {
                    EmptyView()
                } minimumValueLabel: {
                    Text("1×").font(.caption)
                } maximumValueLabel: {
                    Text("4×").font(.caption)
                }
            }
            .card()

            FeatureToggle(
                "Side buttons go back and forward",
                detail: "The two thumb buttons go back and forward in Chrome, Safari, Finder and most apps.",
                isOn: extras.sideButtonsNavigate, set: extras.setSideButtonsNavigate
            )
        }
    }
}

struct ShortcutsView: View {
    @EnvironmentObject private var extras: ExtrasModel

    var body: some View {
        ExtrasPage(
            title: "Windows shortcuts",
            subtitle: "Keep your Windows muscle memory. Text keys expect the Ctrl is ⌘ layout."
        ) {
            FeatureToggle(
                "Alt + Tab switches apps",
                detail: "Hold Alt, tap Tab to move through apps, release to switch. Shift goes back.",
                isOn: extras.altTabSwitchesApps, set: extras.setAltTabSwitchesApps
            )
            FeatureToggle(
                "Alt + Shift switches language",
                detail: "Press and release Alt and Shift together to jump to the next language.",
                isOn: extras.altShiftSwitchesLanguage, set: extras.setAltShiftSwitchesLanguage
            )
            FeatureToggle(
                "Windows text keys",
                detail: "Home and End jump within the line. Ctrl + arrows jump by word, Ctrl + Backspace deletes a word. Applies to every keyboard.",
                isOn: extras.textEditing, set: extras.setTextEditing
            )
            FeatureToggle(
                "Print Screen takes a screenshot",
                detail: "Opens the macOS Screenshot toolbar to capture the screen, a window or an area.",
                isOn: extras.printScreen, set: extras.setPrintScreen
            )
            SkippedAppsCard()
        }
    }
}

private struct SkippedAppsCard: View {
    @EnvironmentObject private var extras: ExtrasModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ToggleLabel(
                title: "Keep Ctrl as Ctrl in these apps",
                detail: "While one of these is in front, your external keyboard and the text keys go back to Mac defaults."
            )
            ForEach(extras.skippedApps, id: \.self) { bundleID in
                HStack {
                    AppLabel(bundleID: bundleID)
                    Spacer()
                    Button("Remove", systemImage: "minus.circle") { extras.removeSkippedApp(bundleID: bundleID) }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                }
            }
            Button("Add App…", systemImage: "plus", action: pickApp)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func pickApp() {
        // 1) Let the user choose an app from Applications
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        guard panel.runModal() == .OK, let url = panel.url else { return }

        // 2) Store it by bundle identifier so moves and updates keep working
        if let bundleID = Bundle(url: url)?.bundleIdentifier { extras.addSkippedApp(bundleID: bundleID) }
    }
}

private struct AppLabel: View {
    let bundleID: String

    var body: some View {
        let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
        HStack(spacing: 8) {
            if let url {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
                    .frame(width: 20, height: 20)
            }
            Text(url.map { FileManager.default.displayName(atPath: $0.path) } ?? bundleID)
        }
    }
}

struct FeatureToggle: View {
    let title: String
    let detail: String
    let isOn: Bool
    let set: (Bool) -> Void

    init(_ title: String, detail: String, isOn: Bool, set: @escaping (Bool) -> Void) {
        self.title = title
        self.detail = detail
        self.isOn = isOn
        self.set = set
    }

    var body: some View {
        Toggle(isOn: Binding(get: { isOn }, set: set)) {
            ToggleLabel(title: title, detail: detail)
        }
        .card()
    }
}

private struct ExtrasPage<Content: View>: View {
    @EnvironmentObject private var extras: ExtrasModel

    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            page
        }
    }

    private var page: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.title2.weight(.semibold))
                Text(subtitle).font(.callout).foregroundStyle(.secondary)
            }

            content

            if extras.needsPermission {
                HStack {
                    Label("KeyFlip needs Accessibility access for this.", systemImage: "lock.fill")
                    Spacer()
                    Button("Open Settings") { NSWorkspace.shared.open(accessibilitySettings) }
                }
                .font(.callout)
                .padding(14)
                .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            FeatureToggle(
                "Start at login",
                detail: "These work only while KeyFlip runs. Closing the window keeps it running.",
                isOn: extras.startsAtLogin, set: extras.setStartsAtLogin
            )
            FeatureToggle(
                "Run in background",
                detail: "No Dock icon, and no window at login. Open KeyFlip from the ⌨ icon in the menu bar.",
                isOn: extras.runInBackground, set: extras.setRunInBackground
            )

            if let message = extras.errorMessage {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.red)
            }
        }
        .padding(28)
    }
}

struct ToggleLabel: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.headline)
            Text(detail).font(.callout).foregroundStyle(.secondary)
        }
    }
}
