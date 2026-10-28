// Draws the Pulse app icon and writes Resources/AppIcon.icns.
// Run with: swift scripts/make-icon.swift
import AppKit

let sizes: [(String, Int)] = [
    ("16x16", 16), ("16x16@2x", 32), ("32x32", 32), ("32x32@2x", 64),
    ("128x128", 128), ("128x128@2x", 256), ("256x256", 256), ("256x256@2x", 512),
    ("512x512", 512), ("512x512@2x", 1024),
]

func drawIcon(pixels: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = CGFloat(pixels) / 1024

    // Squircle-ish tile with the standard macOS margin.
    let tile = NSRect(x: 100 * s, y: 100 * s, width: 824 * s, height: 824 * s)
    let shape = NSBezierPath(roundedRect: tile, xRadius: 185 * s, yRadius: 185 * s)
    NSGraphicsContext.current?.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
    shadow.shadowBlurRadius = 24 * s
    shadow.shadowOffset = NSSize(width: 0, height: -10 * s)
    shadow.set()
    NSColor(srgbRed: 0.06, green: 0.07, blue: 0.09, alpha: 1).setFill()
    shape.fill()
    NSGraphicsContext.current?.restoreGraphicsState()

    NSGradient(colors: [
        NSColor(srgbRed: 0.13, green: 0.15, blue: 0.19, alpha: 1),
        NSColor(srgbRed: 0.05, green: 0.06, blue: 0.08, alpha: 1),
    ])!.draw(in: shape, angle: -90)

    // The pulse line: calm, one sharp beat up, one down, calm again.
    let points: [(CGFloat, CGFloat)] = [
        (210, 512), (400, 512), (460, 690), (540, 330), (600, 512), (814, 512),
    ]
    let line = NSBezierPath()
    line.move(to: NSPoint(x: points[0].0 * s, y: points[0].1 * s))
    for point in points.dropFirst() { line.line(to: NSPoint(x: point.0 * s, y: point.1 * s)) }
    line.lineWidth = 46 * s
    line.lineCapStyle = .round
    line.lineJoinStyle = .round

    let accent = NSColor(srgbRed: 0.42, green: 0.96, blue: 0.78, alpha: 1)
    NSGraphicsContext.current?.saveGraphicsState()
    let glow = NSShadow()
    glow.shadowColor = accent.withAlphaComponent(0.55)
    glow.shadowBlurRadius = 60 * s
    glow.set()
    accent.setStroke()
    line.stroke()
    NSGraphicsContext.current?.restoreGraphicsState()

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for (name, pixels) in sizes {
    let data = drawIcon(pixels: pixels).representation(using: .png, properties: [:])!
    try data.write(to: iconset.appendingPathComponent("icon_\(name).png"))
}
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o", root.appendingPathComponent("Resources/AppIcon.icns").path]
try task.run()
task.waitUntilExit()
try drawIcon(pixels: 1024).representation(using: .png, properties: [:])!
    .write(to: FileManager.default.temporaryDirectory.appendingPathComponent("pulse-icon-preview.png"))
print("Wrote Resources/AppIcon.icns")
