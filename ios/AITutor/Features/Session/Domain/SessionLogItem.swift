import Foundation

struct SessionLogItem: Identifiable, Equatable {
    enum Level: String {
        case info = "INFO"
        case error = "ERROR"
    }

    let id = UUID()
    let date: Date
    let level: Level
    let message: String
    let category: AppLogger.Category

    var displayLine: String {
        "[\(AppDateFormatter.clock(date))] [\(level.rawValue)] \(message)"
    }
}

struct SessionTranscriptItem: Identifiable, Equatable {
    enum Speaker: String {
        case learner = "You"
        case tutor = "Tutor"
    }

    let id: String
    let speaker: Speaker
    var text: String
    var isFinal: Bool

    var displayLine: String {
        let suffix = isFinal ? "" : " ..."
        return "\(speaker.rawValue): \(text)\(suffix)"
    }
}
