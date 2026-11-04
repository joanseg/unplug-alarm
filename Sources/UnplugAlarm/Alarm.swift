import AppKit

/// A looping alarm sound played at unmuted system volume — 100, or `ALARM_VOLUME` when set for testing.
@MainActor
final class Alarm {
    private let sound = NSSound(contentsOfFile: "/System/Library/Sounds/Sosumi.aiff", byReference: true)!
    private let volume = Int(ProcessInfo.processInfo.environment["ALARM_VOLUME"] ?? "") ?? 100

    init() {
        sound.loops = true
    }

    func start() {
        var error: NSDictionary?
        NSAppleScript(source: "set volume output volume \(volume) without output muted")?.executeAndReturnError(&error)
        let playing = sound.play()
        log.info("alarm start: volume=\(self.volume) scriptError=\(String(describing: error)) playing=\(playing)")
    }

    func stop() {
        sound.stop()
    }
}
