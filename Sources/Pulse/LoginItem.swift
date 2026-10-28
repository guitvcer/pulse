import AppKit
import ServiceManagement

/// Starting Pulse automatically when the user logs in.
@MainActor
struct LoginItem {
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            presentFailure(error, enabling: enabled)
        }
        if SMAppService.mainApp.status == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
    }

    private func presentFailure(_ error: Error, enabling: Bool) {
        let alert = NSAlert()
        alert.messageText = enabling ? "Couldn’t turn on Open at Login" : "Couldn’t turn off Open at Login"
        alert.informativeText = error.localizedDescription
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
