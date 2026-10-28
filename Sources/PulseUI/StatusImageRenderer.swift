import AppKit
import PulseCore

/// Draws a `StatusLabel` into a template image for the menu bar.
///
/// Drawing into an image (instead of setting a button title) gives exact
/// control over the two-line layout and lets macOS tint the result for
/// light, dark and highlighted menu bars automatically.
@MainActor
public final class StatusImageRenderer {
    /// Layout constants for one display mode.
    private struct Style {
        var font: NSFont
        var symbolPointSize: CGFloat
        /// Space between an arrow and its value.
        var symbolGap: CGFloat
        /// Space between parts that share a line.
        var partGap: CGFloat
        var stacksParts: Bool
    }

    private enum Metrics {
        static let height: CGFloat = 22
        static let symbolWidthRatio: CGFloat = 1.0
        static let idleSymbolAlpha: CGFloat = 0.35
        static let idleValueAlpha: CGFloat = 0.6
    }

    private static let symbolNames = [
        "↑": "arrow.up",
        "↓": "arrow.down",
        "⇅": "arrow.up.arrow.down",
    ]

    private var valueWidths: [DisplayMode: CGFloat] = [:]
    private var symbolCache: [String: NSImage] = [:]

    public init() {}

    public func image(for label: StatusLabel) -> NSImage {
        let style = Self.style(for: label.mode)
        let valueWidth = valueWidth(for: label.mode, font: style.font)
        let symbolWidth = style.symbolPointSize * Metrics.symbolWidthRatio
        let partWidth = symbolWidth + style.symbolGap + valueWidth

        let width: CGFloat
        if style.stacksParts {
            width = partWidth
        } else {
            let count = CGFloat(label.parts.count)
            width = partWidth * count + style.partGap * (count - 1)
        }

        let symbols = label.parts.map { symbol(for: $0.symbol, pointSize: style.symbolPointSize) }
        let size = NSSize(width: ceil(width), height: Metrics.height)
        let vector = NSImage(size: size, flipped: true) { _ in
            let baselines = Self.baselines(lineCount: style.stacksParts ? label.parts.count : 1, font: style.font)
            for (index, part) in label.parts.enumerated() {
                let origin = NSPoint(
                    x: style.stacksParts ? 0 : CGFloat(index) * (partWidth + style.partGap),
                    y: baselines[style.stacksParts ? index : 0])
                Self.draw(part, symbol: symbols[index], at: origin, style: style, symbolWidth: symbolWidth)
            }
            return true
        }
        let image = Self.rasterize(vector)
        image.isTemplate = true
        return image
    }

    /// Draws once into a Retina bitmap, so the menu bar does not re-run the text
    /// layout every time it repaints (on hover, highlight or a second display).
    private static func rasterize(_ vector: NSImage) -> NSImage {
        let scale: CGFloat = 2
        guard
            let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: Int(vector.size.width * scale),
                pixelsHigh: Int(vector.size.height * scale), bitsPerSample: 8, samplesPerPixel: 4,
                hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
        else { return vector }
        rep.size = vector.size
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        vector.draw(in: NSRect(origin: .zero, size: vector.size))
        NSGraphicsContext.restoreGraphicsState()
        let image = NSImage(size: vector.size)
        image.addRepresentation(rep)
        return image
    }

    private static func style(for mode: DisplayMode) -> Style {
        switch mode {
        case .stacked:
            Style(
                font: .monospacedDigitSystemFont(ofSize: 9, weight: .medium),
                symbolPointSize: 7, symbolGap: 3, partGap: 0, stacksParts: true)
        case .inline:
            Style(
                font: .monospacedDigitSystemFont(ofSize: 12, weight: .regular),
                symbolPointSize: 9, symbolGap: 3, partGap: 8, stacksParts: false)
        case .compact:
            Style(
                font: .monospacedDigitSystemFont(ofSize: 12, weight: .regular),
                symbolPointSize: 10, symbolGap: 4, partGap: 0, stacksParts: false)
        }
    }

    /// Widest value in any unit, so the label keeps one width as numbers change.
    private func valueWidth(for mode: DisplayMode, font: NSFont) -> CGFloat {
        if let cached = valueWidths[mode] { return cached }
        let width =
            StatusLabel.widestValues
            .map { ceil(($0 as NSString).size(withAttributes: [.font: font]).width) }
            .max() ?? 0
        valueWidths[mode] = width
        return width
    }

    /// Baselines (in flipped coordinates) that center the lines vertically.
    private static func baselines(lineCount: Int, font: NSFont) -> [CGFloat] {
        let lineHeight = ceil(font.ascender - font.descender)
        let blockHeight = lineHeight * CGFloat(lineCount)
        let top = (Metrics.height - blockHeight) / 2
        return (0..<lineCount).map { top + lineHeight * CGFloat($0) + font.ascender }
    }

    /// SF Symbol arrows are looked up once and reused; the lookup is the costly part of a redraw.
    private func symbol(for character: String, pointSize: CGFloat) -> NSImage? {
        let key = "\(character)@\(pointSize)"
        if let cached = symbolCache[key] { return cached }
        guard let name = Self.symbolNames[character],
            let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
                .withSymbolConfiguration(.init(pointSize: pointSize, weight: .bold))
        else { return nil }
        symbolCache[key] = image
        return image
    }

    private static func draw(
        _ part: StatusLabel.Part, symbol: NSImage?, at origin: NSPoint, style: Style, symbolWidth: CGFloat
    ) {
        let symbolAlpha = part.isActive ? 1 : Metrics.idleSymbolAlpha
        let valueAlpha = part.isActive ? 1 : Metrics.idleValueAlpha

        // Arrow, centered on the middle of the capital letters.
        let capCenter = origin.y - style.font.capHeight / 2
        if let symbol {
            let size = symbol.size
            let rect = NSRect(
                x: origin.x + (symbolWidth - size.width) / 2,
                y: capCenter - size.height / 2,
                width: size.width, height: size.height)
            symbol.draw(
                in: rect, from: .zero, operation: .sourceOver, fraction: symbolAlpha,
                respectFlipped: true, hints: nil)
        }

        // Value sits right next to its arrow; the reserved width keeps the item steady.
        let attributes: [NSAttributedString.Key: Any] = [
            .font: style.font,
            .foregroundColor: NSColor.black.withAlphaComponent(valueAlpha),
        ]
        (part.value as NSString).draw(
            at: NSPoint(x: origin.x + symbolWidth + style.symbolGap, y: origin.y - style.font.ascender),
            withAttributes: attributes)
    }
}
