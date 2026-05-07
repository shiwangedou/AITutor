import Foundation

enum AppError: LocalizedError, Equatable {
    case backendUnavailable(String)
    case sessionTokenFailed(String)
    case liveKitConnectFailed(String)
    case microphonePermissionDenied
    case audioSessionFailed(String)
    case microphonePublishFailed(String)
    case agentNotResponding
    case networkDisconnected
    case storageFailed(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .backendUnavailable(let message):
            return "Backend unavailable: \(message)"
        case .sessionTokenFailed(let message):
            return "Session token failed: \(message)"
        case .liveKitConnectFailed(let message):
            return "LiveKit connect failed: \(message)"
        case .microphonePermissionDenied:
            return "Microphone permission is required. Please enable it in Settings."
        case .audioSessionFailed(let message):
            return "Audio session failed: \(message)"
        case .microphonePublishFailed(let message):
            return "Microphone publish failed: \(message)"
        case .agentNotResponding:
            return "Tutor agent did not respond yet. Confirm the backend agent is registered and in the same LiveKit project."
        case .networkDisconnected:
            return "Network disconnected. Check Wi-Fi and backend URL."
        case .storageFailed(let message):
            return "Session storage failed: \(message)"
        case .unknown(let message):
            return message
        }
    }

    static func wrap(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        return .unknown(AppLogger.describe(error))
    }
}
