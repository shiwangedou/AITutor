import Foundation
import XCTest
@testable import AITutor

@MainActor
final class SessionViewModelTests: XCTestCase {
    func testConnectSuccessEnablesInput() async {
        let harness = makeHarness()

        await harness.viewModel.connect()

        XCTAssertEqual(harness.viewModel.currentState.sessionState, .connected)
        XCTAssertTrue(harness.viewModel.currentState.isStartEnabled)
        XCTAssertFalse(harness.viewModel.currentState.isConnectEnabled)
        XCTAssertEqual(harness.backend.createSessionCallCount, 1)
        XCTAssertEqual(harness.agent.connectCallCount, 1)
        XCTAssertEqual(harness.viewModel.currentState.primaryHint, "")
    }

    func testStartSessionWithDeniedMicrophoneShowsPermissionFailure() async {
        let harness = makeHarness()
        harness.audio.permission = .denied

        await harness.viewModel.connect()
        await harness.viewModel.startSession()

        XCTAssertEqual(harness.viewModel.currentState.sessionState, .microphonePermissionFailed)
        XCTAssertEqual(harness.agent.startMicrophoneCallCount, 0)
        XCTAssertTrue(harness.viewModel.currentState.errorText?.contains("Microphone permission") == true)
    }

    func testStartSessionPublishesMicrophoneAndEntersListening() async {
        let settings = InMemoryAppSettingsStore()
        settings.voiceInputMode = .manual
        let harness = makeHarness(appSettings: settings)

        await harness.viewModel.connect()
        await harness.viewModel.startSession()

        XCTAssertEqual(harness.viewModel.currentState.sessionState, .listening)
        XCTAssertEqual(harness.audio.configureCallCount, 1)
        XCTAssertEqual(harness.agent.startMicrophoneCallCount, 1)
        XCTAssertTrue(harness.viewModel.currentState.isEndEnabled)
        XCTAssertEqual(harness.viewModel.currentState.micButtonTitle, "Cancel voice input")
    }

    func testBackgroundVoiceAutoStartStartsMicrophoneBeforeEnteringBackgroundWhenEnabledAndGranted() async {
        let settings = InMemoryAppSettingsStore()
        settings.voiceInputMode = .automatic
        let harness = makeHarness(appSettings: settings)

        await harness.viewModel.connect()
        NotificationCenter.default.post(name: .appSceneWillResignActive, object: nil)
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(harness.audio.configureCallCount, 1)
        XCTAssertEqual(harness.agent.startMicrophoneCallCount, 1)
        XCTAssertEqual(harness.viewModel.currentState.sessionState, .listening)
    }

    func testBackgroundVoiceAutoStartStillHasDidEnterBackgroundFallback() async {
        let settings = InMemoryAppSettingsStore()
        settings.voiceInputMode = .automatic
        let harness = makeHarness(appSettings: settings)

        await harness.viewModel.connect()
        NotificationCenter.default.post(name: .appSceneDidEnterBackground, object: nil)
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(harness.audio.configureCallCount, 1)
        XCTAssertEqual(harness.agent.startMicrophoneCallCount, 1)
        XCTAssertEqual(harness.viewModel.currentState.sessionState, .listening)
    }

    func testBackgroundVoiceAutoStartDoesNothingInManualMode() async {
        let settings = InMemoryAppSettingsStore()
        settings.voiceInputMode = .manual
        let harness = makeHarness(appSettings: settings)

        await harness.viewModel.connect()
        NotificationCenter.default.post(name: .appSceneWillResignActive, object: nil)
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(harness.audio.configureCallCount, 0)
        XCTAssertEqual(harness.agent.startMicrophoneCallCount, 0)
        XCTAssertEqual(harness.viewModel.currentState.sessionState, .connected)
    }

    func testBackgroundVoiceAutoStartKeepsExistingContinuousMicrophoneWithoutRestart() async {
        let settings = InMemoryAppSettingsStore()
        settings.voiceInputMode = .automatic
        let harness = makeHarness(appSettings: settings)

        await harness.viewModel.connect()
        await harness.viewModel.startSession()
        NotificationCenter.default.post(name: .appSceneWillResignActive, object: nil)
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(harness.audio.configureCallCount, 1)
        XCTAssertEqual(harness.agent.startMicrophoneCallCount, 1)
        XCTAssertEqual(harness.viewModel.currentState.sessionState, .listening)
    }

