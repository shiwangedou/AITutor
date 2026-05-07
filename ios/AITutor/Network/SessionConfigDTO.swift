import Foundation

struct SessionConfig: Decodable, Equatable {
    let sessionID: String
    let issuedAt: Int?
    let livekitURL: String
    let tutorSubject: String
    let token: String
    let roomName: String
    let participantIdentity: String

    enum CodingKeys: String, CodingKey {
        case sessionID = "session_id"
        case issuedAt = "issued_at"
        case livekitURL = "livekit_url"
        case tutorSubject = "tutor_subject"
        case token
        case roomName = "room_name"
        case participantIdentity = "participant_identity"
    }
}
