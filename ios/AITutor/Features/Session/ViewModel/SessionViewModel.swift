import Foundation

@MainActor
final class SessionViewModel {
    var onStateChange: ((SessionViewState) -> Void)?
    var currentState: SessionViewState { state }

    private let backendClient: BackendAPIClientProtocol
    private let agentClient: LiveKitAgentControlling
    private let audioManager: AudioSessionManaging
    private let storage: SessionStorageManaging
    private let appSettings: AppSettingsStoring

    private var state = SessionViewState()
    private var learningProfile: LearningProfile
    private var resumeContext: SessionResumeContext?
    private let historyRecord: SessionRecord?
    private let isHistoryContinuation: Bool
    private var currentConfig: SessionConfig?
    private var sessionStartedAt: Date?
    private var logItems: [SessionLogItem] = []
    private var transcriptItems: [SessionTranscriptItem] = []
    private var chatMessages: [ChatMessage] = []
    private var pendingSummaryTurns: [String] = []
    private var queuedSummaryTranscriptIDs = Set<String>()
    private var runningAISummary: String?
    private var isIncrementalSummaryGenerating = false
    private var lastIncrementalSummaryAt: Date?
    private var lifecycleObservers: [NSObjectProtocol] = []
    private var finalSummaryTask: Task<Void, Never>?
    private var incrementalSummaryTask: Task<Void, Never>?
    private var autoReconnectTask: Task<Void, Never>?
    private var microphoneWarmupTask: Task<Void, Never>?
    private var backgroundVoiceAutoStartInFlight = false
    private var activeSummaryGenerationID: UUID?
    private var isChatLifecycleActive = true
    private var suppressAutoReconnect = false
    private var isLeavingChat = false
    private var hasVoiceInputInCurrentRecording = false
    private var manualVoiceDraftID: String?
    private var manualVoiceDraftText: String?
    private var hasNewSessionContent = false
    private var autoReconnectAttempts = 0
    private let incrementalSummaryTurnThreshold = 4
    private let incrementalSummaryMinInterval: TimeInterval = 20
    private let maxAutoReconnectAttempts = 2
    private var transcriptHandlerID: UUID?
    private var connectionHandlerID: UUID?

    init(
        environment: AppEnvironment,
        learningProfile: LearningProfile = .default,
        resumeContext: SessionResumeContext? = nil,
        resumeRecord: SessionRecord? = nil
    ) {
        self.backendClient = environment.backendClient
        self.agentClient = environment.agentClient
        self.audioManager = environment.audioManager
        self.storage = environment.sessionStorage
        self.appSettings = environment.appSettingsStore
        self.state.voiceInputMode = environment.appSettingsStore.voiceInputMode
        self.learningProfile = learningProfile.normalized()
        self.resumeContext = resumeContext?.hasContent == true ? resumeContext : nil
        self.historyRecord = resumeRecord
        self.isHistoryContinuation = resumeRecord != nil
        self.state.profileText = self.learningProfile.summaryLine
        refreshLatestSummary()
        if let resumeRecord {
            seedResumeRecord(resumeRecord)
        }
        self.transcriptHandlerID = self.agentClient.addTranscriptHandler { [weak self] update in
            self?.handleTranscript(update)
        }
        self.connectionHandlerID = self.agentClient.addConnectionHandler { [weak self] event in
            self?.handleConnectionEvent(event)
        }
        appendInfo("Backend: \(AppConfig.backendBaseURL.absoluteString)", category: .network)
        appendInfo("Privacy: raw audio is not stored; only local text, metadata, and summaries are saved.", category: .session)
        appendInfo("Learning profile: \(self.learningProfile.summaryLine)", category: .session)
        if self.resumeContext?.hasContent == true {
            appendInfo("Resume context prepared from History. It will be sent as short text context only.", category: .session)
        }
        observeSceneLifecycle()
        publish()
    }

    deinit {
        let transcriptHandlerID = self.transcriptHandlerID
        let connectionHandlerID = self.connectionHandlerID
        let agentClient = self.agentClient
        Task { @MainActor in
            if let transcriptHandlerID {
                agentClient.removeTranscriptHandler(transcriptHandlerID)
            }
            if let connectionHandlerID {
                agentClient.removeConnectionHandler(connectionHandlerID)
            }
        }
        finalSummaryTask?.cancel()
        incrementalSummaryTask?.cancel()
        autoReconnectTask?.cancel()
        microphoneWarmupTask?.cancel()
        lifecycleObservers.forEach(NotificationCenter.default.removeObserver)
    }

    func connect() async {
        isChatLifecycleActive = true
        isLeavingChat = false
        cancelSummaryWork(resetDraft: false)
        setSessionState(.connecting)
        state.errorText = nil
        appendInfo("Requesting session config from backend...", category: .network)

        do {
            let config = try await backendClient.createSession(
                displayName: "Learner",
                learningProfile: learningProfile,
                resumeContext: resumeContext
            )
            guard !isLeavingChat else {
                setSessionState(.ended)
                state.connectionText = "Ended"
                appendInfo("Connect cancelled because Chat was closed before LiveKit join.", category: .session)
                return
            }
            currentConfig = config
            learningProfile = config.learningProfile.normalized()
            state.profileText = learningProfile.summaryLine
            resumeContext = config.resumeContext?.hasContent == true ? config.resumeContext : resumeContext
            appendInfo("Room: \(config.roomName)", category: .session)
            try await agentClient.connect(using: config)
            guard !isLeavingChat else {
                suppressAutoReconnect = true
                await agentClient.disconnect()
                setSessionState(.ended)
                state.connectionText = "Ended"
                appendInfo("Disconnected after Chat was closed during LiveKit connect.", category: .session)
                return
            }
            setSessionState(.connected)
            state.connectionText = "Connected room: \(config.roomName)"
            state.primaryHint = ""
            if resumeContext?.hasContent == true {
                appendInfo("Connected to LiveKit with resume context. Tutor will wait for the learner to continue.", category: .livekit)
            } else {
                appendInfo("Connected to LiveKit. Tutor should open the first empty chat turn.", category: .livekit)
            }
        } catch {
            handleFailure("Connect failed", error: error, category: .session)
        }
    }

