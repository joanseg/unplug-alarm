import AppKit

/// Removes the helper registration, the saved settings and the app itself, then quits.
@MainActor
enum Uninstaller {
    static func run(sleepGuard: SleepGuard) async {
        let alert = NSAlert()
        alert.messageText = "Uninstall Unplug Alarm?"
        alert.informativeText = "This removes its background helper and settings, and moves the app to the Bin."
        alert.addButton(withTitle: "Uninstall")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate()
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        await sleepGuard.unregister()
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        do {
            try await NSWorkspace.shared.recycle([Bundle.main.bundleURL])
        } catch {
            log.error("move to Bin failed: \(error)")
        }
        NSApplication.shared.terminate(nil)
    }
}
