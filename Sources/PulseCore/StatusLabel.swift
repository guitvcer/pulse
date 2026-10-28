/// The text content of the menu bar label, independent of how it is drawn.
public struct StatusLabel: Equatable, Sendable {
    public struct Part: Equatable, Sendable {
        public var symbol: String
        public var value: String
        /// Whether this direction is currently carrying visible traffic.
        public var isActive: Bool

        public init(symbol: String, value: String, isActive: Bool) {
            self.symbol = symbol
            self.value = value
            self.isActive = isActive
        }

        init(symbol: String, bytesPerSecond: Double) {
            self.init(
                symbol: symbol,
                value: RateFormatter.format(bytesPerSecond: bytesPerSecond),
                isActive: bytesPerSecond >= StatusLabel.activityThreshold)
        }
    }

    /// Below this many bytes per second the label reads "0 KB/s", so the arrow rests.
    static let activityThreshold: Double = 50

    /// Values whose rendered width is the widest possible in each unit,
    /// used to reserve a fixed width so the menu bar never jitters.
    public static let widestValues = ["888 KB/s", "888 MB/s", "888 GB/s"]

    public var mode: DisplayMode
    public var parts: [Part]

    public init(rate: TrafficRate, mode: DisplayMode) {
        self.mode = mode
        switch mode {
        case .compact:
            parts = [Part(symbol: "⇅", bytesPerSecond: rate.combined)]
        case .stacked, .inline:
            parts = [
                Part(symbol: "↑", bytesPerSecond: rate.upload),
                Part(symbol: "↓", bytesPerSecond: rate.download),
            ]
        }
    }
}
