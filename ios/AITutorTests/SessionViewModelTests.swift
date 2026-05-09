import Foundation
import XCTest
@testable import AITutor

@MainActor
final class SessionViewModelTests: XCTestCase {
    func testConnectSuccessEnablesStartAndKeepsTutorQuiet() async {
        let harness = makeHarness()

        await harness.viewModel.connect()

        XCTAssertEqual(harness.viewModel.currentState.sessionState, .connected)
        XCTAssertTrue(harness.viewModel.currentState.isStartEnabled)
        XCTAssertFalse(harness.viewModel.currentState.isConnectEnabled)
        XCTAssertEqual(harness.backend.createSessionCallCount, 1)
        XCTAssertEqual(harness.agent.connectCallCount, 1)
        XCTAssertEqual(harness.agent.startConversationCallCount, 0)
        XCTAssertTrue(harness.viewModel.currentState.logText.contains("Tap Start"))
    }

    func testStartSessionWithDeniedMicrophoneShowsPermissionFailure() async {
        let harness = makeHarness()
        harness.audio.permission = .denied

        await harness.viewModel.connect()
        await harness.viewModel.startSession()

        XCTAssertEqual(harness.viewModel.currentState.sessionState, .microphonePermissionFailed)
        XCTAssertEqual(harness.agent.startMicrophoneCallCount, 0)
        XCTAssertEqual(harness.agent.startConversationCallCount, 0)
        XCTAssertTrue(harness.viewModel.currentState.errorText?.contains("Microphone permission") == true)
    }

    func testStartSessionPublishesMicrophoneAndStartsTutor() async {
        let harness = makeHarness()

        await harness.viewModel.connect()
        await harness.viewModel.startSession()

        XCTAssertEqual(harness.viewModel.currentState.sessionState, .inSession)
        XCTAssertEqual(harness.audio.configureCallCount, 1)
        XCTAssertEqual(harness.agent.startMicrophoneCallCount, 1)
        XCTAssertEqual(harness.agent.startConversationCallCount, 1)
        XCTAssertTrue(harness.viewModel.currentState.isEndEnabled)
        XCTAssertFalse(harness.viewModel.currentState.isStartEnabled)
    }

    func testReconnectWithExistingSessionReusesCurrentRoom() async {
        let harness = makeHarness()

        await harness.viewModel.connect()
        await harness.viewModel.reconnect()

        XCTAssertEqual(harness.backend.createSessionCallCount, 1)
        XCTAssertEqual(harness.agent.disconnectCallCount, 1)
        XCTAssertEqual(harness.agent.connectCallCount, 2)
        XCTAssertEqual(harness.viewModel.currentState.sessionState, .connected)
        XCTAssertTrue(harness.viewModel.currentState.connectionText.contains("Reconnected room"))
    }

    func testEndSessionSavesLocalSummaryAndDisconnects() async {
        let harness = makeHarness()
        harness.backend.summaryError = AppError.backendUnavailable("offline in unit test")

        await harness.viewModel.connect()
        await harness.viewModel.startSession()
        harness.agent.emitTranscript(
            TranscriptUpdate(id: "learner-1", speaker: .learner, text: "I want to practice ordering coffee.", isFinal: true)
        )
        harness.agent.emitTranscript(
            TranscriptUpdate(id: "tutor-1", speaker: .tutor, text: "Good! Say: I'd like a coffee, please.", isFinal: true)
        )
        await harness.viewModel.endSession()

        let records = harness.storage.loadRecentSessions()
        XCTAssertEqual(harness.agent.disconnectCallCount, 1)
        XCTAssertEqual(harness.audio.deactivateCallCount, 1)
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0].status, .ended)
        XCTAssertEqual(records[0].roomName, harness.backend.config.roomName)
        XCTAssertTrue(records[0].summary.contains("learner 1, tutor 1"))
        XCTAssertTrue(records[0].summary.contains("Privacy: no raw audio was stored."))
    }

    func testTranscriptPartialIsReplacedByFinalText() async {
        let harness = makeHarness()

        await harness.viewModel.connect()
        await harness.viewModel.startSession()
        harness.agent.emitTranscript(
            TranscriptUpdate(id: "same-id", speaker: .learner, text: "Hell", isFinal: false)
        )
        harness.agent.emitTranscript(
            TranscriptUpdate(id: "same-id", speaker: .learner, text: "Hello", isFinal: true)
        )

        XCTAssertTrue(harness.viewModel.currentState.transcriptText.contains("You: Hello"))
        XCTAssertFalse(harness.viewModel.currentState.transcriptText.contains("Hell ..."))
    }

    private func makeHarness() -> Harness {
        let backend = MockBackendClient()
        let agent = MockLiveKitAgentClient()
        let audio = MockAudioSessionManager()
        let storage = InMemorySessionStorage()
        let environment = AppEnvironment(
            backendClient: backend,
            agentClient: agent,
            audioManager: audio,
            sessionStorage: storage
        )
        let viewModel = SessionViewModel(environment: environment)
        return Harness(
            viewModel: viewModel,
            backend: backend,
            agent: agent,
            audio: audio,
            storage: storage
        )
    }
}

