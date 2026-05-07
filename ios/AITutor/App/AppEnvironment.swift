import Foundation

@MainActor
struct AppEnvironment {
    let backendClient: BackendAPIClientProtocol
    let agentClient: LiveKitAgentControlling
    let audioManager: AudioSessionManaging
    let sessionStorage: SessionStorageManaging

    static func live() -> AppEnvironment {
        AppEnvironment(
            backendClient: BackendAPIClient(baseURL: AppConfig.backendBaseURL),
            agentClient: LiveKitAgentClient(),
            audioManager: AudioSessionManager(),
            sessionStorage: SessionStorageManager()
        )
    }
}
