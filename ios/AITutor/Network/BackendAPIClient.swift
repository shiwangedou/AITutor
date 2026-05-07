import Foundation

protocol BackendAPIClientProtocol {
    func createSession(displayName: String) async throws -> SessionConfig
}

final class BackendAPIClient: BackendAPIClientProtocol {
    private let baseURL: URL
    private let urlSession: URLSession

    init(baseURL: URL, urlSession: URLSession = .shared) {
        self.baseURL = baseURL
        self.urlSession = urlSession
    }

    func createSession(displayName: String) async throws -> SessionConfig {
        var request = URLRequest(url: baseURL.appendingPathComponent("session"))
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["display_name": displayName])

        AppLogger.debug("POST /session baseURL=\(baseURL.absoluteString)", category: .network)

        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw AppError.backendUnavailable("Missing HTTP response")
            }

            guard (200...299).contains(http.statusCode) else {
                let body = String(data: data, encoding: .utf8) ?? "empty body"
                throw AppError.sessionTokenFailed("HTTP \(http.statusCode): \(body)")
            }

            let config = try JSONDecoder().decode(SessionConfig.self, from: data)
            AppLogger.debug("/session ok room=\(config.roomName) identity=\(config.participantIdentity)", category: .network)
            return config
        } catch let appError as AppError {
            throw appError
        } catch {
            throw AppError.backendUnavailable(AppLogger.describe(error))
        }
    }
}