@MainActor
private final class Harness {
    let viewModel: SessionViewModel
    let backend: MockBackendClient
    let agent: MockLiveKitAgentClient
    let audio: MockAudioSessionManager
    let storage: InMemorySessionStorage

    init(
        viewModel: SessionViewModel,
        backend: MockBackendClient,
        agent: MockLiveKitAgentClient,
        audio: MockAudioSessionManager,
        storage: InMemorySessionStorage
    ) {
        self.viewModel = viewModel
        self.backend = backend
        self.agent = agent
        self.audio = audio
        self.storage = storage
    }
}

private final class MockBackendClient: BackendAPIClientProtocol {
    var config = SessionConfig(
        sessionID: "test-session",
        issuedAt: 1_778_000_000,
        livekitURL: "wss://example.livekit.cloud",
        tutorSubject: "english-speaking",
        token: "redacted-test-token",
        roomName: "aitutor-test-room",
        participantIdentity: "user-test"
    )
    var createSessionCallCount = 0
    var summaryCallCount = 0
    var incrementalSummaryCallCount = 0
    var createSessionError: Error?
    var summaryError: Error?
    var incrementalSummaryError: Error?

    func createSession(displayName: String) async throws -> SessionConfig {
        createSessionCallCount += 1
        if let createSessionError {
            throw createSessionError
        }
        return config
    }

    func generateSummary(_ request: SummaryGenerationRequest) async throws -> SummaryGenerationResponse {
        summaryCallCount += 1
        if let summaryError {
            throw summaryError
        }
        return SummaryGenerationResponse(
            summary: "Practice completed.",
            strengths: ["Clear intent"],
            corrections: ["Use please for politeness"],
            nextSteps: ["Practice one more coffee order"]
        )
    }

    func generateIncrementalSummary(_ request: IncrementalSummaryGenerationRequest) async throws -> SummaryGenerationResponse {
        incrementalSummaryCallCount += 1
        if let incrementalSummaryError {
            throw incrementalSummaryError
        }
        return SummaryGenerationResponse(
            summary: "Draft summary updated.",
            strengths: [],
            corrections: [],
            nextSteps: []
        )
    }
}

private final class MockLiveKitAgentClient: LiveKitAgentControlling {
    var isConnected = false
    var isMicrophoneStarted = false
    var diagnosticSummary = "mock-livekit"
    var connectCallCount = 0
    var startMicrophoneCallCount = 0
    var startConversationCallCount = 0
    var sendTextCallCount = 0
    var disconnectCallCount = 0
    var connectError: Error?
    var microphoneError: Error?
    var startConversationError: Error?
    var sentTexts: [String] = []
    private var transcriptHandler: (@MainActor (TranscriptUpdate) -> Void)?

    func setTranscriptHandler(_ handler: @escaping @MainActor (TranscriptUpdate) -> Void) {
        transcriptHandler = handler
    }

    func connect(using config: SessionConfig) async throws {
        connectCallCount += 1
        if let connectError {
            throw connectError
        }
        isConnected = true
    }

    func startMicrophone() async throws {
        startMicrophoneCallCount += 1
        if let microphoneError {
            throw microphoneError
        }
        isMicrophoneStarted = true
    }

    func startConversation() async throws {
        startConversationCallCount += 1
        if let startConversationError {
            throw startConversationError
        }
    }

    func sendText(_ text: String) async throws {
        sendTextCallCount += 1
        sentTexts.append(text)
    }

    func disconnect() async {
        disconnectCallCount += 1
        isConnected = false
        isMicrophoneStarted = false
    }

    @MainActor
    func emitTranscript(_ update: TranscriptUpdate) {
        transcriptHandler?(update)
    }
}

private final class MockAudioSessionManager: AudioSessionManaging {
    var permission: MicrophonePermissionStatus = .granted
    var configureCallCount = 0
    var deactivateCallCount = 0
    var configureError: Error?

    func microphonePermissionStatus() -> MicrophonePermissionStatus {
        permission
    }

    func requestMicrophonePermission() async -> MicrophonePermissionStatus {
        permission
    }

    func configureForVoiceChat() throws {
        configureCallCount += 1
        if let configureError {
            throw configureError
        }
    }

    func diagnosticSummary() -> String {
        "mock-audio permission=\(permission.rawValue)"
    }

    func deactivate() {
        deactivateCallCount += 1
    }
}

private final class InMemorySessionStorage: SessionStorageManaging {
    private(set) var records: [SessionRecord] = []

    func loadRecentSessions() -> [SessionRecord] {
        records
    }

    func save(_ record: SessionRecord) throws {
        records.removeAll { $0.id == record.id }
        records.insert(record, at: 0)
        records = Array(records.prefix(20))
    }

    func clear() throws {
        records.removeAll()
    }
}
