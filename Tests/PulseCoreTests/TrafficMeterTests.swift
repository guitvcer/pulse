import Foundation
import Testing

@testable import PulseCore

@Suite("Traffic meter")
struct TrafficMeterTests {
    private let start = Date(timeIntervalSince1970: 1_000)

    private func snapshot(_ counters: [String: (rx: UInt64, tx: UInt64)], at seconds: Double)
        -> TrafficSnapshot
    {
        TrafficSnapshot(
            counters: counters.mapValues { InterfaceCounters(received: $0.rx, sent: $0.tx) },
            takenAt: start.addingTimeInterval(seconds))
    }

    @Test("First reading has nothing to compare against")
    func firstReadingIsZero() {
        var meter = TrafficMeter()
        let rate = meter.record(snapshot(["en0": (5_000, 1_000)], at: 0))
        #expect(rate == .zero)
    }

    @Test("Rate is bytes moved divided by elapsed time")
    func computesRate() {
        var meter = TrafficMeter()
        meter.record(snapshot(["en0": (5_000, 1_000)], at: 0))
        let rate = meter.record(snapshot(["en0": (25_000, 3_000)], at: 2))
        #expect(rate == TrafficRate(download: 10_000, upload: 1_000))
    }

    @Test("Traffic from several connections adds up")
    func sumsInterfaces() {
        var meter = TrafficMeter()
        meter.record(snapshot(["en0": (0, 0), "en1": (0, 0)], at: 0))
        let rate = meter.record(snapshot(["en0": (1_000, 100), "en1": (500, 50)], at: 1))
        #expect(rate == TrafficRate(download: 1_500, upload: 150))
    }

    @Test("A newly connected adapter does not cause a spike")
    func newInterfaceIgnoredUntilSecondReading() {
        var meter = TrafficMeter()
        meter.record(snapshot(["en0": (0, 0)], at: 0))
        let rate = meter.record(snapshot(["en0": (1_000, 0), "en5": (9_000_000_000, 0)], at: 1))
        #expect(rate == TrafficRate(download: 1_000, upload: 0))
    }

    @Test("A counter that resets is treated as no traffic, not negative")
    func counterResetIsZero() {
        var meter = TrafficMeter()
        meter.record(snapshot(["en0": (9_000, 9_000)], at: 0))
        let rate = meter.record(snapshot(["en0": (100, 100)], at: 1))
        #expect(rate == .zero)
    }

    @Test("Readings with no time between them are ignored")
    func zeroElapsedKeepsPreviousRate() {
        var meter = TrafficMeter()
        meter.record(snapshot(["en0": (0, 0)], at: 0))
        let first = meter.record(snapshot(["en0": (1_000, 0)], at: 1))
        let second = meter.record(snapshot(["en0": (2_000, 0)], at: 1))
        #expect(second == first)
    }

    @Test("Combined rate is download plus upload")
    func combined() {
        #expect(TrafficRate(download: 4_000, upload: 1_000).combined == 5_000)
    }
}
