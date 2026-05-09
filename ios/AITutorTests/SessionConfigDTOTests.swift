import Foundation
import XCTest
@testable import AITutor

final class SessionConfigDTOTests: XCTestCase {
    func testSessionConfigDecodesBackendPayload() throws {
        let json = """
        {
          "session_id": "abc-123",
          "issued_at": 1778000000,
          "livekit_url": "wss://aitutor.example.livekit.cloud",
          "tutor_subject": "english-speaking",
          "token": "redacted",
          "room_name": "aitutor-user-123",
          "participant_identity": "user-123"
        }
        """

        let config = try JSONDecoder().decode(SessionConfig.self, from: Data(json.utf8))

        XCTAssertEqual(config.sessionID, "abc-123")
        XCTAssertEqual(config.issuedAt, 1_778_000_000)
        XCTAssertEqual(config.livekitURL, "wss://aitutor.example.livekit.cloud")
        XCTAssertEqual(config.tutorSubject, "english-speaking")
        XCTAssertEqual(config.token, "redacted")
        XCTAssertEqual(config.roomName, "aitutor-user-123")
        XCTAssertEqual(config.participantIdentity, "user-123")
    }

    func testSummaryDisplayTextCombinesSections() {
        let response = SummaryGenerationResponse(
            summary: "You completed a short speaking practice.",
            strengths: ["Clear topic", "Good confidence"],
            corrections: ["Say 'I would like' instead of 'I want'"],
            nextSteps: ["Practice polite ordering"]
        )

        XCTAssertEqual(
            response.displayText,
            """
            You completed a short speaking practice.
            Strengths: Clear topic; Good confidence
            Corrections: Say 'I would like' instead of 'I want'
            Next steps: Practice polite ordering
            """
        )
    }
}
