// Renders the app icon master PNG: swift scripts/make-icon.swift <out.png>
import AppKit

let size: CGFloat = 1024
let output = CommandLine.arguments.dropFirst().first ?? "icon_1024.png"

func color(_ hex: UInt32) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: 1
    )
}

func draw(_ text: String, size fontSize: CGFloat, weight: NSFont.Weight, color textColor: NSColor, in rect: NSRect) {
    let font = NSFont.systemFont(ofSize: fontSize, weight: weight)
    let rounded = font.fontDescriptor.withDesign(.rounded).flatMap { NSFont(descriptor: $0, size: fontSize) } ?? font
    let attributes: [NSAttributedString.Key: Any] = [.font: rounded, .foregroundColor: textColor]
    let measured = (text as NSString).size(withAttributes: attributes)
    let origin = NSPoint(x: rect.midX - measured.width / 2, y: rect.midY - measured.height / 2)
    (text as NSString).draw(at: origin, withAttributes: attributes)
}

let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

// 1) Draw the squircle background on Apple's 824pt icon grid
let tile = NSRect(x: 100, y: 100, width: 824, height: 824)
let tilePath = NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185)
NSGraphicsContext.saveGraphicsState()
let tileShadow = NSShadow()
tileShadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
tileShadow.shadowOffset = NSSize(width: 0, height: -12)
tileShadow.shadowBlurRadius = 28
tileShadow.set()
color(0x1B2540).setFill()
tilePath.fill()
NSGraphicsContext.restoreGraphicsState()
NSGradient(starting: color(0x2C3B63), ending: color(0x111829))?.draw(in: tilePath, angle: -90)

// 2) Draw the keycap body, a darker skirt under a lighter top face
let skirt = NSRect(x: 262, y: 236, width: 500, height: 500)
NSGraphicsContext.saveGraphicsState()
let capShadow = NSShadow()
capShadow.shadowColor = NSColor.black.withAlphaComponent(0.45)
capShadow.shadowOffset = NSSize(width: 0, height: -18)
capShadow.shadowBlurRadius = 36
capShadow.set()
color(0xBDB6A8).setFill()
NSBezierPath(roundedRect: skirt, xRadius: 92, yRadius: 92).fill()
NSGraphicsContext.restoreGraphicsState()

let face = NSRect(x: 292, y: 296, width: 440, height: 420)
let facePath = NSBezierPath(roundedRect: face, xRadius: 70, yRadius: 70)
NSGradient(starting: color(0xFBF8F1), ending: color(0xE4DED2))?.draw(in: facePath, angle: -90)

// 3) Print the legends: the old Alt label small, the Mac command glyph large
draw("alt", size: 64, weight: .semibold, color: color(0x9A9384),
     in: NSRect(x: face.minX + 30, y: face.maxY - 110, width: 130, height: 90))
draw("⌘", size: 250, weight: .medium, color: color(0x1B2540),
     in: NSRect(x: face.minX, y: face.minY + 10, width: face.width, height: face.height - 40))

// 4) Add the flip accent in the corner of the tile
let badge = NSRect(x: 690, y: 690, width: 170, height: 170)
color(0xFF8A3D).setFill()
NSBezierPath(ovalIn: badge).fill()
draw("⇄", size: 110, weight: .bold, color: .white, in: badge.offsetBy(dx: 0, dy: 4))

image.unlockFocus()

// 5) Write the PNG
guard let tiff = image.tiffRepresentation,
      let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
else { fatalError("Could not encode icon") }
try png.write(to: URL(fileURLWithPath: output))
