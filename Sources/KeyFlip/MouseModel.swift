import KeyFlipCore
import ServiceManagement
import SwiftUI

@MainActor
final class MouseModel: ObservableObject {
    private static let reverseKey = "reverseMouseWheel"

    @Published private(set) var reverseWheel = UserDefaults.standard.bool(forKey: reverseKey)
    @Published private(set) var hasPermission = ScrollReverser.hasPermission
    @Published private(set) var startsAtLogin = SMAppService.mainApp.status == .enabled
    @Published private(set) var errorMessage: String?

    private let reverser = ScrollReverser()

    init() {
        sync()
    }

    func refresh() {
        hasPermission = ScrollReverser.hasPermission
        startsAtLogin = SMAppService.mainApp.status == .enabled
        sync()
    }

    func setReverseWheel(_ on: Bool) {
        // 1) Ask macOS for Accessibility the first time it is needed
        if on && !hasPermission { ScrollReverser.requestPermission() }

        // 2) Remember the choice and start or stop reversing
        reverseWheel = on
        UserDefaults.standard.set(on, forKey: Self.reverseKey)
        refresh()
    }

    func setStartsAtLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        refresh()
    }

    private func sync() {
        if reverseWheel && hasPermission { reverser.start() } else { reverser.stop() }
    }
}
