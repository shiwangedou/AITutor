import Foundation

protocol BackendAPIClientProtocol {
    func createSession(displayName: String) async throws -> SessionConfig
    func generateSummary(_ request: SummaryGenerationRequest) async throws -> SummaryGenerationResponse
    func generateIncrementalSummary(_ request: IncrementalSummaryGenerationRequest) async throws -> SummaryGenerationResponse
}

struct SummaryGenerationRequest: Codable, Equatable {
    let sessionID: String
    let tutorSubject: String
    let durationSeconds: TimeInterval
    let transcript: String
    let runningSummary: String?

    enum CodingKeys: String, CodingKey {
        case sessionID = "session_id"
        case tutorSubject = "tutor_subject"
        case durationSeconds = "duration_seconds"
        case transcript
        case runningSummary = "running_summary"
    }
}

struct IncrementalSummaryGenerationRequest: Codable, Equatable {
    let sessionID: String
    let tutorSubject: String
    let previousSummary: String?
    let newTurns: [String]
    let finalize: Bool

    enum CodingKeys: String, CodingKey {
        case sessionID = "session_id"
        case tutorSubject = "tutor_subject"
        case previousSummary = "previous_summary"
        case newTurns = "new_turns"
        case finalize
    }
}

struct SummaryGenerationResponse: Codable, Equatable {
    let summary: String
    let strengths: [String]
    let corrections: [String]
    let nextSteps: [String]

    enum CodingKeys: String, CodingKey {
        case summary
        case strengths
        case corrections
        case nextSteps = "next_steps"
    }

    var displayText: String {
        var parts = [summary]
        if !strengths.isEmpty {
            parts.append("Strengths: \(strengths.joined(separator: "; "))")
        }
        if !corrections.isEmpty {
            parts.append("Corrections: \(corrections.joined(separator: "; "))")
        }
        if !nextSteps.isEmpty {
            parts.append("Next steps: \(nextSteps.joined(separator: "; "))")
        }
        return parts.joined(separator: "\n")
    }
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

    func generateSummary(_ requestBody: SummaryGenerationRequest) async throws -> SummaryGenerationResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("summary"))
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        AppLogger.debug("POST /summary session=\(requestBody.sessionID) transcriptLength=\(requestBody.transcript.count)", category: .network)

        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw AppError.backendUnavailable("Missing HTTP response")
            }

            guard (200...299).contains(http.statusCode) else {
                let body = String(data: data, encoding: .utf8) ?? "empty body"
                throw AppError.backendUnavailable("Summary HTTP \(http.statusCode): \(body)")
            }

            let summary = try JSONDecoder().decode(SummaryGenerationResponse.self, from: data)
            AppLogger.debug("/summary ok session=\(requestBody.sessionID)", category: .network)
            return summary
        } catch let appError as AppError {
            throw appError
        } catch {
            throw AppError.backendUnavailable(AppLogger.describe(error))
        }
    }

    func generateIncrementalSummary(_ requestBody: IncrementalSummaryGenerationRequest) async throws -> SummaryGenerationResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("summary/incremental"))
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        AppLogger.debug("POST /summary/incremental session=\(requestBody.sessionID) turns=\(requestBody.newTurns.count) finalize=\(requestBody.finalize)", category: .network)

        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw AppError.backendUnavailable("Missing HTTP response")
            }

            guard (200...299).contains(http.statusCode) else {
                let body = String(data: data, encoding: .utf8) ?? "empty body"
                throw AppError.backendUnavailable("Incremental summary HTTP \(http.statusCode): \(body)")
            }

            let summary = try JSONDecoder().decode(SummaryGenerationResponse.self, from: data)
            AppLogger.debug("/summary/incremental ok session=\(requestBody.sessionID)", category: .network)
            return summary
        } catch let appError as AppError {
            throw appError
        } catch {
            throw AppError.backendUnavailable(AppLogger.describe(error))
        }
    }
}
