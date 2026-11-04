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
        let ok = await setSleepDisabled(true, on: connection)
        if !ok { enableSleep() }
        return ok
    }

    /// Closes the helper connection; the helper re-enables sleep when it sees the connection go.
    func enableSleep() {
        connection?.invalidate()
        connection = nil
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

    /// Asks the helper to change the sleep setting; gives up after 5 seconds if it doesn't answer.
    private func setSleepDisabled(_ disabled: Bool, on connection: NSXPCConnection) async -> Bool {
        let ok = await withCheckedContinuation { continuation in
            let reply = ReplyOnce(continuation)
            let proxy = connection.remoteObjectProxyWithErrorHandler { error in
                log.error("helper call failed: \(error)")
                reply.send(false)
            } as! SleepControl
            proxy.setSleepDisabled(disabled) { reply.send($0) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if reply.send(false) { log.error("helper call timed out") }
            }
        }
        log.info("sleep disabled=\(disabled) ok=\(ok)")
        return ok
    }
}

/// Resumes a continuation exactly once, whichever of reply, error or timeout comes first.
private final class ReplyOnce: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Bool, Never>?

    init(_ continuation: CheckedContinuation<Bool, Never>) {
        self.continuation = continuation
    }

    /// Returns whether this call was the one that resumed it.
    @discardableResult
    func send(_ value: Bool) -> Bool {
        lock.lock()
        let pending = continuation
        continuation = nil
        lock.unlock()
        pending?.resume(returning: value)
        return pending != nil
    }
}
