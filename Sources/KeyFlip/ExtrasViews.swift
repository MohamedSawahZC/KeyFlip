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
            subtitle: "Your trackpad keeps natural scrolling. Only mouse wheels with clicks change."
        ) {
            Toggle(isOn: Binding(get: { extras.reverseWheel }, set: extras.setReverseWheel)) {
                ToggleLabel(title: "Reverse scroll wheel", detail: "Wheel down scrolls the page down, like on Windows.")
            }
            .card()
        }
    }
}

struct ShortcutsView: View {
    @EnvironmentObject private var extras: ExtrasModel

    var body: some View {
        ExtrasPage(
            title: "Windows shortcuts",
            subtitle: "Keep your Windows muscle memory for switching apps and languages."
        ) {
            Toggle(
                isOn: Binding(get: { extras.altShiftSwitchesLanguage }, set: extras.setAltShiftSwitchesLanguage)
            ) {
                ToggleLabel(
                    title: "Alt + Shift switches language",
                    detail: "Press and release ⌥ Option and ⇧ Shift together to jump to the next language."
                )
            }
            .card()

            Toggle(isOn: Binding(get: { extras.altTabSwitchesApps }, set: extras.setAltTabSwitchesApps)) {
                ToggleLabel(
                    title: "Alt + Tab switches apps",
                    detail: "Hold ⌥ Option, tap Tab to move through apps, release to switch. Shift goes back."
                )
            }
            .card()
        }
    }
}

private struct ExtrasPage<Content: View>: View {
    @EnvironmentObject private var extras: ExtrasModel

    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
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

            Toggle(isOn: Binding(get: { extras.startsAtLogin }, set: extras.setStartsAtLogin)) {
                ToggleLabel(
                    title: "Start at login",
                    detail: "These work only while KeyFlip runs. Closing the window keeps it running."
                )
            }
            .card()

            Toggle(isOn: Binding(get: { extras.runInBackground }, set: extras.setRunInBackground)) {
                ToggleLabel(
                    title: "Run in background",
                    detail: "No Dock icon, and no window at login. Open KeyFlip from the ⌨ icon in the menu bar."
                )
            }
            .card()

            Spacer()

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
