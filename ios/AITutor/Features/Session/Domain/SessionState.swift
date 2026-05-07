import Foundation

enum SessionState: String, Codable, Equatable {
    case idle = "Idle"
    case connecting = "Connecting"
    case connected = "Connected"
    case inSession = "In Session"
    case ended = "Ended"
    case backendFailed = "Backend Failed"
    case liveKitFailed = "LiveKit Failed"
    case microphonePermissionFailed = "Mic Permission Failed"
    case audioSessionFailed = "Audio Session Failed"
    case microphonePublishFailed = "Mic Publish Failed"
    case textSendFailed = "Text Send Failed"
    case storageFailed = "Storage Failed"
    case unknownFailed = "Unknown Failed"

    var isFailure: Bool {
        switch self {
        case .backendFailed,
             .liveKitFailed,
             .microphonePermissionFailed,
             .audioSessionFailed,
             .microphonePublishFailed,
             .textSendFailed,
             .storageFailed,
             .unknownFailed:
            return true
        case .idle, .connecting, .connected, .inSession, .ended:
            return false
        }
    }

    static func failureState(for error: AppError) -> SessionState {
        switch error {
        case .backendUnavailable, .sessionTokenFailed, .networkDisconnected:
            return .backendFailed
        case .liveKitConnectFailed, .agentNotResponding:
            return .liveKitFailed
        case .microphonePermissionDenied:
            return .microphonePermissionFailed
        case .audioSessionFailed:
            return .audioSessionFailed
        case .microphonePublishFailed:
            return .microphonePublishFailed
        case .storageFailed:
            return .storageFailed
        case .unknown(let message):
            return message.localizedCaseInsensitiveContains("text send failed") ? .textSendFailed : .unknownFailed
        }
    }
}