    func testBackgroundVoiceAutoStartIsScopedToActiveChatOnly() async {
        let settings = InMemoryAppSettingsStore()
        settings.voiceInputMode = .automatic
        let harness = makeHarness(appSettings: settings)

        await harness.viewModel.connect()
        await harness.viewModel.leaveChat()
        NotificationCenter.default.post(name: .appSceneWillResignActive, object: nil)
        NotificationCenter.default.post(name: .appSceneDidEnterBackground, object: nil)
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(harness.audio.configureCallCount, 0)
        XCTAssertEqual(harness.agent.startMicrophoneCallCount, 0)
        XCTAssertEqual(harness.viewModel.currentState.sessionState, .ended)
    }

    func testAutomaticVoiceModeTogglesContinuousMicrophone() async {
        let settings = InMemoryAppSettingsStore()
        settings.voiceInputMode = .automatic
        let harness = makeHarness(appSettings: settings)

        await harness.viewModel.connect()
        await harness.viewModel.toggleAutomaticVoiceInput()

        XCTAssertTrue(harness.viewModel.currentState.isMicrophoneActive)
        XCTAssertEqual(harness.viewModel.currentState.voiceInputMode, .automatic)
        XCTAssertEqual(harness.agent.startMicrophoneCallCount, 1)

        await harness.viewModel.toggleAutomaticVoiceInput()

        XCTAssertFalse(harness.viewModel.currentState.isMicrophoneActive)
        XCTAssertEqual(harness.agent.stopMicrophoneCallCount, 1)
        XCTAssertEqual(harness.viewModel.currentState.sessionState, .connected)
    }

    func testSwitchingToManualStopsAutomaticContinuousMicrophone() async {
        let settings = InMemoryAppSettingsStore()
        settings.voiceInputMode = .automatic
        let harness = makeHarness(appSettings: settings)

        await harness.viewModel.connect()
        await harness.viewModel.toggleAutomaticVoiceInput()
        await harness.viewModel.setVoiceInputMode(.manual)

        XCTAssertEqual(settings.voiceInputMode, .manual)
        XCTAssertFalse(harness.viewModel.currentState.isMicrophoneActive)
        XCTAssertEqual(harness.agent.stopMicrophoneCallCount, 1)
        XCTAssertEqual(harness.viewModel.currentState.sessionState, .connected)
    }

    func testAutoVoiceShowsLearnerSpeechImmediately() async {
        let settings = InMemoryAppSettingsStore()
        settings.voiceInputMode = .automatic
        let harness = makeHarness(appSettings: settings)

        await harness.viewModel.connect()
        await harness.viewModel.startSession()
        harness.agent.emitTranscript(
            TranscriptUpdate(id: "auto-voice-1", speaker: .learner, text: "I am practicing automatically.", isFinal: true)
        )

        XCTAssertTrue(harness.viewModel.currentState.messages.contains { $0.text == "I am practicing automatically." })
        XCTAssertTrue(harness.viewModel.currentState.transcriptText.contains("I am practicing automatically."))
    }

    func testManualVoiceBuffersLearnerSpeechUntilSend() async {
        let settings = InMemoryAppSettingsStore()
        settings.voiceInputMode = .manual
        let harness = makeHarness(appSettings: settings)

        await harness.viewModel.connect()
        await harness.viewModel.startSession()
        harness.agent.emitTranscript(
            TranscriptUpdate(id: "manual-voice-1", speaker: .learner, text: "I want to send this later.", isFinal: true)
        )

        XCTAssertFalse(harness.viewModel.currentState.messages.contains { $0.text == "I want to send this later." })
        XCTAssertFalse(harness.viewModel.currentState.transcriptText.contains("I want to send this later."))

        await harness.viewModel.finishVoiceInput()

        XCTAssertTrue(harness.viewModel.currentState.messages.contains { $0.text == "I want to send this later." })
        XCTAssertTrue(harness.viewModel.currentState.transcriptText.contains("I want to send this later."))
        XCTAssertEqual(harness.viewModel.currentState.sessionState, .tutorThinking)
    }

