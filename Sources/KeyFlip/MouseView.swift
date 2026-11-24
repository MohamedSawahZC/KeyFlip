import AppKit
import SwiftUI

private let accessibilitySettings = URL(
    string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
)!

struct MouseView: View {
    @EnvironmentObject private var mouse: MouseModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Mouse").font(.title2.weight(.semibold))
                Text("Your trackpad keeps natural scrolling. Only mouse wheels with clicks change.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Toggle(isOn: Binding(get: { mouse.reverseWheel }, set: mouse.setReverseWheel)) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reverse scroll wheel").font(.headline)
                    Text("Wheel down scrolls the page down, like on Windows.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .card()

            if mouse.reverseWheel && !mouse.hasPermission {
                HStack {
                    Label("KeyFlip needs Accessibility access to change scrolling.", systemImage: "lock.fill")
                    Spacer()
                    Button("Open Settings") { NSWorkspace.shared.open(accessibilitySettings) }
                }
                .font(.callout)
                .padding(14)
                .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Toggle(isOn: Binding(get: { mouse.startsAtLogin }, set: mouse.setStartsAtLogin)) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Start at login").font(.headline)
                    Text("Scroll reversing works only while KeyFlip runs. Closing the window keeps it running.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .card()

            Spacer()

            if let message = mouse.errorMessage {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.red)
            }
        }
        .padding(28)
    }
}
