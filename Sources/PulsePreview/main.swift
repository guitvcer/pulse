// Renders every display mode on light and dark menu bar backgrounds into one PNG,
// for checking the design without screen capture. Usage: PulsePreview <out.png>
import AppKit
import PulseCore
import PulseUI

@MainActor
func renderSheet(to url: URL) throws {
    let renderer = StatusImageRenderer()
    let rates = [
        TrafficRate.zero,
        TrafficRate(download: 4_800_000, upload: 120_000),
        TrafficRate(download: 512, upload: 88_400_000),
    ]
    let backgrounds: [(NSColor, NSColor)] = [
        (NSColor(white: 0.93, alpha: 1), NSColor(white: 0.1, alpha: 0.85)),
        (NSColor(white: 0.16, alpha: 1), NSColor(white: 1, alpha: 0.9)),
    ]
    let scale: CGFloat = 4
    let cellWidth: CGFloat = 170
    let rowHeight: CGFloat = 30
    let rows = DisplayMode.allCases.count * backgrounds.count
    let size = NSSize(width: cellWidth * CGFloat(rates.count), height: rowHeight * CGFloat(rows))

    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(size.width * scale), pixelsHigh: Int(size.height * scale),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = size
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    var row = 0
    for (background, ink) in backgrounds {
        for mode in DisplayMode.allCases {
            let y = size.height - rowHeight * CGFloat(row + 1)
            background.setFill()
            NSRect(x: 0, y: y, width: size.width, height: rowHeight).fill()
            for (column, rate) in rates.enumerated() {
                let image = renderer.image(for: StatusLabel(rate: rate, mode: mode))
                // Tint the template like the menu bar does.
                let tinted = NSImage(size: image.size, flipped: false) { rect in
                    image.draw(in: rect)
                    ink.set()
                    rect.fill(using: .sourceIn)
                    return true
                }
                let origin = NSPoint(
                    x: CGFloat(column) * cellWidth + 12, y: y + (rowHeight - image.size.height) / 2)
                tinted.draw(at: origin, from: .zero, operation: .sourceOver, fraction: 1)
            }
            row += 1
        }
    }
    NSGraphicsContext.restoreGraphicsState()
    try rep.representation(using: .png, properties: [:])!.write(to: url)
}

let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "preview.png")
try MainActor.assumeIsolated { try renderSheet(to: output) }
print("Wrote \(output.path)")
