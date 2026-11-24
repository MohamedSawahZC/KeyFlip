import AppKit
import KeyFlipCore
import SwiftUI

@main
struct KeyFlipApp: App {
    @StateObject private var keyboards = KeyboardsModel()
    @StateObject private var mouse = MouseModel()

    var body: some Scene {
        WindowGroup("KeyFlip") {
            ContentView()
                .environmentObject(keyboards)
                .environmentObject(mouse)
        }
        .windowResizability(.contentSize)
    }
}

@MainActor
final class KeyboardsModel: ObservableObject {
    static let mouseID = "mouse"

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
        if selection == Self.mouseID { return }
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
