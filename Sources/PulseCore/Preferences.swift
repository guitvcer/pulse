import Foundation

/// User choices that survive restarts.
public final class Preferences {
    private enum Key {
        static let displayMode = "displayMode"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var displayMode: DisplayMode {
        get {
            defaults.string(forKey: Key.displayMode).flatMap(DisplayMode.init(rawValue:)) ?? .stacked
        }
        set { defaults.set(newValue.rawValue, forKey: Key.displayMode) }
    }
}
