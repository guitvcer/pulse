import Foundation
import Testing

@testable import PulseCore

@Suite("Reading this Mac's counters")
struct SystemCountersTests {
    @Test("Reads at least one real connection and never loopback")
    func readsInterfaces() throws {
        let snapshot = try SystemCounters.read()
        #expect(!snapshot.counters.isEmpty)
        #expect(snapshot.counters.keys.allSatisfy { InterfaceFilter.counts(name: $0, isLoopback: false) })
        #expect(snapshot.counters["lo0"] == nil)
    }

    @Test("Counters only grow between readings")
    func countersAreMonotonic() throws {
        let first = try SystemCounters.read()
        let second = try SystemCounters.read()
        for (name, before) in first.counters {
            guard let after = second.counters[name] else { continue }
            #expect(after.received >= before.received)
            #expect(after.sent >= before.sent)
        }
    }
}
