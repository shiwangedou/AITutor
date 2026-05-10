import Foundation

enum LearningMode: String, Codable, CaseIterable, Equatable {
    case dailyConversation = "daily_conversation"
    case interviewEnglish = "interview_english"
    case travelEnglish = "travel_english"
    case pronunciationPractice = "pronunciation_practice"

    var displayName: String {
        switch self {
        case .dailyConversation: return "Daily Conversation"
        case .interviewEnglish: return "Interview English"
        case .travelEnglish: return "Travel English"
        case .pronunciationPractice: return "Pronunciation Practice"
        }
    }
}

enum TutorStyle: String, Codable, CaseIterable, Equatable {
    case gentleCoach = "gentle_coach"
    case directCoach = "direct_coach"
    case challengeCoach = "challenge_coach"

    var displayName: String {
        switch self {
        case .gentleCoach: return "Gentle Coach"
        case .directCoach: return "Direct Coach"
        case .challengeCoach: return "Challenge Coach"
        }
    }
}

enum LearningDifficulty: String, Codable, CaseIterable, Equatable {
    case beginner
    case intermediate
    case advanced

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
}

struct LearningProfile: Codable, Equatable {
    static let customGoalMaxLength = 160
    static let `default` = LearningProfile(
        learningMode: .dailyConversation,
        tutorStyle: .gentleCoach,
        difficulty: .intermediate,
        customGoal: nil
    )

    var learningMode: LearningMode
    var tutorStyle: TutorStyle
    var difficulty: LearningDifficulty
    var customGoal: String?

    var summaryLine: String {
        [learningMode.displayName, tutorStyle.displayName, difficulty.displayName].joined(separator: " · ")
    }

    var goalLine: String {
        let goal = customGoal?.trimmingCharacters(in: .whitespacesAndNewlines)
        return goal?.isEmpty == false ? goal! : "No custom goal"
    }

    func normalized() -> LearningProfile {
        var copy = self
        let trimmed = customGoal?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, !trimmed.isEmpty {
            copy.customGoal = String(trimmed.prefix(Self.customGoalMaxLength))
        } else {
            copy.customGoal = nil
        }
        return copy
    }

    enum CodingKeys: String, CodingKey {
        case learningMode = "learning_mode"
        case tutorStyle = "tutor_style"
        case difficulty
        case customGoal = "custom_goal"
    }
}

struct SessionResumeContext: Codable, Equatable {
    static let summaryMaxLength = 900
    static let aiSummaryMaxLength = 1_200
    static let transcriptMaxLength = 6_000
    static let transcriptLineLimit = 40

    let sourceSessionID: String?
    let summary: String?
    let aiSummary: String?
    let transcriptExcerpt: String?

    var hasContent: Bool {
        [summary, aiSummary, transcriptExcerpt].contains { value in
            value?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        }
    }

    enum CodingKeys: String, CodingKey {
        case sourceSessionID = "source_session_id"
        case summary
        case aiSummary = "ai_summary"
        case transcriptExcerpt = "transcript_excerpt"
    }

    init(
        sourceSessionID: String?,
        summary: String?,
        aiSummary: String?,
        transcriptExcerpt: String?
    ) {
        self.sourceSessionID = sourceSessionID?.trimmedLimited(to: 120)
        self.summary = summary?.trimmedLimited(to: Self.summaryMaxLength)
        self.aiSummary = aiSummary?.trimmedLimited(to: Self.aiSummaryMaxLength)
        self.transcriptExcerpt = transcriptExcerpt?.trimmedLimited(to: Self.transcriptMaxLength)
    }

    static func make(from record: SessionRecord) -> SessionResumeContext {
        let transcript = record.messages?.map(\.transcriptLine).joined(separator: "\n") ?? record.transcriptText
        let transcriptExcerpt = transcript?
            .split(separator: "\n")
            .suffix(Self.transcriptLineLimit)
            .map(String.init)
            .joined(separator: "\n")

        return SessionResumeContext(
            sourceSessionID: record.id,
            summary: record.summary,
            aiSummary: record.aiSummary,
            transcriptExcerpt: transcriptExcerpt
        )
    }
}

private extension String {
    func trimmedLimited(to limit: Int) -> String? {
        let cleaned = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        return String(cleaned.prefix(limit))
    }
}

enum ChatMessageSpeaker: String, Codable, Equatable {
    case learner
    case tutor
    case system

    var displayName: String {
        switch self {
        case .learner: return "You"
        case .tutor: return "Tutor"
        case .system: return "System"
        }
    }
}

enum ChatMessageInputType: String, Codable, Equatable {
    case voice
    case text
    case system
}

enum ChatMessageStatus: String, Codable, Equatable {
    case sending
    case sent
    case failed
    case transcribing
    case streaming
}

struct ChatMessage: Codable, Equatable, Identifiable {
    let id: String
    let sessionID: String
    let speaker: ChatMessageSpeaker
    var text: String
    let createdAt: Date
    let inputType: ChatMessageInputType
    var status: ChatMessageStatus

    var transcriptLine: String {
        "\(speaker.displayName): \(text)"
    }
}

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
    let learningProfile: LearningProfile?
    let startedAt: Date
    let endedAt: Date
    let durationSeconds: TimeInterval
    let status: SessionState
    let summary: String
    let aiSummary: String?
    let aiSummaryStatus: SessionSummaryStatus?
    let messages: [ChatMessage]?
    let transcriptText: String?

    init(
        id: String,
        roomName: String,
        tutorSubject: String,
        learningProfile: LearningProfile? = nil,
        startedAt: Date,
        endedAt: Date,
        durationSeconds: TimeInterval,
        status: SessionState,
        summary: String,
        aiSummary: String?,
        aiSummaryStatus: SessionSummaryStatus?,
        messages: [ChatMessage]? = nil,
        transcriptText: String? = nil
    ) {
        self.id = id
        self.roomName = roomName
        self.tutorSubject = tutorSubject
        self.learningProfile = learningProfile
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
        self.status = status
        self.summary = summary
        self.aiSummary = aiSummary
        self.aiSummaryStatus = aiSummaryStatus
        self.messages = messages
        self.transcriptText = transcriptText
    }
}
