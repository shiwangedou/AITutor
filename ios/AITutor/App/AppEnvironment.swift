import Foundation

@MainActor
struct AppEnvironment {
    let backendClient: BackendAPIClientProtocol
    let agentClient: LiveKitAgentControlling
    let audioManager: AudioSessionManaging
    let sessionStorage: SessionStorageManaging
    let learningProfileStore: LearningProfileStoring
    let appSettingsStore: AppSettingsStoring

    static func live() -> AppEnvironment {
        AppEnvironment(
            backendClient: BackendAPIClient(baseURL: AppConfig.backendBaseURL),
            agentClient: LiveKitAgentClient(),
            audioManager: AudioSessionManager(),
            sessionStorage: SessionStorageManager(),
            learningProfileStore: LearningProfileStore(),
            appSettingsStore: AppSettingsStore()
        )
    }
}
