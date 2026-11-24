# KeyFlip

Use a Windows keyboard on your Mac with one switch. KeyFlip swaps Alt and Win so they sit where ⌘ and ⌥ sit on a Mac keyboard, and lets you remap Caps Lock, Ctrl, Alt and Win per keyboard.

It also fixes the reversed mouse wheel without touching your trackpad. Free and native SwiftUI.

## Install

1. Download `KeyFlip-<version>.pkg` from [Releases](../../releases).
2. Open it. macOS blocks it the first time because the build has no Apple Developer signature.
3. Go to **System Settings → Privacy & Security**, scroll down, click **Open Anyway**, and finish the installer.
4. Open **KeyFlip** from Applications.

## Use

1. Pick your keyboard in the sidebar.
2. Turn on **Windows layout** to swap Alt and Win.
3. Or click the menu under any key and pick what it should do: Caps Lock, Control, Option, Command, Escape, or No action.

Changes apply the moment you pick them. KeyFlip saves them in the same place as **System Settings → Keyboard → Keyboard Shortcuts → Modifier Keys**, so they survive restarts and replugging, and you can quit the app. **Reset to default** clears them.

KeyFlip lists external keyboards only. It hides gaming mice that pretend to be keyboards, and leaves your Mac's built-in keyboard to System Settings.

## Mouse scroll wheel

macOS uses one natural-scrolling setting for both trackpad and mouse, so a mouse wheel feels upside down. Open **Mouse → Scroll wheel** in KeyFlip and turn on **Reverse scroll wheel**. KeyFlip flips notched mouse wheels only, and your trackpad and Magic Mouse keep natural scrolling.

macOS asks for **Accessibility** access the first time. Allow it in **System Settings → Privacy & Security → Accessibility**. KeyFlip has to stay running for this one, so turn on **Start at login**. Closing the window keeps it running.

After you install a new version, remove KeyFlip from the Accessibility list and allow it again. Builds without an Apple Developer signature get a new identity each time.

## Switching input language

A Windows keyboard has no 🌐 key. Press **Ctrl + Space** to switch input language, or change the shortcut in **System Settings → Keyboard → Keyboard Shortcuts → Input Sources**.

## How it works

For each keyboard, KeyFlip writes `com.apple.keyboard.modifiermapping.<vendor>-<product>-0` to your user preferences and pushes the same mapping live with `/usr/bin/hidutil`. You can inspect it yourself:

```sh
defaults -currentHost read -g | grep -A12 modifiermapping
```

## Build from source

Needs macOS 14+ and Xcode 16.

```sh
swift test                  # run the tests
swift run KeyFlip           # run the app
scripts/package.sh 1.0.0    # build dist/KeyFlip-1.0.0.pkg
```

## Releasing

The `VERSION` file holds the version. To ship one:

1. Bump `VERSION` (for example to `1.1.0`) and push.
2. Tag it: `git tag v1.1.0 && git push origin v1.1.0`.

CI builds a `.pkg` on every push, marked `-dev.<commit>`. On a tag, CI checks the tag matches `VERSION` and attaches the `.pkg` to a GitHub Release. The app shows its version under the sidebar.

## License

MIT
