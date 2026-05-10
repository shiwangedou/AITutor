import Foundation

struct SessionConfig: Decodable, Equatable {
    let sessionID: String
    let issuedAt: Int?
    let livekitURL: String
    let tutorSubject: String
    let learningProfile: LearningProfile
    let resumeContext: SessionResumeContext?
    let token: String
    let roomName: String
    let participantIdentity: String

    init(
        sessionID: String,
        issuedAt: Int?,
        livekitURL: String,
        tutorSubject: String,
        learningProfile: LearningProfile = .default,
        resumeContext: SessionResumeContext? = nil,
        token: String,
        roomName: String,
        participantIdentity: String
    ) {
        self.sessionID = sessionID
        self.issuedAt = issuedAt
        self.livekitURL = livekitURL
        self.tutorSubject = tutorSubject
        self.learningProfile = learningProfile
        self.resumeContext = resumeContext
        self.token = token
        self.roomName = roomName
        self.participantIdentity = participantIdentity
    }

    enum CodingKeys: String, CodingKey {
        case sessionID = "session_id"
        case issuedAt = "issued_at"
        case livekitURL = "livekit_url"
        case tutorSubject = "tutor_subject"
        case learningProfile = "learning_profile"
        case resumeContext = "resume_context"
        case token
        case roomName = "room_name"
        case participantIdentity = "participant_identity"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionID = try container.decode(String.self, forKey: .sessionID)
        issuedAt = try container.decodeIfPresent(Int.self, forKey: .issuedAt)
        livekitURL = try container.decode(String.self, forKey: .livekitURL)
        tutorSubject = try container.decode(String.self, forKey: .tutorSubject)
        learningProfile = try container.decodeIfPresent(LearningProfile.self, forKey: .learningProfile) ?? .default
        resumeContext = try container.decodeIfPresent(SessionResumeContext.self, forKey: .resumeContext)
        token = try container.decode(String.self, forKey: .token)
        roomName = try container.decode(String.self, forKey: .roomName)
        participantIdentity = try container.decode(String.self, forKey: .participantIdentity)
    }
}
