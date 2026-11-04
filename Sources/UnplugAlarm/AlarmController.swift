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
    /// Whether sleep is disabled, so the alarm also works with the lid closed.
    private(set) var isLidProtected = false
    /// Alarm volume, 0–100, remembered across launches.
    var volume = UserDefaults.standard.object(forKey: "volume") as? Int ?? 100 {
        didSet { UserDefaults.standard.set(volume, forKey: "volume") }
    }

    @ObservationIgnored private let alarm = Alarm()
    @ObservationIgnored let sleepGuard = SleepGuard()
    @ObservationIgnored private var monitor: PowerMonitor?

    init() {
        monitor = PowerMonitor { [weak self] onAC in self?.powerChanged(onAC: onAC) }
        monitor?.start()
    }

    func arm() async {
        isArmed = true
        let protected = await sleepGuard.disableSleep()
        guard isArmed else {
            sleepGuard.enableSleep()
            return
        }
        isLidProtected = protected
        log.info("armed lidProtected=\(self.isLidProtected)")
    }

    /// Asks for Touch ID or the Mac password, then silences and disarms.
    func disarm() async {
        let context = LAContext()
        guard (try? await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "disarm the unplug alarm")) == true else { return }
        alarm.stop()
        sleepGuard.enableSleep()
        isRinging = false
        isArmed = false
        isLidProtected = false
    }

    private func powerChanged(onAC: Bool) {
        log.info("power changed: onAC=\(onAC) armed=\(self.isArmed) ringing=\(self.isRinging)")
        isOnAC = onAC
        if isArmed && !onAC && !isRinging {
            isRinging = true
            alarm.start(volume: volume)
        }
    }
}
