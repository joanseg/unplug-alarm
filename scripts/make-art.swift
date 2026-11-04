// Generates Resources/AppIcon.icns and Resources/dmg-background.tiff.
// Run from the repo root: swift scripts/make-art.swift
import AppKit

/// Renders `draw` into a PNG of `pixels` × `pixelsHigh`, where `draw` works in `points` coordinates.
func png(width: CGFloat, height: CGFloat, scale: CGFloat, _ draw: () -> Void) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(width * scale), pixelsHigh: Int(height * scale),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: width, height: height)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    draw()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

func symbol(_ name: String, pointSize: CGFloat, color: NSColor) -> NSImage {
    let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        .applying(.init(paletteColors: [color]))
    return NSImage(systemSymbolName: name, accessibilityDescription: nil)!.withSymbolConfiguration(config)!
}

func drawCentered(_ image: NSImage, at center: NSPoint) {
    image.draw(in: NSRect(x: center.x - image.size.width / 2, y: center.y - image.size.height / 2,
                          width: image.size.width, height: image.size.height))
}

/// The app icon on Apple's 1024-point grid: a red-to-orange rounded square with a white ringing bell.
func drawIcon() {
    let tile = NSRect(x: 100, y: 100, width: 824, height: 824)
    let shape = NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = .black.withAlphaComponent(0.3)
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.shadowBlurRadius = 24
    shadow.set()
    NSColor.white.setFill()
    shape.fill()
    NSGraphicsContext.restoreGraphicsState()
    NSGradient(starting: NSColor(red: 1.0, green: 0.62, blue: 0.04, alpha: 1),
               ending: NSColor(red: 0.92, green: 0.18, blue: 0.16, alpha: 1))!.draw(in: shape, angle: -90)
    drawCentered(symbol("bell.and.waves.left.and.right.fill", pointSize: 400, color: .white), at: NSPoint(x: 512, y: 512))
}

/// DMG window content size in points; scripts/make-dmg.sh places the icons on this grid.
let backgroundSize = NSSize(width: 540, height: 300)
/// Vertical centre of the two icons, measured from the top (Finder's coordinates).
let iconCentreFromTop: CGFloat = 125

/// The DMG window background: app on the left, Applications on the right, an arrow and a caption between.
func drawBackground() {
    let bounds = NSRect(origin: .zero, size: backgroundSize)
    NSGradient(starting: NSColor(white: 0.98, alpha: 1), ending: NSColor(white: 0.93, alpha: 1))!.draw(in: bounds, angle: -90)

    let y = backgroundSize.height - iconCentreFromTop
    let arrow = NSBezierPath()
    arrow.move(to: NSPoint(x: 222, y: y))
    arrow.line(to: NSPoint(x: 318, y: y))
    arrow.move(to: NSPoint(x: 304, y: y + 12))
    arrow.line(to: NSPoint(x: 318, y: y))
    arrow.line(to: NSPoint(x: 304, y: y - 12))
    arrow.lineWidth = 4
    arrow.lineCapStyle = .round
    arrow.lineJoinStyle = .round
    NSColor(white: 0.62, alpha: 1).setStroke()
    arrow.stroke()

    let caption = NSAttributedString(string: "Drag Unplug Alarm into Applications to install", attributes: [
        .font: NSFont.systemFont(ofSize: 13, weight: .regular),
        .foregroundColor: NSColor(white: 0.45, alpha: 1),
    ])
    caption.draw(at: NSPoint(x: (backgroundSize.width - caption.size().width) / 2, y: 38))
}

let resources = URL(fileURLWithPath: "Resources")
let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("unplug-art-\(UUID().uuidString)")
let iconset = tmp.appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let data = png(width: 1024, height: 1024, scale: CGFloat(size * scale) / 1024, drawIcon)
        let name = scale == 1 ? "icon_\(size)x\(size).png" : "icon_\(size)x\(size)@2x.png"
        try data.write(to: iconset.appendingPathComponent(name))
    }
}
let background1x = tmp.appendingPathComponent("bg.png"), background2x = tmp.appendingPathComponent("bg@2x.png")
try png(width: backgroundSize.width, height: backgroundSize.height, scale: 1, drawBackground).write(to: background1x)
try png(width: backgroundSize.width, height: backgroundSize.height, scale: 2, drawBackground).write(to: background2x)

func run(_ tool: String, _ arguments: [String]) throws {
    let process = try Process.run(URL(fileURLWithPath: tool), arguments: arguments)
    process.waitUntilExit()
    precondition(process.terminationStatus == 0, "\(tool) failed")
}
try run("/usr/bin/iconutil", ["-c", "icns", iconset.path, "-o", resources.appendingPathComponent("AppIcon.icns").path])
try run("/usr/bin/tiffutil", ["-cathidpicheck", background1x.path, background2x.path,
                              "-out", resources.appendingPathComponent("dmg-background.tiff").path])
print("Wrote Resources/AppIcon.icns and Resources/dmg-background.tiff")