    func testStopVoiceInputWithoutSpeechMutesMicrophoneAndReturnsToConnected() async {
        let harness = makeHarness()

        await harness.viewModel.connect()
        await harness.viewModel.startSession()
        await harness.viewModel.stopVoiceInput()

        XCTAssertEqual(harness.viewModel.currentState.sessionState, .connected)
        XCTAssertEqual(harness.agent.stopMicrophoneCallCount, 1)
        XCTAssertFalse(harness.agent.isMicrophoneStarted)
    }

    func testStopVoiceInputWithSpeechWaitsForTutor() async {
        let harness = makeHarness()

        await harness.viewModel.connect()
        await harness.viewModel.startSession()
        harness.agent.emitTranscript(
            TranscriptUpdate(id: "learner-speaking", speaker: .learner, text: "hello", isFinal: false)
        )
        await harness.viewModel.stopVoiceInput()

        XCTAssertEqual(harness.viewModel.currentState.sessionState, .tutorThinking)
        XCTAssertEqual(harness.agent.stopMicrophoneCallCount, 1)
        XCTAssertFalse(harness.agent.isMicrophoneStarted)
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

    func testReconnectFallsBackToNewSessionAndKeepsLocalMessages() async {
        let harness = makeHarness()

        await harness.viewModel.connect()
        await harness.viewModel.sendText("Hello from the first room.")
        harness.agent.connectErrors = [AppError.liveKitConnectFailed("stale room")]
        harness.backend.config = SessionConfig(
            sessionID: "new-session",
            issuedAt: 1_778_000_001,
            livekitURL: "wss://example.livekit.cloud",
            tutorSubject: "english-speaking",
            token: "redacted-new-token",
            roomName: "aitutor-new-room",
            participantIdentity: "user-new"
        )

        await harness.viewModel.reconnect()

        XCTAssertEqual(harness.backend.createSessionCallCount, 2)
        XCTAssertEqual(harness.agent.connectCallCount, 3)
        XCTAssertEqual(harness.viewModel.currentState.sessionState, .connected)
        XCTAssertTrue(harness.viewModel.currentState.connectionText.contains("aitutor-new-room"))
        XCTAssertTrue(harness.viewModel.currentState.messages.contains { $0.text == "Hello from the first room." })
        XCTAssertEqual(harness.backend.lastResumeContext?.sourceSessionID, "test-session")
        XCTAssertTrue(harness.backend.lastResumeContext?.transcriptExcerpt?.contains("Hello from the first room.") == true)
    }

    func testConnectSendsResumeContextWhenContinuingFromHistory() async {
        let context = SessionResumeContext(
            sourceSessionID: "old-session",
            summary: "Learner practiced ordering coffee.",
            aiSummary: "Main correction: use 'I'd like'.",
            transcriptExcerpt: "You: I want coffee.\nTutor: Say I'd like a coffee, please."
        )
        let harness = makeHarness(resumeContext: context)

        await harness.viewModel.connect()

        XCTAssertEqual(harness.backend.lastResumeContext, context)
        XCTAssertEqual(harness.viewModel.currentState.sessionState, .connected)
    }

    func testHistoryContinueSeedsPreviousMessagesInChat() async {
        let record = makeHistoryRecord()
        let context = SessionResumeContext.make(from: record)
        let harness = makeHarness(resumeContext: context, resumeRecord: record)

        XCTAssertTrue(harness.viewModel.currentState.messages.contains { $0.text == "I want coffee." })
        XCTAssertTrue(harness.viewModel.currentState.messages.contains { $0.text == "Say: I'd like a coffee, please." })

        await harness.viewModel.connect()

        XCTAssertEqual(harness.backend.lastResumeContext?.sourceSessionID, record.id)
        XCTAssertTrue(harness.viewModel.currentState.messages.contains { $0.text == "I want coffee." })
        XCTAssertTrue(harness.viewModel.currentState.latestSummaryText.contains("Previous:"))
    }

    func testHistoryContinueRestoresTranscriptTextWhenMessagesAreMissing() async {
        let record = makeHistoryRecordWithoutMessages()
        let context = SessionResumeContext.make(from: record)
        let harness = makeHarness(resumeContext: context, resumeRecord: record)

        XCTAssertTrue(harness.viewModel.currentState.messages.contains { $0.text == "I need a hotel room." })
        XCTAssertTrue(harness.viewModel.currentState.messages.contains { $0.text == "Try: I'd like to book a room." })
    }

    func testHistoryContinueExitWithoutNewContentDoesNotCreateNewRecord() async {
        let record = makeHistoryRecord()
        let context = SessionResumeContext.make(from: record)
        let harness = makeHarness(resumeContext: context, resumeRecord: record)

        await harness.viewModel.connect()
        await harness.viewModel.leaveChat()

        let records = harness.storage.loadRecentSessions()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.id, record.id)
        XCTAssertEqual(harness.agent.disconnectCallCount, 1)
        XCTAssertEqual(harness.viewModel.currentState.sessionState, .ended)
    }

