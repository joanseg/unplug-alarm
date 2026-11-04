import AppKit
import AVFoundation

/// A looping siren played at unmuted system volume.
@MainActor
final class Alarm {
    private let engine = AVAudioEngine()

    init() {
        let sampleRate = engine.outputNode.inputFormat(forBus: 0).sampleRate
        let node = Siren.makeNode(sampleRate: sampleRate)
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: node.outputFormat(forBus: 0))
    }

    /// Sets the system volume (0–100), unmutes, and starts the siren.
    func start(volume: Int) {
        var error: NSDictionary?
        NSAppleScript(source: "set volume output volume \(volume) without output muted")?.executeAndReturnError(&error)
        do {
            try engine.start()
            log.info("alarm start: volume=\(volume) scriptError=\(String(describing: error))")
        } catch {
            log.error("alarm start failed: \(error)")
        }
    }

    func stop() {
        engine.stop()
    }
}
