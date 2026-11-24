import AppKit
import KeyFlipCore
import ServiceManagement
import SwiftUI

/// Features that run in the background while KeyFlip is open: mouse tweaks and Windows shortcuts.
@MainActor
final class ExtrasModel: ObservableObject {
    private enum Key {
        static let reverseWheel = "reverseMouseWheel"
        static let wheelSpeed = "mouseWheelSpeed"
        static let sideButtons = "sideButtonsNavigate"
        static let altShift = "altShiftSwitchesLanguage"
        static let altTab = "altTabSwitchesApps"
        static let textEditing = "windowsTextEditing"
        static let printScreen = "printScreenOpensScreenshot"
        static let skippedApps = "skippedAppBundleIDs"
    }

    nonisolated private static let backgroundKey = "runInBackground"
    nonisolated static var runsInBackground: Bool { UserDefaults.standard.bool(forKey: backgroundKey) }

    private static let defaults = UserDefaults.standard

    @Published private(set) var reverseWheel = defaults.bool(forKey: Key.reverseWheel)
    @Published private(set) var wheelSpeed = max(1, defaults.double(forKey: Key.wheelSpeed))
    @Published private(set) var sideButtonsNavigate = defaults.bool(forKey: Key.sideButtons)
    @Published private(set) var altShiftSwitchesLanguage = defaults.bool(forKey: Key.altShift)
    @Published private(set) var altTabSwitchesApps = defaults.bool(forKey: Key.altTab)
    @Published private(set) var textEditing = defaults.bool(forKey: Key.textEditing)
    @Published private(set) var printScreen = defaults.bool(forKey: Key.printScreen)
    @Published private(set) var skippedApps = defaults.stringArray(forKey: Key.skippedApps) ?? []
    @Published private(set) var hasPermission = EventTap.hasPermission
    @Published private(set) var runInBackground = runsInBackground
    @Published private(set) var startsAtLogin = SMAppService.mainApp.status == .enabled
    @Published private(set) var errorMessage: String?

    private var skippedAppIsActive = false
    private var mouseTap: EventTap!
    private var windowsKeysTap: EventTap!
    private let languageTap = LanguageSwitcher.makeTap()
    private let appSwitchTap = AppSwitcher.makeTap()

    private var mouseOptions: MouseOptions {
        MouseOptions(reverseWheel: reverseWheel, wheelSpeed: wheelSpeed, sideButtonsNavigate: sideButtonsNavigate)
    }

    private var windowsKeysOptions: WindowsKeysOptions {
        WindowsKeysOptions(textEditing: textEditing && !skippedAppIsActive, printScreen: printScreen)
    }

    /// What the user switched on, before the skip list narrows it.
    private var chosenWindowsKeys: WindowsKeysOptions {
        WindowsKeysOptions(textEditing: textEditing, printScreen: printScreen)
    }

    var needsPermission: Bool {
        let anyOn = mouseOptions.changesAnything || chosenWindowsKeys.changesAnything
            || altShiftSwitchesLanguage || altTabSwitchesApps
        return anyOn && !hasPermission
    }

    init() {
        // 1) Taps read the latest settings on every event
        mouseTap = MouseTweaks.makeTap { [weak self] in
            MainActor.assumeIsolated { self?.mouseOptions } ?? MouseOptions(reverseWheel: false, wheelSpeed: 1, sideButtonsNavigate: false)
        }
        windowsKeysTap = WindowsKeys.makeTap { [weak self] in
            MainActor.assumeIsolated { self?.windowsKeysOptions } ?? WindowsKeysOptions(textEditing: false, printScreen: false)
        }

        // 2) Follow the frontmost app for the skip list, and restore keys on quit
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            MainActor.assumeIsolated { self?.frontmostAppChanged(to: app?.bundleIdentifier) }
        }
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.frontmostAppChanged(to: nil) }
        }

        // 3) Start whatever is already switched on
        sync()
    }

    func refresh() {
        hasPermission = EventTap.hasPermission
        startsAtLogin = SMAppService.mainApp.status == .enabled
        sync()
    }

    func setReverseWheel(_ on: Bool) { set(\.reverseWheel, on, key: Key.reverseWheel) }
    func setSideButtonsNavigate(_ on: Bool) { set(\.sideButtonsNavigate, on, key: Key.sideButtons) }
    func setAltShiftSwitchesLanguage(_ on: Bool) { set(\.altShiftSwitchesLanguage, on, key: Key.altShift) }
    func setAltTabSwitchesApps(_ on: Bool) { set(\.altTabSwitchesApps, on, key: Key.altTab) }
    func setTextEditing(_ on: Bool) { set(\.textEditing, on, key: Key.textEditing) }
    func setPrintScreen(_ on: Bool) { set(\.printScreen, on, key: Key.printScreen) }

    func setWheelSpeed(_ speed: Double) {
        wheelSpeed = speed
        Self.defaults.set(speed, forKey: Key.wheelSpeed)
        if speed != 1 && !hasPermission { EventTap.requestPermission() }
        refresh()
    }

    func addSkippedApp(bundleID: String) {
        guard !skippedApps.contains(bundleID) else { return }
        skippedApps.append(bundleID)
        Self.defaults.set(skippedApps, forKey: Key.skippedApps)
    }

    func removeSkippedApp(bundleID: String) {
        skippedApps.removeAll { $0 == bundleID }
        Self.defaults.set(skippedApps, forKey: Key.skippedApps)
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

    private func set(_ property: ReferenceWritableKeyPath<ExtrasModel, Bool>, _ on: Bool, key: String) {
        // 1) Ask macOS for Accessibility the first time a feature needs it
        if on && !hasPermission { EventTap.requestPermission() }

        // 2) Remember the choice and start or stop the listeners
        self[keyPath: property] = on
        Self.defaults.set(on, forKey: key)
        refresh()
    }

    private func frontmostAppChanged(to bundleID: String?) {
        // 1) Only act when moving into or out of a skipped app
        let skipped = bundleID.map(skippedApps.contains) ?? false
        guard skipped != skippedAppIsActive else { return }
        skippedAppIsActive = skipped

        // 2) Give skipped apps plain keys, everyone else the saved mapping
        do {
            for keyboard in connectedKeyboards() {
                let saved = savedRemap(for: keyboard)
                guard !saved.isIdentity else { continue }
                try applyLive(skipped ? .identity : saved, to: keyboard)
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func sync() {
        toggle(mouseTap, on: mouseOptions.changesAnything && hasPermission)
        toggle(windowsKeysTap, on: chosenWindowsKeys.changesAnything && hasPermission)
        toggle(languageTap, on: altShiftSwitchesLanguage && hasPermission)
        toggle(appSwitchTap, on: altTabSwitchesApps && hasPermission)
    }

    private func toggle(_ tap: EventTap, on: Bool) {
        if on { tap.start() } else { tap.stop() }
    }
}
