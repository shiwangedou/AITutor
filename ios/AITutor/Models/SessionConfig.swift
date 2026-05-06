import Foundation

struct SessionConfig: Decodable {
    let livekitURL: String
    let tutorSubject: String
    let token: String
    let roomName: String
    let participantIdentity: String

    enum CodingKeys: String, CodingKey {
        case livekitURL = "livekit_url"
        case tutorSubject = "tutor_subject"
        case token
        case roomName = "room_name"
        case participantIdentity = "participant_identity"
    }
}