    func startSession() async {
        guard currentConfig != nil else {
            handleFailure("Start failed", error: AppError.sessionTokenFailed("No active session config"), category: .session)
            return
        }

        do {
            appendInfo("Audio before permission: \(audioManager.diagnosticSummary())", category: .audio)
            let permission = await audioManager.requestMicrophonePermission()
            appendInfo("Microphone permission: \(permission.rawValue)", category: .audio)
            guard permission == .granted else {
                throw AppError.microphonePermissionDenied
            }

            try audioManager.configureForVoiceChat()
            appendInfo("Audio configured: \(audioManager.diagnosticSummary())", category: .audio)
            try await agentClient.startMicrophone()
            if sessionStartedAt == nil {
                sessionStartedAt = Date()
            }
            hasVoiceInputInCurrentRecording = false
            resetManualVoiceDraft()
            state.isMicrophoneActive = true
            state.runningSummaryText = "Draft waiting for transcript. It will update after 4 final turns."
            setSessionState(.listening)
            state.primaryHint = ""
            appendInfo("Microphone is active. Tutor will respond after learner speech.", category: .livekit)
            scheduleMicrophoneWarmupCheck()
        } catch {
            handleFailure("Start failed", error: error, category: .session)
            appendError("Audio after failure: \(audioManager.diagnosticSummary())", category: .audio)
        }
    }

    func stopVoiceInput() async {
        await finishVoiceInput()
    }

    func finishVoiceInput() async {
        guard state.sessionState == .listening else { return }
        cancelMicrophoneWarmupCheck()
        await agentClient.stopMicrophone()
        state.isMicrophoneActive = false
        let flushedManualVoice = flushManualVoiceDraftIfNeeded()
        if hasVoiceInputInCurrentRecording || flushedManualVoice {
            setSessionState(.tutorThinking)
            appendInfo("Voice input sent. Waiting for tutor response.", category: .session)
        } else {
            setSessionState(.connected)
            appendInfo("Voice input closed without detected speech.", category: .session)
        }
        state.primaryHint = ""
        hasVoiceInputInCurrentRecording = false
        resetManualVoiceDraft()
    }

    func cancelVoiceInput() async {
        guard state.sessionState == .listening else { return }
        cancelMicrophoneWarmupCheck()
        await agentClient.stopMicrophone()
        state.isMicrophoneActive = false
        hasVoiceInputInCurrentRecording = false
        resetManualVoiceDraft()
        setSessionState(.connected)
        state.primaryHint = ""
        appendInfo("Voice input cancelled.", category: .session)
    }

    func sendText(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        guard canSendInput else {
            handleFailure("Text send failed", error: AppError.liveKitConnectFailed("Connect to LiveKit before sending text"), category: .session)
            return
        }

        if sessionStartedAt == nil {
            sessionStartedAt = Date()
        }
        hasNewSessionContent = true

        let messageID = "typed-\(UUID().uuidString)"
        appendChatMessage(
            ChatMessage(
                id: messageID,
                sessionID: localSessionID,
                speaker: .learner,
                text: trimmed,
                createdAt: Date(),
                inputType: .text,
                status: .sending
            )
        )
        appendTranscript(id: messageID, speaker: .learner, text: trimmed, isFinal: true, inputType: .text)

        do {
            try await agentClient.sendText(trimmed)
            updateMessageStatus(id: messageID, status: .sent)
            setSessionState(.tutorThinking)
            state.primaryHint = ""
            appendInfo("Text sent to tutor agent.", category: .livekit)
        } catch {
            updateMessageStatus(id: messageID, status: .failed)
            handleFailure("Text send failed", error: error, category: .livekit)
        }
    }

