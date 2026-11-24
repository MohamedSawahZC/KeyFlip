import KeyFlipCore
import SwiftUI

extension ModKey {
    var symbol: String {
        switch self {
        case .capsLock: "⇪"
        case .control: "⌃"
        case .option: "⌥"
        case .command: "⌘"
        case .escape: "esc"
        case .noAction: "—"
        }
    }

    var title: String {
        switch self {
        case .capsLock: "Caps Lock"
        case .control: "Control"
        case .option: "Option"
        case .command: "Command"
        case .escape: "Escape"
        case .noAction: "No action"
        }
    }

    /// What the key is printed as on a Windows keyboard.
    var windowsLabel: String {
        switch self {
        case .capsLock: "Caps"
        case .control: "Ctrl"
        case .option: "Alt"
        case .command: "Win"
        case .escape: "Esc"
        case .noAction: ""
        }
    }
}

struct KeycapView: View {
    let source: ModKey
    let target: ModKey
    let onPick: (ModKey) -> Void

    private var isRemapped: Bool { source != target }

    var body: some View {
        VStack(spacing: 14) {
            keycap
            Image(systemName: "arrow.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(isRemapped ? Color.accentColor : Color.secondary.opacity(0.5))
            Menu {
                ForEach(ModKey.allCases) { key in
                    Button {
                        onPick(key)
                    } label: {
                        Text("\(key.symbol)  \(key.title)")
                    }
                }
            } label: {
                Text("\(target.symbol)  \(target.title)")
                    .font(.callout.weight(isRemapped ? .semibold : .regular))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .foregroundStyle(isRemapped ? Color.accentColor : Color.primary)
        }
        .frame(width: 112)
    }

    private var keycap: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(source.windowsLabel)
                .font(.system(size: 15, weight: .medium, design: .rounded))
            Spacer()
            HStack {
                Spacer()
                Text(source.symbol)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(width: 84, height: 72)
        .background {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.18), radius: 0, y: 3)
                .shadow(color: .black.opacity(0.08), radius: 6, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(isRemapped ? Color.accentColor : Color.primary.opacity(0.12), lineWidth: isRemapped ? 1.5 : 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(source.windowsLabel) key, acts as \(target.title)")
    }
}
