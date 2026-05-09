import Foundation

enum SessionSummaryStatus: String, Codable, Equatable {
    case localOnly
    case generating
    case completed
    case unavailable
    case failed
}

struct SessionRecord: Codable, Equatable, Identifiable {
    let id: String
    let roomName: String
    let tutorSubject: String
    let startedAt: Date
    let endedAt: Date
    let durationSeconds: TimeInterval
    let status: SessionState
    let summary: String
    let aiSummary: String?
    let aiSummaryStatus: SessionSummaryStatus?
}
