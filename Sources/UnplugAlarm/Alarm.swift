import AppKit

/// A looping alarm sound played at full, unmuted system volume.
@MainActor
final class Alarm {
    private let sound = NSSound(contentsOfFile: "/System/Library/Sounds/Sosumi.aiff", byReference: true)!

    init() {
        sound.loops = true
    }

    func start() {
        NSAppleScript(source: "set volume output volume 100 without output muted")?.executeAndReturnError(nil)
        sound.play()
    }

    func stop() {
        sound.stop()
    }
}
