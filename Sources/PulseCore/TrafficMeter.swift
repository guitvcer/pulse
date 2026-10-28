import Foundation

/// Lifetime byte counters of one network interface.
public struct InterfaceCounters: Equatable, Sendable {
    public var received: UInt64
    public var sent: UInt64

    public init(received: UInt64, sent: UInt64) {
        self.received = received
        self.sent = sent
    }
}

/// Counters of every interface that counts, read at one moment.
public struct TrafficSnapshot: Equatable, Sendable {
    public var counters: [String: InterfaceCounters]
    public var takenAt: Date

    public init(counters: [String: InterfaceCounters], takenAt: Date) {
        self.counters = counters
        self.takenAt = takenAt
    }
}

/// Bytes per second flowing in each direction.
public struct TrafficRate: Equatable, Sendable {
    public var download: Double
    public var upload: Double

    public static let zero = TrafficRate(download: 0, upload: 0)

    public init(download: Double, upload: Double) {
        self.download = download
        self.upload = upload
    }

    public var combined: Double { download + upload }
}

/// Turns successive counter snapshots into a live rate.
///
/// Deltas are taken per interface, so an adapter that appears with a large
/// lifetime counter, or one whose counter resets, never produces a spike.
public struct TrafficMeter: Sendable {
    private var previous: TrafficSnapshot?
    private var lastRate = TrafficRate.zero

    public init() {}

    @discardableResult
    public mutating func record(_ snapshot: TrafficSnapshot) -> TrafficRate {
        defer { previous = snapshot }
        guard let previous else { return .zero }

        let elapsed = snapshot.takenAt.timeIntervalSince(previous.takenAt)
        guard elapsed > 0 else { return lastRate }

        var received: UInt64 = 0
        var sent: UInt64 = 0
        for (name, now) in snapshot.counters {
            guard let before = previous.counters[name] else { continue }
            received += now.received >= before.received ? now.received - before.received : 0
            sent += now.sent >= before.sent ? now.sent - before.sent : 0
        }

        lastRate = TrafficRate(
            download: Double(received) / elapsed,
            upload: Double(sent) / elapsed)
        return lastRate
    }
}
