import AppKit
import AVFoundation

/// A looping siren played at unmuted system volume — 100, or `ALARM_VOLUME` when set for testing.
@MainActor
final class Alarm {
    private let engine = AVAudioEngine()
    private let volume = Int(ProcessInfo.processInfo.environment["ALARM_VOLUME"] ?? "") ?? 100

    init() {
        let sampleRate = engine.outputNode.inputFormat(forBus: 0).sampleRate
        let node = Siren.makeNode(sampleRate: sampleRate)
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: node.outputFormat(forBus: 0))
    }

    func start() {
        var error: NSDictionary?
        NSAppleScript(source: "set volume output volume \(volume) without output muted")?.executeAndReturnError(&error)
        do {
            try engine.start()
            log.info("alarm start: volume=\(self.volume) scriptError=\(String(describing: error))")
        } catch {
            log.error("alarm start failed: \(error)")
        }
    }

    func stop() {
        engine.stop()
    }
}
