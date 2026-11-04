import Foundation
import ServiceManagement
import Shared

/// Keeps the Mac awake with the lid closed while armed, through the privileged helper.
@MainActor
final class SleepGuard {
    private let service = SMAppService.daemon(plistName: "xyz.pesso.unplugalarm.helper.plist")
    private var connection: NSXPCConnection?

    /// Whether the user still has to approve the helper in System Settings → Login Items.
    var needsApproval: Bool { service.status != .enabled }

    /// Registers the helper if needed and disables sleep; returns false if that isn't possible yet.
    func disableSleep() async -> Bool {
        if service.status != .enabled {
            do { try service.register() } catch { log.error("helper register failed: \(error)") }
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
