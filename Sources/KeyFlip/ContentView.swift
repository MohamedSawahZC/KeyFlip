import AppKit
import KeyFlipCore
import SwiftUI

private let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)
    .map { "v\($0)" } ?? "dev"

struct ContentView: View {
    @EnvironmentObject private var model: KeyboardsModel
    @EnvironmentObject private var mouse: MouseModel

    var body: some View {
        NavigationSplitView {
            List(selection: $model.selection) {
                Section("Keyboards") {
                    ForEach(model.keyboards) { keyboard in
                        Label(keyboard.name, systemImage: "keyboard").tag(keyboard.id)
                    }
                    if model.keyboards.isEmpty {
                        Text("None connected").foregroundStyle(.secondary)
                    }
                }
                Section("Mouse") {
                    Label("Scroll wheel", systemImage: "computermouse").tag(KeyboardsModel.mouseID)
                }
            }
            .navigationSplitViewColumnWidth(min: 190, ideal: 210)
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Button("Refresh", systemImage: "arrow.clockwise", action: model.refresh)
                        .buttonStyle(.borderless)
                    Spacer()
                    Text(appVersion)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
                .padding(10)
            }
        } detail: {
            if model.selection == KeyboardsModel.mouseID {
                MouseView()
            } else if let keyboard = model.selected {
                detail(for: keyboard)
            } else {
                ContentUnavailableView(
                    "No external keyboard",
                    systemImage: "keyboard.badge.ellipsis",
                    description: Text("Plug one in, then press Refresh.")
                )
            }
        }
        .frame(minWidth: 720, minHeight: 440)
        .onAppear(perform: model.refresh)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            model.refresh()
            mouse.refresh()
        }
    }

    private func detail(for keyboard: Keyboard) -> some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 4) {
                Text(keyboard.name).font(.title2.weight(.semibold))
                Text(String(format: "Vendor 0x%04X · Product 0x%04X", keyboard.vendorID, keyboard.productID))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            Toggle(isOn: Binding(
                get: { model.remap == .windows },
                set: { model.commit($0 ? .windows : .identity) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Windows layout").font(.headline)
                    Text("Alt works as ⌘ Command and Win as ⌥ Option, like a Mac keyboard.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .card()

            VStack(alignment: .leading, spacing: 16) {
                Text("Each key").font(.headline)
                HStack(spacing: 8) {
                    ForEach(ModKey.sources) { source in
                        KeycapView(source: source, target: model.remap[source]) { target in
                            model.set(target, for: source)
                        }
                    }
                }
            }

            Spacer()

            HStack {
                if let message = model.errorMessage {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                } else {
                    Label("Saved. Stays after restart and replug.", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Reset to default") { model.commit(.identity) }
                    .disabled(model.remap.isIdentity)
            }
            .font(.callout)
        }
        .padding(28)
    }
}

extension View {
    func card() -> some View {
        toggleStyle(.switch)
            .padding(16)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
