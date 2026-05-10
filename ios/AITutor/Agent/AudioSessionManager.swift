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
    private let notificationCenter: NotificationCenter
    private var notificationObservers: [NSObjectProtocol] = []

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        notificationObservers.append(
            notificationCenter.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: AVAudioSession.sharedInstance(),
                queue: .main
            ) { notification in
                Self.logInterruption(notification)
            }
        )
        notificationObservers.append(
            notificationCenter.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: AVAudioSession.sharedInstance(),
                queue: .main
            ) { notification in
                Self.logRouteChange(notification)
            }
        )
    }

    deinit {
        notificationObservers.forEach(notificationCenter.removeObserver)
    }

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

    private static func logInterruption(_ notification: Notification) {
        let userInfo = notification.userInfo ?? [:]
        let rawType = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt
        let type = rawType.flatMap(AVAudioSession.InterruptionType.init(rawValue:))
        let rawOptions = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt
        let options = rawOptions.map(AVAudioSession.InterruptionOptions.init(rawValue:)) ?? []

        switch type {
        case .began:
            AppLogger.debug("AVAudioSession interruption began. Voice session may pause until system interruption ends.", category: .audio)
        case .ended:
            AppLogger.debug("AVAudioSession interruption ended shouldResume=\(options.contains(.shouldResume))", category: .audio)
        case .none:
            AppLogger.debug("AVAudioSession interruption unknown type=\(String(describing: rawType))", category: .audio)
        @unknown default:
            AppLogger.debug("AVAudioSession interruption future type=\(String(describing: rawType))", category: .audio)
        }
    }

    private static func logRouteChange(_ notification: Notification) {
        let rawReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
        let reason = rawReason.flatMap(AVAudioSession.RouteChangeReason.init(rawValue:))
        let route = AVAudioSession.sharedInstance().currentRoute
        let outputs = route.outputs.map { "\($0.portType.rawValue):\($0.portName)" }.joined(separator: ", ")
        AppLogger.debug("AVAudioSession route changed reason=\(reason?.description ?? "unknown") outputs=\(outputs.isEmpty ? "none" : outputs)", category: .audio)
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

private extension AVAudioSession.RouteChangeReason {
    var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .newDeviceAvailable:
            return "newDeviceAvailable"
        case .oldDeviceUnavailable:
            return "oldDeviceUnavailable"
        case .categoryChange:
            return "categoryChange"
        case .override:
            return "override"
        case .wakeFromSleep:
            return "wakeFromSleep"
        case .noSuitableRouteForCategory:
            return "noSuitableRouteForCategory"
        case .routeConfigurationChange:
            return "routeConfigurationChange"
        @unknown default:
            return "future"
        }
    }
}
