import AppKit
import PulseCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusController: StatusController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusController = StatusController(preferences: Preferences(), loginItem: LoginItem())
    }
}
