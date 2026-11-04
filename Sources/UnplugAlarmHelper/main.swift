import Foundation
import Shared

/// Only the signed Unplug Alarm app from the Pesso team may connect.
let clientRequirement = #"identifier "xyz.pesso.unplugalarm" and anchor apple generic and certificate leaf[subject.OU] = "35XAX3CSKK""#

/// Runs `pmset disablesleep` as root; returns whether it succeeded.
func setSleepDisabled(_ disabled: Bool) -> Bool {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
    process.arguments = ["disablesleep", disabled ? "1" : "0"]
    do { try process.run() } catch { return false }
    process.waitUntilExit()
    return process.terminationStatus == 0
}

final class Service: NSObject, SleepControl {
    func setSleepDisabled(_ disabled: Bool, reply: @escaping @Sendable (Bool) -> Void) {
        reply(UnplugAlarmHelper.setSleepDisabled(disabled))
    }
}

final class ListenerDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        connection.setCodeSigningRequirement(clientRequirement)
        connection.exportedInterface = NSXPCInterface(with: SleepControl.self)
        connection.exportedObject = Service()
        // Fail-safe: when the app disarms, quits or crashes, sleep comes back.
        connection.invalidationHandler = { _ = UnplugAlarmHelper.setSleepDisabled(false) }
        connection.resume()
        return true
    }
}

_ = setSleepDisabled(false)
let delegate = ListenerDelegate()
let listener = NSXPCListener(machServiceName: helperMachService)
listener.delegate = delegate
listener.resume()
dispatchMain()
