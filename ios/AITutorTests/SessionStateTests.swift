import XCTest
@testable import AITutor

final class SessionStateTests: XCTestCase {
    func testFailureStateMappingKeepsUserFacingFailuresSpecific() {
        XCTAssertEqual(SessionState.failureState(for: .backendUnavailable("offline")), .backendFailed)
        XCTAssertEqual(SessionState.failureState(for: .sessionTokenFailed("bad token")), .backendFailed)
        XCTAssertEqual(SessionState.failureState(for: .liveKitConnectFailed("join failed")), .liveKitFailed)
        XCTAssertEqual(SessionState.failureState(for: .microphonePermissionDenied), .microphonePermissionFailed)
        XCTAssertEqual(SessionState.failureState(for: .audioSessionFailed("route")), .audioSessionFailed)
        XCTAssertEqual(SessionState.failureState(for: .microphonePublishFailed("track")), .microphonePublishFailed)
        XCTAssertEqual(SessionState.failureState(for: .storageFailed("disk")), .storageFailed)
        XCTAssertEqual(SessionState.failureState(for: .unknown("Text send failed: topic missing")), .textSendFailed)
    }

    func testIsFailureOnlyMatchesTerminalFailureStates() {
        XCTAssertFalse(SessionState.idle.isFailure)
        XCTAssertFalse(SessionState.connected.isFailure)
        XCTAssertFalse(SessionState.inSession.isFailure)
        XCTAssertFalse(SessionState.ended.isFailure)
        XCTAssertTrue(SessionState.backendFailed.isFailure)
        XCTAssertTrue(SessionState.liveKitFailed.isFailure)
        XCTAssertTrue(SessionState.microphonePermissionFailed.isFailure)
    }
}
