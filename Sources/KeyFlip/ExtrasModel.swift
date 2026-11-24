import KeyFlipCore
import ServiceManagement
import SwiftUI

/// Features that run in the background while KeyFlip is open: scroll reversing, Alt+Shift and Alt+Tab.
@MainActor
final class ExtrasModel: ObservableObject {
    private static let reverseKey = "reverseMouseWheel"
    private static let altShiftKey = "altShiftSwitchesLanguage"
    private static let altTabKey = "altTabSwitchesApps"
    nonisolated private static let backgroundKey = "runInBackground"

    nonisolated static var runsInBackground: Bool { UserDefaults.standard.bool(forKey: backgroundKey) }

    @Published private(set) var reverseWheel = UserDefaults.standard.bool(forKey: reverseKey)
    @Published private(set) var altShiftSwitchesLanguage = UserDefaults.standard.bool(forKey: altShiftKey)
    @Published private(set) var altTabSwitchesApps = UserDefaults.standard.bool(forKey: altTabKey)
    @Published private(set) var hasPermission = EventTap.hasPermission
    @Published private(set) var runInBackground = runsInBackground
    @Published private(set) var startsAtLogin = SMAppService.mainApp.status == .enabled
    @Published private(set) var errorMessage: String?

    private let scrollTap = ScrollReverser.makeTap()
    private let languageTap = LanguageSwitcher.makeTap()
    private let appSwitchTap = AppSwitcher.makeTap()

    var needsPermission: Bool { (reverseWheel || altShiftSwitchesLanguage || altTabSwitchesApps) && !hasPermission }

    init() {
        sync()
    }

    func refresh() {
        hasPermission = EventTap.hasPermission
        startsAtLogin = SMAppService.mainApp.status == .enabled
        sync()
    }

    func setReverseWheel(_ on: Bool) {
        reverseWheel = on
        save(on, forKey: Self.reverseKey)
    }

    func setAltShiftSwitchesLanguage(_ on: Bool) {
        altShiftSwitchesLanguage = on
        save(on, forKey: Self.altShiftKey)
    }

    func setAltTabSwitchesApps(_ on: Bool) {
        altTabSwitchesApps = on
        save(on, forKey: Self.altTabKey)
    }

    func setRunInBackground(_ on: Bool) {
        runInBackground = on
        UserDefaults.standard.set(on, forKey: Self.backgroundKey)
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

    private func save(_ on: Bool, forKey key: String) {
        // 1) Ask macOS for Accessibility the first time a feature needs it
        if on && !hasPermission { EventTap.requestPermission() }

        // 2) Remember the choice and start or stop the listeners
        UserDefaults.standard.set(on, forKey: key)
        refresh()
    }

    private func sync() {
        toggle(scrollTap, on: reverseWheel && hasPermission)
        toggle(languageTap, on: altShiftSwitchesLanguage && hasPermission)
        toggle(appSwitchTap, on: altTabSwitchesApps && hasPermission)
    }

    private func toggle(_ tap: EventTap, on: Bool) {
        if on { tap.start() } else { tap.stop() }
    }
}
