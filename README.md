# KeyFlip

Use a Windows keyboard on your Mac with one click. Pick **Ctrl is ⌘** to keep your Windows habits (Ctrl+C, Ctrl+V, Ctrl+A), or **Alt is ⌘** to match a Mac keyboard. You can also remap Caps Lock, Ctrl, Alt and Win per keyboard.

It also fixes the reversed mouse wheel without touching your trackpad. Free and native SwiftUI.

## Install

1. Download `KeyFlip-<version>.pkg` from [Releases](../../releases).
2. Open it. macOS blocks it the first time because the build has no Apple Developer signature.
3. Go to **System Settings → Privacy & Security**, scroll down, click **Open Anyway**, and finish the installer.
4. Open **KeyFlip** from Applications.

## Use

1. Pick your keyboard in the sidebar.
2. Pick a layout:
   - **Ctrl is ⌘**: Ctrl+C, Ctrl+V, Ctrl+A and Ctrl+Z work like on Windows. Win becomes Control.
   - **Alt is ⌘**: the key next to the space bar acts as ⌘, like on a Mac keyboard.
   - **No change**: macOS defaults.
3. Or click the menu under any key and pick what it should do: Caps Lock, Control, Option, Command, Escape, or No action.

Changes apply the moment you pick them. KeyFlip saves them in the same place as **System Settings → Keyboard → Keyboard Shortcuts → Modifier Keys**, so they survive restarts and replugging, and you can quit the app. **Reset to default** clears them.

KeyFlip lists external keyboards only. It hides gaming mice that pretend to be keyboards, and leaves your Mac's built-in keyboard to System Settings.

## Mouse

Open **Mouse** in the KeyFlip sidebar. Every option leaves your trackpad and Magic Mouse alone.

- **Reverse scroll wheel**: macOS uses one natural-scrolling setting for trackpad and mouse, so a mouse wheel feels upside down. This flips clicking mouse wheels only.
- **Wheel speed**: 1× to 4× per wheel click.
- **Side buttons go back and forward**: the thumb buttons send ⌘[ and ⌘], which Chrome, Safari, Finder and most apps understand.

macOS asks for **Accessibility** access the first time. Allow it in **System Settings → Privacy & Security → Accessibility**. KeyFlip has to stay running for the mouse options and the Windows shortcuts. Turn on **Start at login** and **Run in background**: KeyFlip then lives in the menu bar (⌨ icon) with no Dock icon and no window at login.

Release builds have no Apple Developer signature, so macOS sees each new version as a different app. After an update, remove KeyFlip from the Accessibility list and allow it again. Builds you sign yourself (below) keep the permission.

## Windows shortcuts

With **Ctrl is ⌘**, your Ctrl key runs Mac shortcuts. Open **Windows shortcuts** in the KeyFlip sidebar for the rest of your Windows habits:

| Switch | Keys |
|---|---|
| Alt + Tab switches apps | Hold Alt, tap Tab, release to switch. Alt+Shift+Tab goes back. |
| Alt + Shift switches language | Press and release Alt and Shift together. |
| Windows text keys | Home / End: start or end of line. Ctrl+Home / End: top or bottom. Ctrl+← / →: word. Ctrl+↑ / ↓: paragraph. Ctrl+Backspace / Delete: whole word. Shift selects as usual. |
| Print Screen takes a screenshot | Opens the macOS Screenshot toolbar. |

Text keys expect the **Ctrl is ⌘** layout and apply to every keyboard, your Mac's built-in one included.

**Keep Ctrl as Ctrl in these apps**: add Terminal, a code editor or a game, and while that app is in front, your external keyboards go back to Mac defaults and the text keys pause. KeyFlip never touches your saved mapping for this, and it restores your keys when you switch away or quit.

The macOS language shortcut ⌃ Control + Space still works. With **Ctrl is ⌘**, you press it as Win + Space.

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

To keep Accessibility access across your own rebuilds, sign with a fixed certificate. Create a self-signed **Code Signing** certificate in Keychain Access (Certificate Assistant → Create a Certificate), then:

```sh
SIGN_IDENTITY="Your Certificate Name" scripts/package.sh
```

## Releasing

The `VERSION` file holds the version. To ship one:

1. Bump `VERSION` (for example to `1.1.0`) and push.
2. Tag it: `git tag v1.1.0 && git push origin v1.1.0`.

CI builds a `.pkg` on every push, marked `-dev.<commit>`. On a tag, CI checks the tag matches `VERSION` and attaches the `.pkg` to a GitHub Release. The app shows its version under the sidebar.

## License

MIT
