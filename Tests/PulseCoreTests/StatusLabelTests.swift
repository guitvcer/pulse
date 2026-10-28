import Testing

@testable import PulseCore

@Suite("What the menu bar shows")
struct StatusLabelTests {
    private let rate = TrafficRate(download: 4_800_000, upload: 120_000)

    @Test("Compact shows one combined number")
    func compact() {
        let label = StatusLabel(rate: rate, mode: .compact)
        #expect(label.parts == [StatusLabel.Part(symbol: "⇅", value: "4.9 MB/s", isActive: true)])
    }

    @Test("Stacked puts upload above download")
    func stacked() {
        let label = StatusLabel(rate: rate, mode: .stacked)
        #expect(
            label.parts == [
                StatusLabel.Part(symbol: "↑", value: "120 KB/s", isActive: true),
                StatusLabel.Part(symbol: "↓", value: "4.8 MB/s", isActive: true),
            ])
    }

    @Test("Inline uses the same order as stacked")
    func inline() {
        let label = StatusLabel(rate: rate, mode: .inline)
        #expect(label.parts == StatusLabel(rate: rate, mode: .stacked).parts)
    }

    @Test("An arrow is lit only while its direction carries traffic")
    func activity() {
        let label = StatusLabel(rate: TrafficRate(download: 30, upload: 2_000), mode: .stacked)
        #expect(label.parts.map(\.isActive) == [true, false])
        let quiet = StatusLabel(rate: .zero, mode: .compact)
        #expect(quiet.parts.map(\.isActive) == [false])
    }

    @Test("Every mode has a human name for the menu")
    func modeTitles() {
        #expect(DisplayMode.allCases.map(\.title) == ["Compact", "Stacked", "Inline"])
    }

    @Test("Width is reserved for the longest value in every unit")
    func widestSamples() {
        #expect(StatusLabel.widestValues == ["888 KB/s", "888 MB/s", "888 GB/s"])
    }
}