    func testHistoryContinueWithNewTextUpdatesExistingSessionRecord() async {
        let record = makeHistoryRecord()
        let context = SessionResumeContext.make(from: record)
        let harness = makeHarness(resumeContext: context, resumeRecord: record)
        harness.backend.summaryError = AppError.backendUnavailable("offline in unit test")

        await harness.viewModel.connect()
        await harness.viewModel.sendText("Let's continue with another coffee order.")
        await harness.viewModel.endSession()

        let records = harness.storage.loadRecentSessions()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.id, record.id)
        XCTAssertEqual(records.first?.roomName, harness.backend.config.roomName)
        XCTAssertTrue(records.first?.durationSeconds ?? 0 > record.durationSeconds)
        XCTAssertTrue(records.first?.messages?.contains { $0.text == "I want coffee." } == true)
        XCTAssertTrue(records.first?.messages?.contains { $0.text == "Let's continue with another coffee order." } == true)
        XCTAssertTrue(records.first?.messages?.last?.sessionID == record.id)
        XCTAssertTrue(records.first?.transcriptText?.contains("You: I want coffee.") == true)
        XCTAssertTrue(records.first?.transcriptText?.contains("You: Let's continue with another coffee order.") == true)
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

    private func makeHarness(
        resumeContext: SessionResumeContext? = nil,
        resumeRecord: SessionRecord? = nil,
        appSettings: InMemoryAppSettingsStore = InMemoryAppSettingsStore()
    ) -> Harness {
        let backend = MockBackendClient()
        let agent = MockLiveKitAgentClient()
        let audio = MockAudioSessionManager()
        let storage = InMemorySessionStorage()
        if let resumeRecord {
            try? storage.save(resumeRecord)
        }
        let environment = AppEnvironment(
            backendClient: backend,
            agentClient: agent,
            audioManager: audio,
            sessionStorage: storage,
            learningProfileStore: InMemoryLearningProfileStore(),
            appSettingsStore: appSettings
        )
        let viewModel = SessionViewModel(
            environment: environment,
            resumeContext: resumeContext,
            resumeRecord: resumeRecord
        )
        return Harness(
            viewModel: viewModel,
            backend: backend,
            agent: agent,
            audio: audio,
            storage: storage
        )
    }

    private func makeHistoryRecord() -> SessionRecord {
        let startedAt = Date(timeIntervalSince1970: 1_778_000_000)
        let messages = [
            ChatMessage(
                id: "old-learner",
                sessionID: "old-session",
                speaker: .learner,
                text: "I want coffee.",
                createdAt: startedAt,
                inputType: .voice,
                status: .sent
            ),
            ChatMessage(
                id: "old-tutor",
                sessionID: "old-session",
                speaker: .tutor,
                text: "Say: I'd like a coffee, please.",
                createdAt: startedAt.addingTimeInterval(1),
                inputType: .voice,
                status: .sent
            )
        ]
        return SessionRecord(
            id: "old-session",
            roomName: "old-room",
            tutorSubject: "english-speaking",
            learningProfile: .default,
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(60),
            durationSeconds: 60,
            status: .ended,
            summary: "Learner practiced ordering coffee.",
            aiSummary: "Main correction: use I'd like.",
            aiSummaryStatus: .completed,
            messages: messages,
            transcriptText: messages.map(\.transcriptLine).joined(separator: "\n")
        )
    }

