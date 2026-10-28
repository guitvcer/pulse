import AppKit
import PulseCore
import Testing

@testable import PulseUI

@Suite("Drawing the menu bar label")
@MainActor
struct StatusImageRendererTests {
    private let renderer = StatusImageRenderer()

    private func image(_ download: Double, _ upload: Double, _ mode: DisplayMode) -> NSImage {
        renderer.image(for: StatusLabel(rate: TrafficRate(download: download, upload: upload), mode: mode))
    }

    @Test("Width stays the same whatever the numbers", arguments: DisplayMode.allCases)
    func stableWidth(mode: DisplayMode) {
        let widths = [
            image(0, 0, mode), image(512, 40, mode), image(4_800_000, 120_000, mode),
            image(999_000_000, 888_000_000, mode),
        ].map(\.size.width)
        #expect(Set(widths).count == 1)
    }

    @Test("Fits inside the menu bar", arguments: DisplayMode.allCases)
    func fitsMenuBar(mode: DisplayMode) {
        let size = image(1, 1, mode).size
        #expect(size.height <= 22)
        #expect(size.width > 20)
    }

    @Test("Adapts to light, dark and highlighted menu bars", arguments: DisplayMode.allCases)
    func isTemplate(mode: DisplayMode) {
        #expect(image(1, 1, mode).isTemplate)
    }

    @Test("Inline is the widest mode")
    func relativeWidths() {
        let inline = image(1, 1, .inline).size.width
        #expect(image(1, 1, .compact).size.width < inline)
        #expect(image(1, 1, .stacked).size.width < inline)
    }

    /// Row (from the top) where the arrow in the first symbol column is widest:
    /// an up arrow has its head near the top, a down arrow near the bottom.
    private func widestArrowRow(_ image: NSImage) throws -> (row: Int, height: Int) {
        let rep = try #require(
            image.cgImage(forProposedRect: nil, context: nil, hints: nil).map(NSBitmapImageRep.init(cgImage:)))
        let columns = 0..<Int(Double(rep.pixelsWide) * 0.12)
        var best = (row: 0, ink: 0)
        for y in 0..<rep.pixelsHigh {
            let ink = columns.filter { (rep.colorAt(x: $0, y: y)?.alphaComponent ?? 0) > 0.5 }.count
            if ink > best.ink { best = (y, ink) }
        }
        return (best.row, rep.pixelsHigh)
    }

    @Test("Arrows are not drawn upside down")
    func arrowsPointTheRightWay() throws {
        // Stacked mode: upload line on top, its arrow head should be in the upper part of that line.
        let stacked = image(0, 5_000, .stacked)
        let (row, height) = try widestArrowRow(stacked)
        #expect(row < height / 4, "upload arrow head should sit at the top of the upper line")
    }

    @Test("Actually draws something")
    func drawsInk() throws {
        let image = image(4_800_000, 120_000, .stacked)
        let rep = try #require(
            image.cgImage(forProposedRect: nil, context: nil, hints: nil).map(NSBitmapImageRep.init(cgImage:)))
        var inked = 0
        for x in 0..<rep.pixelsWide {
            for y in 0..<rep.pixelsHigh where (rep.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.5 {
                inked += 1
            }
        }
        #expect(inked > 50)
    }
}
