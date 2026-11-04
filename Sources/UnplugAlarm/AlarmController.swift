import LocalAuthentication
import Observation
import os

let log = Logger(subsystem: "unplug-alarm", category: "app")

/// Arms the alarm and rings it when the power cable is pulled.
@MainActor
@Observable
final class AlarmController {
    private(set) var isArmed = false
    private(set) var isRinging = false
    private(set) var isOnAC = PowerMonitor.isOnAC

    @ObservationIgnored private let alarm = Alarm()
    @ObservationIgnored private var monitor: PowerMonitor?

    init() {
        monitor = PowerMonitor { [weak self] onAC in self?.powerChanged(onAC: onAC) }
        monitor?.start()
    }

    func arm() {
        isArmed = true
        log.info("armed")
    }

    /// Asks for Touch ID or the Mac password, then silences and disarms.
    func disarm() async {
        let context = LAContext()
        guard (try? await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "disarm the unplug alarm")) == true else { return }
        alarm.stop()
        isRinging = false
        isArmed = false
    }

    private func powerChanged(onAC: Bool) {
        log.info("power changed: onAC=\(onAC) armed=\(self.isArmed) ringing=\(self.isRinging)")
        isOnAC = onAC
        if isArmed && !onAC && !isRinging {
            isRinging = true
            alarm.start()
        }
    }
}
