import AppKit
import ServiceManagement
import Shared

/// Keeps the Mac awake with the lid closed while armed, through the privileged helper.
@MainActor
final class SleepGuard {
    private let service = SMAppService.daemon(plistName: "xyz.pesso.unplugalarm.helper.plist")
    private var connection: NSXPCConnection?

    /// Whether the user still has to approve the helper in System Settings → Login Items.
    var needsApproval: Bool { service.status != .enabled }

    /// Registers the helper if needed and disables sleep; returns false if that isn't possible.
    /// When the helper still needs approval, explains what to switch on and waits for it.
    func disableSleep() async -> Bool {
        if service.status != .enabled {
            do { try service.register() } catch { log.error("helper register failed: \(error)") }
        }
        if service.status == .requiresApproval {
            guard askToApprove() else { return false }
            openLoginItems()
            guard await waitUntilEnabled() else { return false }
        }
        guard service.status == .enabled else { return false }
        let connection = NSXPCConnection(machServiceName: helperMachService, options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: SleepControl.self)
        connection.resume()
        self.connection = connection
        return await setSleepDisabled(true, on: connection)
    }

    /// Re-enables sleep and closes the helper connection.
    func enableSleep() async {
        guard let connection else { return }
        _ = await setSleepDisabled(false, on: connection)
        connection.invalidate()
        self.connection = nil
    }

    func openLoginItems() {
        SMAppService.openSystemSettingsLoginItems()
    }

    private func askToApprove() -> Bool {
        let alert = NSAlert()
        alert.messageText = "Allow Unplug Alarm to keep your Mac awake"
        alert.informativeText = """
            To ring with the lid closed, Unplug Alarm stops your Mac from sleeping while it's armed. \
            macOS asks you to allow this once.

            In the window that opens, find Unplug Alarm under App Background Activity and switch it on. \
            Unplug Alarm finishes arming by itself.
            """
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Not Now")
        NSApp.activate()
        return alert.runModal() == .alertFirstButtonReturn
    }

    /// Polls for up to three minutes while the user switches the helper on.
    private func waitUntilEnabled() async -> Bool {
        for _ in 0..<180 {
            if service.status == .enabled { return true }
            try? await Task.sleep(for: .seconds(1))
        }
        return false
    }

    private func setSleepDisabled(_ disabled: Bool, on connection: NSXPCConnection) async -> Bool {
        let ok = await withCheckedContinuation { continuation in
            let proxy = connection.remoteObjectProxyWithErrorHandler { error in
                log.error("helper call failed: \(error)")
                continuation.resume(returning: false)
            } as! SleepControl
            proxy.setSleepDisabled(disabled) { continuation.resume(returning: $0) }
        }
        log.info("sleep disabled=\(disabled) ok=\(ok)")
        return ok
    }
}