    func endSession() async {
        isChatLifecycleActive = false
        suppressAutoReconnect = true
        autoReconnectTask?.cancel()
        let endedConfig = currentConfig
        let startedAt = sessionStartedAt
        let finalTranscriptItems = transcriptItems
        let finalMessages = chatMessages
        let summaryGenerationID = UUID()
        activeSummaryGenerationID = summaryGenerationID
        incrementalSummaryTask?.cancel()
        incrementalSummaryTask = nil
        isIncrementalSummaryGenerating = false

        await agentClient.disconnect()
        state.isMicrophoneActive = false
        audioManager.deactivate()
        guard shouldSaveEndedSession else {
            currentConfig = nil
            sessionStartedAt = nil
            setSessionState(.ended)
            state.connectionText = "Ended"
            state.runningSummaryText = "Previous session was reviewed. No new practice content was saved."
            appendInfo("History continuation closed without new learner/tutor content; no new session record saved.", category: .session)
            return
        }
        saveLocalSummary(
            status: .ended,
            config: endedConfig,
            startedAt: startedAt,
            transcriptItems: finalTranscriptItems,
            messages: finalMessages
        )
        currentConfig = nil
        sessionStartedAt = nil
        setSessionState(.ended)
        state.connectionText = "Ended"
        state.runningSummaryText = "Final summary generating when transcript text is available. Local summary is already saved."
        appendInfo("Session ended. Local summary saved; AI summary generation started when available.", category: .session)

        if let endedConfig {
            let endedAt = Date()
            let localRecordID = localRecordID(for: endedConfig)
            let recordStartedAt = savedStartedAt(fallback: startedAt ?? endedAt)
            let recordDuration = durationForSavedRecord(startedAt: startedAt, endedAt: endedAt)
            let transcript = transcriptText(from: finalMessages)
            let localSummary = makeLocalSummary(
                subject: endedConfig.tutorSubject,
                profile: endedConfig.learningProfile,
                duration: recordDuration,
                transcriptItems: chatTranscriptItems(from: finalMessages)
            )
            let backendClient = self.backendClient
            let storage = self.storage
            let runningSummary = runningAISummary
            finalSummaryTask?.cancel()
            finalSummaryTask = Task { @MainActor [weak self, backendClient, storage] in
                let result: (SessionSummaryStatus, String?)
                if transcript.isEmpty {
                    result = (.unavailable, "AI summary skipped because no final transcript was available.")
                } else {
                    do {
                        self?.state.runningSummaryText = "Final summary generating from transcript text..."
                        self?.publish()
                        let response = try await backendClient.generateSummary(
                            SummaryGenerationRequest(
                                sessionID: endedConfig.sessionID,
                                tutorSubject: endedConfig.tutorSubject,
                                durationSeconds: recordDuration,
                                transcript: transcript,
                                runningSummary: runningSummary,
                                learningProfile: endedConfig.learningProfile
                            )
                        )
                        result = (.completed, response.displayText)
                    } catch {
                        result = (.unavailable, "AI summary endpoint is not available yet. Local summary is saved.")
                    }
                }

                guard storage.loadRecentSessions().contains(where: { $0.id == localRecordID }) else {
                    AppLogger.debug("Skipped final AI summary save because session record no longer exists.", category: .storage)
                    return
                }

                let record = SessionRecord(
                    id: localRecordID,
                    roomName: endedConfig.roomName,
                    tutorSubject: endedConfig.tutorSubject,
                    learningProfile: endedConfig.learningProfile,
                    startedAt: recordStartedAt,
                    endedAt: endedAt,
                    durationSeconds: recordDuration,
                    status: .ended,
                    summary: localSummary,
                    aiSummary: result.1,
                    aiSummaryStatus: result.0,
                    messages: finalMessages,
                    transcriptText: transcript
                )

                do {
                    try storage.save(record)
                    AppLogger.debug("Final AI summary saved for session=\(localRecordID)", category: .storage)
                } catch {
                    AppLogger.error("Final AI summary save failed: \(AppLogger.describe(error))", category: .storage)
                }

                guard let self,
                      self.activeSummaryGenerationID == summaryGenerationID,
                      self.currentConfig == nil,
                      self.state.sessionState == .ended else {
                    return
                }
                self.refreshLatestSummary()
                self.state.runningSummaryText = result.1 ?? "Final AI summary unavailable. Local summary is saved."
                self.publish()
            }
        }
    }

    func leaveChat() async {
        isChatLifecycleActive = false
        isLeavingChat = true
        suppressAutoReconnect = true
        autoReconnectTask?.cancel()
        guard currentConfig != nil || agentClient.isConnected else {
            setSessionState(.ended)
            state.connectionText = "Ended"
            return
        }
        await endSession()
    }

    private var shouldSaveEndedSession: Bool {
        !isHistoryContinuation || hasNewSessionContent
    }

    private var localSessionID: String {
        historyRecord?.id ?? currentConfig?.sessionID ?? "pending"
    }

    private func localRecordID(for config: SessionConfig) -> String {
        historyRecord?.id ?? config.sessionID
    }

    private func savedStartedAt(fallback: Date) -> Date {
        historyRecord?.startedAt ?? fallback
    }

    private func durationForSavedRecord(startedAt: Date?, endedAt: Date) -> TimeInterval {
        let currentDuration = max(0, endedAt.timeIntervalSince(startedAt ?? endedAt))
        return (historyRecord?.durationSeconds ?? 0) + currentDuration
    }

    func reconnect() async {
        isLeavingChat = false
        autoReconnectTask?.cancel()
        suppressAutoReconnect = false
        appendInfo("Reconnect requested.", category: .session)
        setSessionState(.reconnecting)
        suppressAutoReconnect = true
        await agentClient.disconnect()
        state.isMicrophoneActive = false
        audioManager.deactivate()
        suppressAutoReconnect = false

        if let config = currentConfig {
            do {
                try await agentClient.connect(using: config)
                setSessionState(.connected)
                state.connectionText = "Reconnected room: \(config.roomName)"
                appendInfo("Reconnected to current LiveKit room.", category: .livekit)
            } catch {
                appendError(
                    "Reconnect to current room failed: \(AppLogger.describe(error)). Creating a new LiveKit room while keeping local chat visible.",
                    category: .livekit
                )
                resumeContext = makeActiveSessionResumeContext(config: config) ?? resumeContext
                currentConfig = nil
                state.connectionText = "Reconnect failed. Creating a new room..."
                state.errorText = nil
                await connect()
            }
        } else {
            await connect()
        }
    }

    func clearHistory() {
        do {
            cancelSummaryWork(resetDraft: true)
            try storage.clear()
            refreshLatestSummary()
            appendInfo("Local session history cleared.", category: .storage)
        } catch {
            handleFailure("Clear history failed", error: error, category: .storage)
        }
    }

    private var canSendInput: Bool {
        switch state.sessionState {
        case .connected, .inSession, .listening, .tutorThinking, .tutorSpeaking:
            return true
        default:
            return false
        }
    }

    func setVoiceInputMode(_ mode: VoiceInputMode) async {
        let previousMode = appSettings.voiceInputMode
        appSettings.voiceInputMode = mode
        state.voiceInputMode = mode
        refreshVoiceInputPresentation()
        appendInfo("Voice input mode set to \(mode.displayName).", category: .session)

        if previousMode == .automatic, mode == .manual, state.isMicrophoneActive {
            await agentClient.stopMicrophone()
            state.isMicrophoneActive = false
            hasVoiceInputInCurrentRecording = false
            resetManualVoiceDraft()
            if state.sessionState == .listening {
                setSessionState(.connected)
            }
            appendInfo("Automatic continuous voice stopped after switching to Manual Voice.", category: .audio)
        }
        publish()
    }

