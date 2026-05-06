import Foundation

final class BackendClient {
    private let baseURL: URL

    init(baseURL: URL) {
        self.baseURL = baseURL
    }

    func createSession(displayName: String) async throws -> SessionConfig {
        var request = URLRequest(url: baseURL.appendingPathComponent("session"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["display_name": displayName])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "BackendClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create session"])
        }
        return try JSONDecoder().decode(SessionConfig.self, from: data)
    }
}
