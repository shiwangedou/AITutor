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
          "learning_profile": {
            "learning_mode": "interview_english",
            "tutor_style": "challenge_coach",
            "difficulty": "advanced",
            "custom_goal": "Practice concise interview answers."
          },
          "resume_context": {
            "source_session_id": "old-session",
            "summary": "Learner practiced interview intros.",
            "ai_summary": "Focus on concise answers.",
            "transcript_excerpt": "You: I am engineer.\\nTutor: Say I am an engineer."
          },
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
        XCTAssertEqual(config.learningProfile.learningMode, .interviewEnglish)
        XCTAssertEqual(config.learningProfile.tutorStyle, .challengeCoach)
        XCTAssertEqual(config.learningProfile.difficulty, .advanced)
        XCTAssertEqual(config.learningProfile.customGoal, "Practice concise interview answers.")
        XCTAssertEqual(config.resumeContext?.sourceSessionID, "old-session")
        XCTAssertEqual(config.resumeContext?.summary, "Learner practiced interview intros.")
        XCTAssertEqual(config.resumeContext?.aiSummary, "Focus on concise answers.")
        XCTAssertEqual(config.resumeContext?.transcriptExcerpt, "You: I am engineer.\nTutor: Say I am an engineer.")
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

    func testResumeContextFromRecordUsesLatestTranscriptLines() {
        let messages = (1...10).map { index in
            ChatMessage(
                id: "m-\(index)",
                sessionID: "session-1",
                speaker: index.isMultiple(of: 2) ? .tutor : .learner,
                text: "turn \(index)",
                createdAt: Date(timeIntervalSince1970: TimeInterval(index)),
                inputType: .text,
                status: .sent
            )
        }
        let record = SessionRecord(
            id: "session-1",
            roomName: "room-1",
            tutorSubject: "english-speaking",
            learningProfile: .default,
            startedAt: Date(timeIntervalSince1970: 1),
            endedAt: Date(timeIntervalSince1970: 2),
            durationSeconds: 1,
            status: .ended,
            summary: "Local summary.",
            aiSummary: "AI summary.",
            aiSummaryStatus: .completed,
            messages: messages,
            transcriptText: nil
        )

        let context = SessionResumeContext.make(from: record)

        XCTAssertEqual(context.sourceSessionID, "session-1")
        XCTAssertEqual(context.summary, "Local summary.")
        XCTAssertEqual(context.aiSummary, "AI summary.")
        let transcriptLines = context.transcriptExcerpt?.components(separatedBy: "\n") ?? []
        XCTAssertFalse(transcriptLines.contains("You: turn 1"))
        XCTAssertTrue(transcriptLines.contains("Tutor: turn 10"))
    }
}