    private func makeHistoryRecordWithoutMessages() -> SessionRecord {
        let startedAt = Date(timeIntervalSince1970: 1_778_000_100)
        return SessionRecord(
            id: "old-transcript-session",
            roomName: "old-transcript-room",
            tutorSubject: "english-speaking",
            learningProfile: .default,
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(42),
            durationSeconds: 42,
            status: .ended,
            summary: "Learner practiced booking a hotel.",
            aiSummary: nil,
            aiSummaryStatus: .localOnly,
            messages: nil,
            transcriptText: "You: I need a hotel room.\nTutor: Try: I'd like to book a room."
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
    var lastResumeContext: SessionResumeContext?
    var createSessionError: Error?
    var summaryError: Error?
    var incrementalSummaryError: Error?

    func createSession(
        displayName: String,
        learningProfile: LearningProfile,
        resumeContext: SessionResumeContext?
    ) async throws -> SessionConfig {
        createSessionCallCount += 1
        lastResumeContext = resumeContext
        if let createSessionError {
            throw createSessionError
        }
        return SessionConfig(
            sessionID: config.sessionID,
            issuedAt: config.issuedAt,
            livekitURL: config.livekitURL,
            tutorSubject: config.tutorSubject,
            learningProfile: learningProfile,
            resumeContext: resumeContext,
            token: config.token,
            roomName: config.roomName,
            participantIdentity: config.participantIdentity
        )
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
    var stopMicrophoneCallCount = 0
    var sendTextCallCount = 0
    var disconnectCallCount = 0
    var connectErrors: [Error] = []
    var connectError: Error?
    var microphoneError: Error?
    var sentTexts: [String] = []
    private var transcriptHandlers: [UUID: (@MainActor (TranscriptUpdate) -> Void)] = [:]
    private var connectionHandlers: [UUID: (@MainActor (AgentConnectionEvent) -> Void)] = [:]

    @discardableResult
    func addTranscriptHandler(_ handler: @escaping @MainActor (TranscriptUpdate) -> Void) -> UUID {
        let id = UUID()
        transcriptHandlers[id] = handler
        return id
    }

    @discardableResult
    func addConnectionHandler(_ handler: @escaping @MainActor (AgentConnectionEvent) -> Void) -> UUID {
        let id = UUID()
        connectionHandlers[id] = handler
        return id
    }

    func removeTranscriptHandler(_ id: UUID) {
        transcriptHandlers[id] = nil
    }

    func removeConnectionHandler(_ id: UUID) {
        connectionHandlers[id] = nil
    }

    func connect(using config: SessionConfig) async throws {
        connectCallCount += 1
        if !connectErrors.isEmpty {
            throw connectErrors.removeFirst()
        }
        if let connectError {
            throw connectError
        }
        isConnected = true
        await MainActor.run {
            connectionHandlers.values.forEach { $0(AgentConnectionEvent(state: .connected, reason: "mock connected")) }
        }
    }

    func startMicrophone() async throws {
        startMicrophoneCallCount += 1
        if let microphoneError {
            throw microphoneError
        }
        isMicrophoneStarted = true
    }

    func stopMicrophone() async {
        stopMicrophoneCallCount += 1
        isMicrophoneStarted = false
    }

    func sendText(_ text: String) async throws {
        sendTextCallCount += 1
        sentTexts.append(text)
    }

    func disconnect() async {
        disconnectCallCount += 1
        isConnected = false
        isMicrophoneStarted = false
        await MainActor.run {
            connectionHandlers.values.forEach { $0(AgentConnectionEvent(state: .disconnected, reason: "mock disconnect")) }
        }
    }

    @MainActor
    func emitTranscript(_ update: TranscriptUpdate) {
        transcriptHandlers.values.forEach { $0(update) }
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

    func deleteSession(id: String) throws {
        records.removeAll { $0.id == id }
    }

    func clear() throws {
        records.removeAll()
    }
}

private final class InMemoryLearningProfileStore: LearningProfileStoring {
    private var profile = LearningProfile.default

    func loadDefaultProfile() -> LearningProfile {
        profile
    }

    func saveDefaultProfile(_ profile: LearningProfile) {
        self.profile = profile.normalized()
    }

    func resetDefaultProfile() {
        profile = .default
    }
}

private final class InMemoryAppSettingsStore: AppSettingsStoring {
    var voiceInputMode: VoiceInputMode = .automatic
}
