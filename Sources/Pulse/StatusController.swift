import AppKit
import PulseCore
import PulseUI

/// Owns the menu bar item: samples traffic every second and redraws the label.
@MainActor
final class StatusController: NSObject, NSMenuDelegate {
    private static let refreshInterval: TimeInterval = 1
    private static let horizontalPadding: CGFloat = 8

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let renderer = StatusImageRenderer()
    private let preferences: Preferences
    private let loginItem: LoginItem
    private var meter = TrafficMeter()
    private var rate = TrafficRate.zero
    private var timer: Timer?
    private var shownLabel: StatusLabel?

    private var modeItems: [DisplayMode: NSMenuItem] = [:]
    private let loginMenuItem = NSMenuItem(
        title: "Open at Login", action: #selector(toggleLogin), keyEquivalent: "")

    init(preferences: Preferences, loginItem: LoginItem) {
        self.preferences = preferences
        self.loginItem = loginItem
        super.init()
        statusItem.menu = makeMenu()
        sample()
        startTimer()
    }

    private func startTimer() {
        let timer = Timer(timeInterval: Self.refreshInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.sample() }
        }
        timer.tolerance = 0.1
        // Common modes keep the numbers live while the menu is open.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func sample() {
        if let snapshot = try? SystemCounters.read() {
            rate = meter.record(snapshot)
        }
        redraw()
    }

    private func redraw() {
        guard let button = statusItem.button else { return }
        let label = StatusLabel(rate: rate, mode: preferences.displayMode)
        // Most seconds nothing visible changes; skip the redraw then.
        guard label != shownLabel else { return }
        shownLabel = label
        let image = renderer.image(for: label)
        // A fixed length spares the menu bar a layout pass on every update.
        let length = ceil(image.size.width) + Self.horizontalPadding
        if statusItem.length != length { statusItem.length = length }
        button.image = image
        button.imagePosition = .imageOnly
        let download = RateFormatter.format(bytesPerSecond: rate.download)
        let upload = RateFormatter.format(bytesPerSecond: rate.upload)
        button.setAccessibilityLabel("Download \(download), upload \(upload)")
    }

    // MARK: - Menu

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(.sectionHeader(title: "Display"))
        for mode in DisplayMode.allCases {
            let item = NSMenuItem(title: mode.title, action: #selector(selectMode(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mode.rawValue
            modeItems[mode] = item
            menu.addItem(item)
        }
        menu.addItem(.separator())
        loginMenuItem.target = self
        menu.addItem(loginMenuItem)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Pulse", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        return menu
    }

    nonisolated func menuNeedsUpdate(_ menu: NSMenu) {
        MainActor.assumeIsolated {
            for (mode, item) in modeItems {
                item.state = mode == preferences.displayMode ? .on : .off
            }
            loginMenuItem.state = loginItem.isEnabled ? .on : .off
        }
    }

    @objc private func selectMode(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let mode = DisplayMode(rawValue: raw) else { return }
        preferences.displayMode = mode
        redraw()
    }

    @objc private func toggleLogin() {
        loginItem.setEnabled(!loginItem.isEnabled)
    }
}