    func toggleAutomaticVoiceInput() async {
        if state.isMicrophoneActive {
            cancelMicrophoneWarmupCheck()
            await agentClient.stopMicrophone()
            state.isMicrophoneActive = false
            hasVoiceInputInCurrentRecording = false
            resetManualVoiceDraft()
            setSessionState(.connected)
            appendInfo("Automatic continuous voice stopped.", category: .audio)
            return
        }

        await startSession()
        if state.sessionState == .listening {
            appendInfo("Automatic continuous voice started. LiveKit STT/turn detection will auto-submit speech.", category: .audio)
        }
    }

    private func handleConnectionEvent(_ event: AgentConnectionEvent) {
        guard currentConfig != nil else { return }

        switch event.state {
        case .connecting:
            if state.sessionState != .connecting {
                setSessionState(.connecting)
            }
            state.connectionText = "Connecting..."
            state.primaryHint = ""
        case .reconnecting:
            setSessionState(.reconnecting)
            state.connectionText = "Reconnecting..."
            state.primaryHint = ""
            appendInfo(event.reason ?? "LiveKit is reconnecting.", category: .livekit)
        case .connected:
            suppressAutoReconnect = false
            autoReconnectAttempts = 0
            autoReconnectTask?.cancel()
            if state.sessionState == .connecting || state.sessionState == .reconnecting || state.sessionState.isFailure {
                setSessionState(.connected)
            }
            state.connectionText = currentConfig.map { "Connected room: \($0.roomName)" } ?? "Connected"
            state.primaryHint = ""
            appendInfo(event.reason ?? "LiveKit connected.", category: .livekit)
        case .disconnecting:
            state.connectionText = "Disconnecting..."
            state.primaryHint = ""
            publish()
        case .disconnected:
            state.isMicrophoneActive = false
            guard !suppressAutoReconnect, state.sessionState != .ended else {
                state.connectionText = "Disconnected"
                publish()
                return
            }
            setSessionState(.liveKitFailed)
            state.connectionText = "Disconnected. Reconnecting..."
            state.errorText = event.reason.map { "Connection lost: \($0)" } ?? "Connection lost."
            scheduleAutoReconnect()
        }
        publish()
    }

