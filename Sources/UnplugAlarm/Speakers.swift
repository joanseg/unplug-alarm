import CoreAudio

/// The Mac's built-in speakers, found and driven directly so the siren never goes to headphones.
enum Speakers {
    /// The data source code for the internal speaker, `'ispk'` (IOKit's kIOAudioOutputPortSubTypeInternalSpeaker).
    private static let internalSpeaker: UInt32 = 0x6973_706B

    /// The output device whose data source is the internal speaker, or nil on Macs without one.
    static var deviceID: AudioDeviceID? {
        outputDevices.first { device in
            transportType(of: device) == kAudioDeviceTransportTypeBuiltIn
                && dataSource(of: device) == internalSpeaker
        }
    }

    /// Sets the speakers' volume (0–100) and unmutes them.
    static func setVolume(_ volume: Int, on device: AudioDeviceID) {
        var mute: UInt32 = 0
        set(kAudioDevicePropertyMute, element: kAudioObjectPropertyElementMain, on: device, to: &mute)
        var scalar = Float32(volume) / 100
        // Some devices only expose per-channel volume, so set the main element and both channels.
        for element in [kAudioObjectPropertyElementMain, 1, 2] {
            set(kAudioDevicePropertyVolumeScalar, element: element, on: device, to: &scalar)
        }
    }

    private static var outputDevices: [AudioDeviceID] {
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices,
                                                 mScope: kAudioObjectPropertyScopeGlobal,
                                                 mElement: kAudioObjectPropertyElementMain)
        var size: UInt32 = 0
        AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size)
        var devices = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &devices)
        return devices
    }

    private static func transportType(of device: AudioDeviceID) -> UInt32? {
        read(kAudioDevicePropertyTransportType, scope: kAudioObjectPropertyScopeGlobal, of: device)
    }

    private static func dataSource(of device: AudioDeviceID) -> UInt32? {
        read(kAudioDevicePropertyDataSource, scope: kAudioDevicePropertyScopeOutput, of: device)
    }

    private static func read(_ selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope,
                             of device: AudioDeviceID) -> UInt32? {
        var address = AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        return AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value) == noErr ? value : nil
    }

    private static func set<T: BitwiseCopyable>(_ selector: AudioObjectPropertySelector, element: AudioObjectPropertyElement,
                               on device: AudioDeviceID, to value: inout T) {
        var address = AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioDevicePropertyScopeOutput, mElement: element)
        guard AudioObjectHasProperty(device, &address) else { return }
        AudioObjectSetPropertyData(device, &address, 0, nil, UInt32(MemoryLayout<T>.size), &value)
    }
}
