import AVFAudio
import Foundation

protocol AudioSessionManaging {
    func microphonePermissionStatus() -> MicrophonePermissionStatus
    func requestMicrophonePermission() async -> MicrophonePermissionStatus
    func configureForVoiceChat() throws
    func diagnosticSummary() -> String
    func deactivate()
}

enum MicrophonePermissionStatus: String, Equatable {
    case undetermined
    case denied
    case granted
    case unknown
}

final class AudioSessionManager: AudioSessionManaging {
    func microphonePermissionStatus() -> MicrophonePermissionStatus {
        AVAudioSession.sharedInstance().recordPermission.microphoneStatus
    }

    func requestMicrophonePermission() async -> MicrophonePermissionStatus {
        let before = microphonePermissionStatus()
        AppLogger.debug("Microphone permission before request=\(before.rawValue)", category: .audio)

        guard before == .undetermined else {
            return before
        }

        let granted = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        let status: MicrophonePermissionStatus = granted ? .granted : .denied
        AppLogger.debug("Microphone permission after request=\(status.rawValue)", category: .audio)
        return status
    }

    func configureForVoiceChat() throws {
        let session = AVAudioSession.sharedInstance()
        AppLogger.debug("Configuring AVAudioSession before=\(diagnosticSummary())", category: .audio)

        do {
            try session.setCategory(.playAndRecord, mode: .videoChat, options: [.defaultToSpeaker, .allowBluetoothHFP])
            AppLogger.debug("Configured AVAudioSession after=\(diagnosticSummary())", category: .audio)
        } catch {
            throw AppError.audioSessionFailed(AppLogger.describe(error))
        }
    }

    func diagnosticSummary() -> String {
        let session = AVAudioSession.sharedInstance()
        let route = session.currentRoute
        let inputs = route.inputs.map { "\($0.portType.rawValue):\($0.portName)" }.joined(separator: ", ")
        let outputs = route.outputs.map { "\($0.portType.rawValue):\($0.portName)" }.joined(separator: ", ")

        return [
            "recordPermission=\(session.recordPermission.microphoneStatus.rawValue)",
            "category=\(session.category.rawValue)",
            "mode=\(session.mode.rawValue)",
            "sampleRate=\(Int(session.sampleRate))",
            "inputAvailable=\(session.isInputAvailable)",
            "inputs=\(inputs.isEmpty ? "none" : inputs)",
            "outputs=\(outputs.isEmpty ? "none" : outputs)"
        ].joined(separator: " | ")
    }

    func deactivate() {
        AppLogger.debug("Deactivating AVAudioSession before=\(diagnosticSummary())", category: .audio)
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        AppLogger.debug("Deactivated AVAudioSession after=\(diagnosticSummary())", category: .audio)
    }
}

private extension AVAudioSession.RecordPermission {
    var microphoneStatus: MicrophonePermissionStatus {
        switch self {
        case .undetermined:
            return .undetermined
        case .denied:
            return .denied
        case .granted:
            return .granted
        @unknown default:
            return .unknown
        }
    }
}