    private func scheduleAutoReconnect() {
        guard currentConfig != nil else { return }
        guard autoReconnectAttempts < maxAutoReconnectAttempts else {
            state.primaryHint = ""
            state.isReconnectEnabled = true
            publish()
            return
        }

        autoReconnectAttempts += 1
        let attempt = autoReconnectAttempts
        autoReconnectTask?.cancel()
        autoReconnectTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 800_000_000)
            guard let self, !Task.isCancelled else { return }
            self.appendInfo("Auto reconnect attempt \(attempt).", category: .livekit)
            await self.reconnect()
        }
    }

    private func makeActiveSessionResumeContext(config: SessionConfig) -> SessionResumeContext? {
        let recentMessages = chatMessages
            .filter { $0.speaker == .learner || $0.speaker == .tutor }
            .suffix(SessionResumeContext.transcriptLineLimit)
        let transcriptExcerpt = recentMessages.map(\.transcriptLine).joined(separator: "\n")
        let duration = max(0, Date().timeIntervalSince(sessionStartedAt ?? Date()))
        let summary = makeLocalSummary(
            subject: config.tutorSubject,
            profile: config.learningProfile,
            duration: duration,
            transcriptItems: transcriptItems
        )
        let context = SessionResumeContext(
            sourceSessionID: config.sessionID,
            summary: summary,
            aiSummary: runningAISummary,
            transcriptExcerpt: transcriptExcerpt.isEmpty ? nil : transcriptExcerpt
        )
        return context.hasContent ? context : nil
    }

    private func saveLocalSummary(
        status: SessionState,
        config: SessionConfig?,
        startedAt: Date?,
        transcriptItems: [SessionTranscriptItem],
        messages: [ChatMessage]
    ) {
        guard let config else { return }

        let startedAt = startedAt ?? Date()
        let endedAt = Date()
        let duration = durationForSavedRecord(startedAt: startedAt, endedAt: endedAt)
        let recordID = localRecordID(for: config)
        let transcriptSourceItems = chatTranscriptItems(from: messages)
        let transcriptText = transcriptText(from: messages)
        let summary = makeLocalSummary(
            subject: config.tutorSubject,
            profile: config.learningProfile,
            duration: duration,
            transcriptItems: transcriptSourceItems
        )
        let record = SessionRecord(
            id: recordID,
            roomName: config.roomName,
            tutorSubject: config.tutorSubject,
            learningProfile: config.learningProfile,
            startedAt: savedStartedAt(fallback: startedAt),
            endedAt: endedAt,
            durationSeconds: duration,
            status: status,
            summary: summary,
            aiSummary: runningAISummary,
            aiSummaryStatus: .generating,
            messages: messages,
            transcriptText: transcriptText
        )

        do {
            try storage.save(record)
            refreshLatestSummary()
        } catch {
            appendError("Summary save failed: \(AppLogger.describe(error))", category: .storage)
        }
    }

    private func generateAISummaryIfAvailable(
        config: SessionConfig,
        startedAt: Date,
        endedAt: Date,
        transcriptItems: [SessionTranscriptItem],
        messages: [ChatMessage],
        generationID: UUID
    ) async {
        guard shouldApplyFinalSummary(config: config, generationID: generationID) else { return }
        let transcript = transcriptItems.filter(\.isFinal).map(\.displayLine).joined(separator: "\n")
        let localSummary = makeLocalSummary(
            subject: config.tutorSubject,
            profile: config.learningProfile,
            duration: max(0, endedAt.timeIntervalSince(startedAt)),
            transcriptItems: transcriptItems
        )
        guard !transcript.isEmpty else {
            updateAISummary(
                config: config,
                startedAt: startedAt,
                endedAt: endedAt,
                localSummary: localSummary,
                status: .unavailable,
                aiSummary: "AI summary skipped because no final transcript was available.",
                messages: messages
            )
            state.runningSummaryText = "Final summary skipped because no final transcript was available."
            publish()
            return
        }

        do {
            state.runningSummaryText = "Final summary generating from transcript text..."
            publish()
            let response = try await backendClient.generateSummary(
                SummaryGenerationRequest(
                    sessionID: config.sessionID,
                    tutorSubject: config.tutorSubject,
                    durationSeconds: max(0, endedAt.timeIntervalSince(startedAt)),
                    transcript: transcript,
                    runningSummary: runningAISummary,
                    learningProfile: config.learningProfile
                )
            )
            guard shouldApplyFinalSummary(config: config, generationID: generationID) else { return }
            updateAISummary(
                config: config,
                startedAt: startedAt,
                endedAt: endedAt,
                localSummary: localSummary,
                status: .completed,
                aiSummary: response.displayText,
                messages: messages
            )
            state.runningSummaryText = response.displayText
            appendInfo("AI summary generated and saved.", category: .storage)
        } catch {
            updateAISummary(
                config: config,
                startedAt: startedAt,
                endedAt: endedAt,
                localSummary: localSummary,
                status: .unavailable,
                aiSummary: "AI summary endpoint is not available yet. Local summary is saved.",
                messages: messages
            )
            state.runningSummaryText = "Final AI summary unavailable. Local summary is saved."
            appendInfo("AI summary unavailable; local summary remains saved.", category: .storage)
        }
        publish()
    }

    private func considerIncrementalSummary() {
        guard [.inSession, .listening, .tutorThinking, .tutorSpeaking].contains(state.sessionState) else { return }
        guard pendingSummaryTurns.count >= incrementalSummaryTurnThreshold else { return }
        guard !isIncrementalSummaryGenerating else { return }
        if let lastIncrementalSummaryAt,
           Date().timeIntervalSince(lastIncrementalSummaryAt) < incrementalSummaryMinInterval {
            return
        }
        guard let config = currentConfig else { return }

        let turns = pendingSummaryTurns
        pendingSummaryTurns.removeAll()
        isIncrementalSummaryGenerating = true
        lastIncrementalSummaryAt = Date()
        state.runningSummaryText = "Draft updating with \(turns.count) new final turns..."
        publish()
        appendInfo("AI summary draft updating with \(turns.count) new turns.", category: .storage)

        incrementalSummaryTask?.cancel()
        incrementalSummaryTask = Task { [weak self] in
            guard let self else { return }
            await self.generateIncrementalSummary(config: config, turns: turns, finalize: false)
        }
    }

    private func generateIncrementalSummary(config: SessionConfig, turns: [String], finalize: Bool) async {
        do {
            guard !Task.isCancelled else { return }
            let response = try await backendClient.generateIncrementalSummary(
                IncrementalSummaryGenerationRequest(
                    sessionID: config.sessionID,
                    tutorSubject: config.tutorSubject,
                    previousSummary: runningAISummary,
                    newTurns: turns,
                    finalize: finalize,
                    learningProfile: config.learningProfile
                )
            )
            guard !Task.isCancelled, currentConfig?.sessionID == config.sessionID else { return }
            runningAISummary = response.displayText
            state.runningSummaryText = response.displayText
            publish()
            appendInfo(finalize ? "Final AI summary draft updated." : "AI summary draft updated.", category: .storage)
        } catch {
            guard !Task.isCancelled else { return }
            pendingSummaryTurns.insert(contentsOf: turns, at: 0)
            state.runningSummaryText = "Draft unavailable right now. Local summary will still be saved at End Session."
            publish()
            appendInfo("Incremental AI summary unavailable; will keep local summary path.", category: .storage)
        }
        isIncrementalSummaryGenerating = false
    }

    private func observeSceneLifecycle() {
        lifecycleObservers.append(NotificationCenter.default.addObserver(forName: .appSceneWillResignActive, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in await self?.handleSceneWillResignActive() }
        })
        lifecycleObservers.append(NotificationCenter.default.addObserver(forName: .appSceneDidEnterBackground, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in await self?.handleSceneDidEnterBackground() }
        })
        lifecycleObservers.append(NotificationCenter.default.addObserver(forName: .appSceneWillEnterForeground, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.handleSceneWillEnterForeground() }
        })
    }

    private func handleSceneWillResignActive() async {
        guard isChatLifecycleActive, canSendInput else { return }
        appendInfo("App will resign active during LiveKit session. Preparing background continuous voice if enabled.", category: .session)
        guard appSettings.voiceInputMode == .automatic else {
            appendInfo("Manual Voice is selected. The app will not open the microphone automatically for background speech.", category: .session)
            return
        }
        await startBackgroundContinuousVoiceIfPossible(trigger: "willResignActive")
    }

    private func handleSceneDidEnterBackground() async {
        guard isChatLifecycleActive, canSendInput else { return }
        appendInfo("App entered background during active LiveKit session. Background audio mode should keep an already-active LiveKit voice session alive.", category: .session)
        appendInfo("Background audio snapshot: \(audioManager.diagnosticSummary())", category: .audio)
        guard appSettings.voiceInputMode == .automatic else {
            appendInfo("Manual Voice is selected. Existing active audio may continue, but the app will not open the microphone automatically.", category: .session)
            return
        }
        await startBackgroundContinuousVoiceIfPossible(trigger: "didEnterBackgroundFallback")
    }

    private func startBackgroundContinuousVoiceIfPossible(trigger: String) async {
        guard !backgroundVoiceAutoStartInFlight else { return }
        backgroundVoiceAutoStartInFlight = true
        defer { backgroundVoiceAutoStartInFlight = false }

        guard currentConfig != nil, agentClient.isConnected else {
            appendInfo("Auto Voice background start skipped because LiveKit is not connected.", category: .livekit)
            return
        }
        if state.isMicrophoneActive || agentClient.isMicrophoneStarted {
            appendInfo("Background continuous voice already active; LiveKit turn detection will auto-submit speech. trigger=\(trigger)", category: .audio)
            return
        }

        let permission = audioManager.microphonePermissionStatus()
        appendInfo("Auto Voice background permission=\(permission.rawValue)", category: .audio)
        guard permission == .granted else {
            appendInfo("Auto Voice needs microphone permission first. Open Chat in foreground and tap the microphone once.", category: .audio)
            return
        }

        do {
            try audioManager.configureForVoiceChat()
            try await agentClient.startMicrophone()
            if sessionStartedAt == nil {
                sessionStartedAt = Date()
            }
            hasVoiceInputInCurrentRecording = false
            resetManualVoiceDraft()
            state.isMicrophoneActive = true
            setSessionState(.listening)
            state.primaryHint = ""
            appendInfo("Background continuous voice opened the microphone before suspension. LiveKit STT/turn detection will auto-submit speech. trigger=\(trigger)", category: .audio)
        } catch {
            appendError("Auto Voice background start failed: \(AppLogger.describe(error))", category: .audio)
        }
    }

    private func handleSceneWillEnterForeground() {
        guard isChatLifecycleActive, canSendInput else { return }
        appendInfo("App returned foreground. Check voice continuity; use Reconnect if LiveKit audio stopped.", category: .session)
        appendInfo("Foreground audio snapshot: \(audioManager.diagnosticSummary())", category: .audio)
        appendInfo("Foreground LiveKit snapshot: \(agentClient.diagnosticSummary)", category: .livekit)
        state.isReconnectEnabled = true
        if !agentClient.isConnected {
            state.errorText = "Foreground recovery recommended: LiveKit state looks inactive."
        }
        publish()
    }

    private func cancelSummaryWork(resetDraft: Bool) {
        finalSummaryTask?.cancel()
        finalSummaryTask = nil
        incrementalSummaryTask?.cancel()
        incrementalSummaryTask = nil
        activeSummaryGenerationID = nil
        isIncrementalSummaryGenerating = false
        pendingSummaryTurns.removeAll()
        queuedSummaryTranscriptIDs.removeAll()
        if resetDraft {
            runningAISummary = nil
            state.runningSummaryText = "AI summary draft cleared. Only transcript text is sent; raw audio is never sent."
            publish()
        }
    }

    private func shouldApplyFinalSummary(config: SessionConfig, generationID: UUID) -> Bool {
        !Task.isCancelled && activeSummaryGenerationID == generationID && currentConfig == nil && state.sessionState == .ended && !storage.loadRecentSessions().isEmpty
    }

    private func updateAISummary(
        config: SessionConfig,
        startedAt: Date,
        endedAt: Date,
        localSummary: String,
        status: SessionSummaryStatus,
        aiSummary: String?,
        messages: [ChatMessage]
    ) {
        let duration = durationForSavedRecord(startedAt: startedAt, endedAt: endedAt)
        let record = SessionRecord(
            id: localRecordID(for: config),
            roomName: config.roomName,
            tutorSubject: config.tutorSubject,
            learningProfile: config.learningProfile,
            startedAt: savedStartedAt(fallback: startedAt),
            endedAt: endedAt,
            durationSeconds: duration,
            status: .ended,
            summary: localSummary,
            aiSummary: aiSummary,
            aiSummaryStatus: status,
            messages: messages,
            transcriptText: transcriptText(from: messages)
        )

        do {
            try storage.save(record)
            refreshLatestSummary()
        } catch {
            appendError("AI summary save failed: \(AppLogger.describe(error))", category: .storage)
        }
    }

    private func makeLocalSummary(
        subject: String,
        profile: LearningProfile,
        duration: TimeInterval,
        transcriptItems: [SessionTranscriptItem]
    ) -> String {
        let finalItems = transcriptItems.filter(\.isFinal)
        let learnerTurns = finalItems.filter { $0.speaker == .learner }.count
        let tutorTurns = finalItems.filter { $0.speaker == .tutor }.count
        let lastTutorFeedback = finalItems.last(where: { $0.speaker == .tutor })?.text
        var lines = [
            "Local summary: English speaking practice completed for \(formatDuration(duration)).",
            "Mode: \(profile.summaryLine).",
            "Goal: \(profile.goalLine).",
            "Subject: \(subject).",
            "Turns: learner \(learnerTurns), tutor \(tutorTurns)."
        ]
        lines.append("Latest tutor note: \(lastTutorFeedback ?? "not available yet.")")
        lines.append("Privacy: no raw audio was stored.")
        return lines.joined(separator: "\n")
    }

    private func chatTranscriptItems(from messages: [ChatMessage]) -> [SessionTranscriptItem] {
        messages.compactMap { message in
            let speaker: SessionTranscriptItem.Speaker
            switch message.speaker {
            case .learner:
                speaker = .learner
            case .tutor:
                speaker = .tutor
            case .system:
                return nil
            }
            return SessionTranscriptItem(
                id: message.id,
                speaker: speaker,
                text: message.text,
                isFinal: message.status == .sent
            )
        }
    }

    private func transcriptText(from messages: [ChatMessage]) -> String {
        messages
            .filter { $0.speaker == .learner || $0.speaker == .tutor }
            .map(\.transcriptLine)
            .joined(separator: "\n")
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = max(0, Int(duration))
        let minutes = seconds / 60
        let remainder = seconds % 60
        return minutes == 0 ? "\(remainder)s" : "\(minutes)m \(remainder)s"
    }

    private func refreshLatestSummary() {
        let records = storage.loadRecentSessions()
        state.isClearHistoryEnabled = !records.isEmpty
        guard let latest = records.first else {
            state.latestSummaryRecord = nil
            state.latestSummaryText = "No local summary yet."
            return
        }
        applySummaryRecord(latest, label: "Latest")
    }

    private func seedResumeRecord(_ record: SessionRecord) {
        let restoredMessages = restoreMessages(from: record, fallbackContext: resumeContext)
        if !restoredMessages.isEmpty {
            chatMessages = Array(restoredMessages.suffix(120))
            state.messages = chatMessages
            state.transcriptText = chatMessages.map(\.transcriptLine).joined(separator: "\n")
        } else {
            let fallbackMessage = makeResumeSummaryMessage(from: record)
            chatMessages = [fallbackMessage]
            state.messages = chatMessages
            state.transcriptText = fallbackMessage.transcriptLine
        }
        AppLogger.debug(
            "Restored history messages count=\(chatMessages.count) session=\(record.id)",
            category: .storage
        )
        applySummaryRecord(record, label: "Previous")
        state.runningSummaryText = record.aiSummary?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? record.aiSummary!
            : record.summary
    }

    private func restoreMessages(from record: SessionRecord, fallbackContext: SessionResumeContext?) -> [ChatMessage] {
        if let messages = record.messages, !messages.isEmpty {
            return messages.map { message in
                var restored = message
                restored.status = .sent
                return restored
            }
        }

        let transcript = record.transcriptText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? record.transcriptText
            : fallbackContext?.transcriptExcerpt

        guard let transcript = transcript?.trimmingCharacters(in: .whitespacesAndNewlines),
              !transcript.isEmpty else {
            return []
        }

        return transcript
            .split(separator: "\n")
            .enumerated()
            .compactMap { index, rawLine in
                let line = String(rawLine).trimmingCharacters(in: .whitespacesAndNewlines)
                guard !line.isEmpty else { return nil }
                let parts = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
                let rawSpeaker = parts.count > 1 ? parts[0].trimmingCharacters(in: .whitespacesAndNewlines) : "System"
                let text = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines) : line
                let speaker: ChatMessageSpeaker
                switch rawSpeaker.lowercased() {
                case "you", "learner", "user":
                    speaker = .learner
                case "tutor", "assistant", "agent":
                    speaker = .tutor
                default:
                    speaker = .system
                }
                return ChatMessage(
                    id: "restored-\(record.id)-\(index)",
                    sessionID: record.id,
                    speaker: speaker,
                    text: text,
                    createdAt: record.startedAt.addingTimeInterval(TimeInterval(index)),
                    inputType: speaker == .system ? .system : .text,
                    status: .sent
                )
            }
    }

    private func makeResumeSummaryMessage(from record: SessionRecord) -> ChatMessage {
        let summary = record.aiSummary?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? record.aiSummary!
            : record.summary
        let text = """
        Previous session loaded.
        \(summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No previous transcript text was saved." : summary)
        """
        return ChatMessage(
            id: "restored-summary-\(record.id)",
            sessionID: record.id,
            speaker: .system,
            text: text,
            createdAt: record.endedAt,
            inputType: .system,
            status: .sent
        )
    }

    private func applySummaryRecord(_ record: SessionRecord, label: String) {
        state.latestSummaryRecord = record
        let aiText: String
        switch record.aiSummaryStatus {
        case .generating:
            aiText = record.aiSummary?.isEmpty == false ? "\nAI summary: generating...\nDraft:\n\(record.aiSummary!)" : "\nAI summary: generating..."
        case .completed:
            aiText = "\nAI summary:\n\(record.aiSummary ?? "Completed, but no text was returned.")"
            state.runningSummaryText = record.aiSummary ?? state.runningSummaryText
        case .unavailable:
            aiText = "\nAI summary: unavailable. \(record.aiSummary ?? "Local summary is saved.")"
        case .failed:
            aiText = "\nAI summary: failed. \(record.aiSummary ?? "Local summary is saved.")"
        case .localOnly, .none:
            aiText = "\nAI summary: not requested."
        }
        let profile = record.learningProfile?.summaryLine ?? record.tutorSubject
        state.latestSummaryText = "\(label): \(profile), \(Int(record.durationSeconds))s, \(AppDateFormatter.shortDateTime(record.endedAt))\n\(record.summary)\(aiText)"
    }

    private func setSessionState(_ next: SessionState) {
        state.sessionState = next
        refreshVoiceInputPresentation()
        state.statusText = "State: \(next.rawValue)"
        state.voiceStateText = next.rawValue
        state.isConnectEnabled = next == .idle || next == .ended || next.isFailure
        state.isStartEnabled = next == .connected || next == .inSession || next == .tutorThinking || next == .tutorSpeaking
        state.isMicEnabled = state.isStartEnabled || next == .listening
        state.isEndEnabled = next == .connected || next == .inSession || next == .listening || next == .tutorThinking || next == .tutorSpeaking || next.isFailure
        state.isReconnectEnabled = next == .reconnecting || next.isFailure
        state.isTextInputEnabled = next == .connected || next == .inSession || next == .listening || next == .tutorThinking || next == .tutorSpeaking
        publish()
    }

    private func refreshVoiceInputPresentation() {
        state.voiceInputMode = appSettings.voiceInputMode
        switch state.voiceInputMode {
        case .automatic:
            state.micButtonTitle = state.isMicrophoneActive ? "Stop automatic voice" : "Start automatic voice"
        case .manual:
            state.micButtonTitle = state.isMicrophoneActive ? "Cancel voice input" : "Start manual voice input"
        }
    }

    private func handleFailure(_ prefix: String, error: Error, category: AppLogger.Category) {
        let appError = AppError.wrap(error)
        setSessionState(.failureState(for: appError))
        let message = "\(prefix): \(appError.localizedDescription)"
        state.errorText = message
        appendError(message, category: category)
        appendSystemMessage(message, status: .failed)
    }

    private func appendInfo(_ message: String, category: AppLogger.Category) {
        AppLogger.debug(message, category: category)
        appendLog(.info, message: message, category: category)
    }

    private func appendError(_ message: String, category: AppLogger.Category) {
        AppLogger.error(message, category: category)
        appendLog(.error, message: message, category: category)
    }

    private func appendLog(_ level: SessionLogItem.Level, message: String, category: AppLogger.Category) {
        logItems.append(SessionLogItem(date: Date(), level: level, message: message, category: category))
        logItems = Array(logItems.suffix(120))
        state.logText = logItems.map(\.displayLine).joined(separator: "\n")
        publish()
    }

    private func handleTranscript(_ update: TranscriptUpdate) {
        let speaker: SessionTranscriptItem.Speaker = update.speaker == .tutor ? .tutor : .learner
        if update.speaker == .tutor {
            setSessionState(update.isFinal ? .inSession : .tutorSpeaking)
            state.primaryHint = ""
        } else if state.sessionState == .listening {
            hasVoiceInputInCurrentRecording = true
            cancelMicrophoneWarmupCheck()
            if appSettings.voiceInputMode == .manual {
                bufferManualVoiceTranscript(update)
                return
            }
        }
        appendTranscript(id: update.id, speaker: speaker, text: update.text, isFinal: update.isFinal, inputType: .voice)
    }

    private func scheduleMicrophoneWarmupCheck() {
        cancelMicrophoneWarmupCheck()
        microphoneWarmupTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            guard let self, !Task.isCancelled else { return }
            guard self.state.isMicrophoneActive, self.state.sessionState == .listening, !self.hasVoiceInputInCurrentRecording else { return }

            self.appendInfo("No learner transcript detected after microphone start. Retrying microphone publish once.", category: .audio)
            do {
                await self.agentClient.stopMicrophone()
                try await self.agentClient.startMicrophone()
                self.appendInfo("Microphone publish retried successfully.", category: .audio)
            } catch {
                self.appendError("Microphone publish retry failed: \(AppLogger.describe(error))", category: .audio)
            }
        }
    }

    private func cancelMicrophoneWarmupCheck() {
        microphoneWarmupTask?.cancel()
        microphoneWarmupTask = nil
    }

    private func bufferManualVoiceTranscript(_ update: TranscriptUpdate) {
        let trimmed = update.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        manualVoiceDraftID = manualVoiceDraftID ?? update.id
        manualVoiceDraftText = trimmed
        AppLogger.debug(
            "Manual Voice buffered learner transcript final=\(update.isFinal) length=\(trimmed.count). It will appear after Send.",
            category: .session
        )
    }

    private func flushManualVoiceDraftIfNeeded() -> Bool {
        guard appSettings.voiceInputMode == .manual,
              let text = manualVoiceDraftText?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return false
        }

        let id = manualVoiceDraftID ?? "manual-voice-\(UUID().uuidString)"
        appendTranscript(id: id, speaker: .learner, text: text, isFinal: true, inputType: .voice)
        resetManualVoiceDraft()
        return true
    }

    private func resetManualVoiceDraft() {
        manualVoiceDraftID = nil
        manualVoiceDraftText = nil
    }

    private func appendTranscript(
        id: String,
        speaker: SessionTranscriptItem.Speaker,
        text: String,
        isFinal: Bool,
        inputType: ChatMessageInputType
    ) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if isFinal {
            hasNewSessionContent = true
        }

        if let index = transcriptItems.firstIndex(where: { $0.id == id }) {
            transcriptItems[index].text = trimmed
            transcriptItems[index].isFinal = isFinal
        } else {
            transcriptItems.append(SessionTranscriptItem(id: id, speaker: speaker, text: trimmed, isFinal: isFinal))
        }
        transcriptItems = Array(transcriptItems.suffix(80))
        state.transcriptText = transcriptItems.map(\.displayLine).joined(separator: "\n")

        let chatSpeaker: ChatMessageSpeaker = speaker == .tutor ? .tutor : .learner
        let status: ChatMessageStatus = isFinal ? .sent : (chatSpeaker == .tutor ? .streaming : .transcribing)
        upsertChatMessage(
            id: id,
            speaker: chatSpeaker,
            text: trimmed,
            inputType: inputType,
            status: status
        )

        if isFinal, queuedSummaryTranscriptIDs.insert(id).inserted {
            let line = SessionTranscriptItem(id: id, speaker: speaker, text: trimmed, isFinal: true).displayLine
            pendingSummaryTurns.append(line)
            considerIncrementalSummary()
        }
        publish()
    }

    private func appendSystemMessage(_ text: String, status: ChatMessageStatus) {
        appendChatMessage(
            ChatMessage(
                id: "system-\(UUID().uuidString)",
                sessionID: localSessionID,
                speaker: .system,
                text: text,
                createdAt: Date(),
                inputType: .system,
                status: status
            )
        )
    }

    private func appendChatMessage(_ message: ChatMessage) {
        chatMessages.append(message)
        chatMessages = Array(chatMessages.suffix(120))
        state.messages = chatMessages
        publish()
    }

    private func upsertChatMessage(id: String, speaker: ChatMessageSpeaker, text: String, inputType: ChatMessageInputType, status: ChatMessageStatus) {
        if let index = chatMessages.firstIndex(where: { $0.id == id }) {
            chatMessages[index].text = text
            chatMessages[index].status = status
        } else {
            appendChatMessage(
                ChatMessage(
                    id: id,
                    sessionID: localSessionID,
                    speaker: speaker,
                    text: text,
                    createdAt: Date(),
                    inputType: inputType,
                    status: status
                )
            )
        }
        state.messages = chatMessages
    }

    private func updateMessageStatus(id: String, status: ChatMessageStatus) {
        guard let index = chatMessages.firstIndex(where: { $0.id == id }) else { return }
        chatMessages[index].status = status
        state.messages = chatMessages
        publish()
    }

    private func publish() {
        onStateChange?(state)
    }
}
