import AppKit
import KeyFlipCore
import SwiftUI

@main
struct KeyFlipApp: App {
    static let mainWindowID = "main"

    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @StateObject private var keyboards = KeyboardsModel()
    @StateObject private var extras = ExtrasModel()

    var body: some Scene {
        Window("KeyFlip", id: Self.mainWindowID) {
            ContentView()
                .environmentObject(keyboards)
                .environmentObject(extras)
        }
        .windowResizability(.contentSize)

        MenuBarExtra("KeyFlip", systemImage: "keyboard") {
            MenuBarMenu().environmentObject(extras)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1) In background mode, start with no Dock icon and no window
        guard ExtrasModel.runsInBackground else { return }
        NSApp.setActivationPolicy(.accessory)
        DispatchQueue.main.async { NSApp.windows.filter(\.isMainWindowCandidate).forEach { $0.close() } }

        // 2) Hide the Dock icon again whenever the window closes
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification, object: nil, queue: .main
        ) { note in
            guard ExtrasModel.runsInBackground, (note.object as? NSWindow)?.isMainWindowCandidate == true else { return }
            NSApp.setActivationPolicy(.accessory)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

private extension NSWindow {
    var isMainWindowCandidate: Bool { identifier?.rawValue.hasPrefix(KeyFlipApp.mainWindowID) == true }
}

private struct MenuBarMenu: View {
    @EnvironmentObject private var extras: ExtrasModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Open KeyFlip") {
            NSApp.setActivationPolicy(.regular)
            openWindow(id: KeyFlipApp.mainWindowID)
            NSApp.activate()
        }
        Divider()
        Toggle("Reverse scroll wheel", isOn: Binding(get: { extras.reverseWheel }, set: extras.setReverseWheel))
        Toggle(
            "Alt + Shift switches language",
            isOn: Binding(get: { extras.altShiftSwitchesLanguage }, set: extras.setAltShiftSwitchesLanguage)
        )
        Divider()
        Button("Quit KeyFlip") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}

@MainActor
final class KeyboardsModel: ObservableObject {
    static let mouseID = "mouse"
    static let languageID = "language"

    @Published private(set) var keyboards: [Keyboard] = []
    @Published var selection: Keyboard.ID? {
        didSet { load() }
    }
    @Published private(set) var remap = Remap.identity
    @Published private(set) var errorMessage: String?

    var selected: Keyboard? { keyboards.first { $0.id == selection } }

    func refresh() {
        // 1) Re-read connected keyboards
        keyboards = connectedKeyboards()

        // 2) Drop a selection that was unplugged, pick the first one instead
        if selection == Self.mouseID || selection == Self.languageID { return }
        if selected == nil { selection = keyboards.first?.id ?? Self.mouseID } else { load() }
    }

    func set(_ target: ModKey, for source: ModKey) {
        var next = remap
        next[source] = target
        commit(next)
    }

    func commit(_ next: Remap) {
        guard let keyboard = selected else { return }
        do {
            try apply(next, to: keyboard)
            remap = next
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func load() {
        remap = selected.map(savedRemap(for:)) ?? .identity
        errorMessage = nil
    }
}
