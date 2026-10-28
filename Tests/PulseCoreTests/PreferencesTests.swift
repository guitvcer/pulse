import Foundation
import Testing

@testable import PulseCore

@Suite("Remembering choices")
struct PreferencesTests {
    private func freshDefaults() -> UserDefaults {
        let name = "PulseTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test("Stacked is the starting mode")
    func defaultMode() {
        #expect(Preferences(defaults: freshDefaults()).displayMode == .stacked)
    }

    @Test("A chosen mode survives a restart")
    func persistsMode() {
        let defaults = freshDefaults()
        Preferences(defaults: defaults).displayMode = .compact
        #expect(Preferences(defaults: defaults).displayMode == .compact)
    }

    @Test("A corrupted stored value falls back to the starting mode")
    func corruptedValue() {
        let defaults = freshDefaults()
        defaults.set("sideways", forKey: "displayMode")
        #expect(Preferences(defaults: defaults).displayMode == .stacked)
    }
}
