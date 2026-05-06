import Foundation

protocol LiveKitControlling {
    func connect(using config: SessionConfig) async throws
    func startMicrophone() async throws
    func disconnect() async
}

final class LiveKitService: LiveKitControlling {
    // TODO: Replace with real LiveKit Room implementation after adding the LiveKit iOS SDK.
    // Intentionally lightweight for challenge scope.

    func connect(using config: SessionConfig) async throws {
        _ = config
        try await Task.sleep(nanoseconds: 300_000_000)
    }

    func startMicrophone() async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
    }

    func disconnect() async {
        try? await Task.sleep(nanoseconds: 100_000_000)
    }
}
