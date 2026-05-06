import AVFAudio

final class AudioSessionManager {
    func configureForVoiceChat() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try session.setActive(true)
    }

    func deactivate() {
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
