import AVFoundation

/// A square-wave siren whose pitch wails between 700 and 1500 Hz once a second.
final class Siren: @unchecked Sendable {
    private let sampleRate: Double
    private var phase = 0.0
    private var time = 0.0

    init(sampleRate: Double) {
        self.sampleRate = sampleRate
    }

    /// An audio node that renders the siren; built outside the main actor because it runs on the audio thread.
    nonisolated static func makeNode(sampleRate: Double) -> AVAudioSourceNode {
        let siren = Siren(sampleRate: sampleRate)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        return AVAudioSourceNode(format: format) { _, _, frameCount, bufferList in
            let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
            for frame in 0..<Int(frameCount) {
                let sample = siren.nextSample()
                for buffer in buffers {
                    buffer.mData!.assumingMemoryBound(to: Float.self)[frame] = sample
                }
            }
            return noErr
        }
    }

    private func nextSample() -> Float {
        let sweep = abs(time.truncatingRemainder(dividingBy: 1) * 2 - 1)
        let frequency = 700 + 800 * (1 - sweep)
        phase = (phase + 2 * .pi * frequency / sampleRate).truncatingRemainder(dividingBy: 2 * .pi)
        time += 1 / sampleRate
        return sin(phase) >= 0 ? 0.7 : -0.7
    }
}
