import Foundation
import IOKit.ps

/// Watches the Mac's power source and reports changes between AC and battery.
@MainActor
final class PowerMonitor {
    private var source: CFRunLoopSource?
    private let onChange: (Bool) -> Void

    /// `onChange` receives `true` when on AC power, `false` when on battery.
    init(onChange: @escaping (Bool) -> Void) {
        self.onChange = onChange
    }

    /// Whether the Mac is currently drawing from AC power.
    static var isOnAC: Bool {
        let info = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let type = IOPSGetProvidingPowerSourceType(info).takeRetainedValue() as String
        return type == kIOPMACPowerKey
    }

    func start() {
        let context = Unmanaged.passUnretained(self).toOpaque()
        source = IOPSNotificationCreateRunLoopSource({ context in
            let monitor = Unmanaged<PowerMonitor>.fromOpaque(context!).takeUnretainedValue()
            MainActor.assumeIsolated { monitor.onChange(PowerMonitor.isOnAC) }
        }, context).takeRetainedValue()
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
    }
}
