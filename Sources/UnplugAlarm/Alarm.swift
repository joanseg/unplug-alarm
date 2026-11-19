import AppKit
import AVFoundation
import AudioToolbox

/// A looping siren played through the built-in speakers at the chosen volume, even when
/// headphones or AirPods are connected. Falls back to the default output on Macs without speakers.
@MainActor
final class Alarm {
    private var engine: AVAudioEngine?

    /// Sets the volume (0–100), unmutes, and starts the siren.
    func start(volume: Int) {
        let engine = AVAudioEngine()
        if let speakers = Speakers.deviceID {
            var device = speakers
            AudioUnitSetProperty(engine.outputNode.audioUnit!, kAudioOutputUnitProperty_CurrentDevice,
                                 kAudioUnitScope_Global, 0, &device, UInt32(MemoryLayout<AudioDeviceID>.size))
            Speakers.setVolume(volume, on: speakers)
        } else {
            NSAppleScript(source: "set volume output volume \(volume) without output muted")?.executeAndReturnError(nil)
        }
        let node = Siren.makeNode(sampleRate: engine.outputNode.outputFormat(forBus: 0).sampleRate)
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: node.outputFormat(forBus: 0))
        do {
            try engine.start()
            self.engine = engine
            log.info("alarm start: volume=\(volume) speakers=\(Speakers.deviceID != nil)")
        } catch {
            log.error("alarm start failed: \(error)")
        }
    }

    func stop() {
        engine?.stop()
        engine = nil
    }
}
