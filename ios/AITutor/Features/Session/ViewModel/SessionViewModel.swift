import Foundation

@MainActor
final class SessionViewModel {
    var onStateChange: ((SessionViewState) -> Void)?
    var currentState: SessionViewState { state }

    private let backendClient: BackendAPIClientProtocol
    private let agentClient: LiveKitAgentControlling
    private let audioManager: AudioSessionManaging
    private let storage: SessionStorageManaging

    private var state = SessionViewState()
    private var currentConfig: SessionConfig?
    private var sessionStartedAt: Date?
    private var logItems: [SessionLogItem] = []
    private var transcriptItems: [SessionTranscriptItem] = []
    private var pendingSummaryTurns: [String] = []
    private var queuedSummaryTranscriptIDs = Set<String>()
    private var runningAISummary: String?
    private var isIncrementalSummaryGenerating = false
    private var lastIncrementalSummaryAt: Date?
    private var lifecycleObservers: [NSObjectProtocol] = []
    private var finalSummaryTask: Task<Void, Never>?
    private var incrementalSummaryTask: Task<Void, Never>?
    private var activeSummaryGenerationID: UUID?
    private let incrementalSummaryTurnThreshold = 4
    private let incrementalSummaryMinInterval: TimeInterval = 20

    init(environment: AppEnvironment) {
        self.backendClient = environment.backendClient
        self.agentClient = environment.agentClient
        self.audioManager = environment.audioManager
        self.storage = environment.sessionStorage
        self.agentClient.setTranscriptHandler { [weak self] update in
            self?.handleTranscript(update)
        }
        refreshLatestSummary()
        appendInfo("Backend: \(AppConfig.backendBaseURL.absoluteString)", category: .network)
        appendInfo("Privacy: raw audio is not stored; only local metadata and summaries are saved.", category: .session)
        appendInfo("Summary privacy: AI summaries send transcript text only, never raw audio.", category: .storage)
        observeSceneLifecycle()
        publish()
    }

    deinit {
        finalSummaryTask?.cancel()
        incrementalSummaryTask?.cancel()
        lifecycleObservers.forEach(NotificationCenter.default.removeObserver)
    }

    func connect() async {
        cancelSummaryWork(resetDraft: false)
        setSessionState(.connecting)
        state.errorText = nil
        appendInfo("Requesting session config from backend...", category: .network)

        do {
            let config = try await backendClient.createSession(displayName: "Learner")
            currentConfig = config
            appendInfo("Room: \(config.roomName)", category: .session)
            try await agentClient.connect(using: config)
            setSessionState(.connected)
            state.connectionText = "Connected room: \(config.roomName)"
            state.primaryHint = "Connected. Tap Start to enable the iPhone microphone and begin speaking."
            appendInfo("Connected to LiveKit. Tap Start to request microphone permission and publish local audio.", category: .livekit)
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
            appendInfo("Microphone is published. Starting tutor conversation...", category: .livekit)
            try await agentClient.startConversation()
            sessionStartedAt = Date()
            runningAISummary = nil
            pendingSummaryTurns.removeAll()
            queuedSummaryTranscriptIDs.removeAll()
            incrementalSummaryTask?.cancel()
            activeSummaryGenerationID = nil
            state.runningSummaryText = "Draft waiting for transcript. It will update after 4 final turns."
            setSessionState(.inSession)
            state.primaryHint = "Tutor is starting. Answer the warm-up question in one short sentence."
            appendInfo("Voice session started by Start action. Wait for the tutor warm-up question.", category: .session)
        } catch {
            handleFailure("Start failed", error: error, category: .session)
            appendError("Audio after failure: \(audioManager.diagnosticSummary())", category: .audio)
        }
    }

    func sendText(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        guard state.sessionState == .connected || state.sessionState == .inSession else {
            handleFailure("Text send failed", error: AppError.liveKitConnectFailed("Connect to LiveKit before sending text"), category: .session)
            return
        }

        do {
            appendInfo("Learner text: \(trimmed)", category: .session)
            appendTranscript(
                id: "typed-\(UUID().uuidString)",
                speaker: .learner,
                text: trimmed,
                isFinal: true
            )
            try await agentClient.sendText(trimmed)
            appendInfo("Text sent to tutor agent.", category: .livekit)
        } catch {
            handleFailure("Text send failed", error: error, category: .livekit)
        }
    }

    func endSession() async {
        let endedConfig = currentConfig
        let startedAt = sessionStartedAt
        let finalTranscriptItems = transcriptItems
        let summaryGenerationID = UUID()
        activeSummaryGenerationID = summaryGenerationID
        incrementalSummaryTask?.cancel()
        incrementalSummaryTask = nil
        isIncrementalSummaryGenerating = false

        await agentClient.disconnect()
        audioManager.deactivate()
        saveLocalSummary(
            status: .ended,
            config: endedConfig,
            startedAt: startedAt,
            transcriptItems: finalTranscriptItems
        )
        currentConfig = nil
        sessionStartedAt = nil
        setSessionState(.ended)
        state.connectionText = "Ended"
        state.runningSummaryText = "Final summary generating when transcript text is available. Local summary is already saved."
        appendInfo("Session ended. Local summary saved; AI summary generation started when available.", category: .session)

        if let endedConfig {
            finalSummaryTask?.cancel()
            finalSummaryTask = Task { [weak self] in
                guard let self else { return }
                await self.generateAISummaryIfAvailable(
                    config: endedConfig,
                    startedAt: startedAt ?? Date(),
                    endedAt: Date(),
                    transcriptItems: finalTranscriptItems,
                    generationID: summaryGenerationID
                )
            }
        }
    }

    func reconnect() async {
        appendInfo("Reconnect requested.", category: .session)
        await agentClient.disconnect()
        audioManager.deactivate()

        if let config = currentConfig {
            do {
                setSessionState(.connecting)
                try await agentClient.connect(using: config)
                setSessionState(.connected)
                state.connectionText = "Reconnected room: \(config.roomName)"
                appendInfo("Reconnected to current LiveKit room.", category: .livekit)
            } catch {
                handleFailure("Reconnect failed", error: error, category: .livekit)
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

    private func saveLocalSummary(
        status: SessionState,
        config: SessionConfig?,
        startedAt: Date?,
        transcriptItems: [SessionTranscriptItem]
    ) {
        guard let config else {
            return
        }

        let startedAt = startedAt ?? Date()
        let endedAt = Date()
        let duration = max(0, endedAt.timeIntervalSince(startedAt))
        let summary = makeLocalSummary(
            subject: config.tutorSubject,
            duration: duration,
            transcriptItems: transcriptItems
        )
        let record = SessionRecord(
            id: config.sessionID,
            roomName: config.roomName,
            tutorSubject: config.tutorSubject,
            startedAt: startedAt,
            endedAt: endedAt,
            durationSeconds: duration,
            status: status,
            summary: summary,
            aiSummary: runningAISummary,
            aiSummaryStatus: .generating
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
        generationID: UUID
    ) async {
        guard shouldApplyFinalSummary(config: config, generationID: generationID) else { return }
        let transcript = transcriptItems
            .filter(\.isFinal)
            .map(\.displayLine)
            .joined(separator: "\n")
        guard !transcript.isEmpty else {
            guard shouldApplyFinalSummary(config: config, generationID: generationID) else { return }
            updateAISummary(
                config: config,
                startedAt: startedAt,
                endedAt: endedAt,
                localSummary: makeLocalSummary(
                    subject: config.tutorSubject,
                    duration: max(0, endedAt.timeIntervalSince(startedAt)),
                    transcriptItems: transcriptItems
                ),
                status: .unavailable,
                aiSummary: "AI summary skipped because no final transcript was available."
            )
            appendInfo("AI summary skipped: no final transcript available.", category: .storage)
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
                    runningSummary: runningAISummary
                )
            )
            guard shouldApplyFinalSummary(config: config, generationID: generationID) else { return }
            updateAISummary(
                config: config,
                startedAt: startedAt,
                endedAt: endedAt,
                localSummary: makeLocalSummary(
                    subject: config.tutorSubject,
                    duration: max(0, endedAt.timeIntervalSince(startedAt)),
                    transcriptItems: transcriptItems
                ),
                status: .completed,
                aiSummary: response.displayText
            )
            state.runningSummaryText = response.displayText
            appendInfo("AI summary generated and saved.", category: .storage)
        } catch {
            guard shouldApplyFinalSummary(config: config, generationID: generationID) else { return }
            updateAISummary(
                config: config,
                startedAt: startedAt,
                endedAt: endedAt,
                localSummary: makeLocalSummary(
                    subject: config.tutorSubject,
                    duration: max(0, endedAt.timeIntervalSince(startedAt)),
                    transcriptItems: transcriptItems
                ),
                status: .unavailable,
                aiSummary: "AI summary endpoint is not available yet. Local summary is saved."
            )
            state.runningSummaryText = "Final AI summary unavailable. Local summary is saved."
            appendInfo("AI summary unavailable; local summary remains saved.", category: .storage)
        }
        publish()
    }

    private func considerIncrementalSummary() {
        guard state.sessionState == .inSession else { return }
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

    private func generateIncrementalSummary(
        config: SessionConfig,
        turns: [String],
        finalize: Bool
    ) async {
        do {
            guard !Task.isCancelled else { return }
            let response = try await backendClient.generateIncrementalSummary(
                IncrementalSummaryGenerationRequest(
                    sessionID: config.sessionID,
                    tutorSubject: config.tutorSubject,
                    previousSummary: runningAISummary,
                    newTurns: turns,
                    finalize: finalize
                )
            )
            guard !Task.isCancelled, currentConfig?.sessionID == config.sessionID, state.sessionState == .inSession else { return }
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
        lifecycleObservers.append(
            NotificationCenter.default.addObserver(
                forName: .appSceneDidEnterBackground,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.handleSceneDidEnterBackground()
                }
            }
        )
        lifecycleObservers.append(
            NotificationCenter.default.addObserver(
                forName: .appSceneWillEnterForeground,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.handleSceneWillEnterForeground()
                }
            }
        )
    }

    private func handleSceneDidEnterBackground() {
        guard state.sessionState == .connected || state.sessionState == .inSession else { return }
        appendInfo("App entered background during active LiveKit session. Background audio mode is expected to keep voice active.", category: .session)
        appendInfo("Background audio snapshot: \(audioManager.diagnosticSummary())", category: .audio)
    }

    private func handleSceneWillEnterForeground() {
        guard state.sessionState == .connected || state.sessionState == .inSession else { return }
        appendInfo("App returned foreground. Check voice continuity; use Reconnect if LiveKit audio stopped.", category: .session)
        appendInfo("Foreground audio snapshot: \(audioManager.diagnosticSummary())", category: .audio)
        appendInfo("Foreground LiveKit snapshot: \(agentClient.diagnosticSummary)", category: .livekit)

        if state.sessionState == .inSession, (!agentClient.isConnected || !agentClient.isMicrophoneStarted) {
            state.primaryHint = "Voice session may have stopped while backgrounded. Tap Reconnect, then Start if needed."
            state.isReconnectEnabled = true
            state.errorText = "Foreground recovery recommended: LiveKit or microphone state looks inactive."
            publish()
        } else {
            state.primaryHint = "Returned to foreground. If audio stopped, tap Reconnect."
            state.isReconnectEnabled = true
            publish()
        }
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
        aiSummary: String?
    ) {
        let duration = max(0, endedAt.timeIntervalSince(startedAt))
        let record = SessionRecord(
            id: config.sessionID,
            roomName: config.roomName,
            tutorSubject: config.tutorSubject,
            startedAt: startedAt,
            endedAt: endedAt,
            durationSeconds: duration,
            status: .ended,
            summary: localSummary,
            aiSummary: aiSummary,
            aiSummaryStatus: status
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
        duration: TimeInterval,
        transcriptItems: [SessionTranscriptItem]
    ) -> String {
        let finalItems = transcriptItems.filter(\.isFinal)
        let learnerTurns = finalItems.filter { $0.speaker == .learner }.count
        let tutorTurns = finalItems.filter { $0.speaker == .tutor }.count
        let lastTutorFeedback = finalItems.last(where: { $0.speaker == .tutor })?.text

        var lines = [
            "Local summary: English speaking practice completed for \(formatDuration(duration)).",
            "Subject: \(subject).",
            "Turns: learner \(learnerTurns), tutor \(tutorTurns)."
        ]

        if let lastTutorFeedback {
            lines.append("Latest tutor note: \(lastTutorFeedback)")
        } else {
            lines.append("Latest tutor note: not available yet.")
        }

        lines.append("Privacy: no raw audio was stored.")
        return lines.joined(separator: "\n")
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = max(0, Int(duration))
        let minutes = seconds / 60
        let remainder = seconds % 60
        if minutes == 0 {
            return "\(remainder)s"
        }
        return "\(minutes)m \(remainder)s"
    }

    private func refreshLatestSummary() {
        let records = storage.loadRecentSessions()
        state.isClearHistoryEnabled = !records.isEmpty
        guard let latest = records.first else {
            state.latestSummaryText = "No local summary yet."
            return
        }
        let aiText: String
        switch latest.aiSummaryStatus {
        case .generating:
            if let draft = latest.aiSummary, !draft.isEmpty {
                aiText = "\nAI summary: generating...\nDraft:\n\(draft)"
                state.runningSummaryText = draft
            } else {
                aiText = "\nAI summary: generating..."
            }
        case .completed:
            aiText = "\nAI summary:\n\(latest.aiSummary ?? "Completed, but no text was returned.")"
            state.runningSummaryText = latest.aiSummary ?? state.runningSummaryText
        case .unavailable:
            aiText = "\nAI summary: unavailable. \(latest.aiSummary ?? "Local summary is saved.")"
        case .failed:
            aiText = "\nAI summary: failed. \(latest.aiSummary ?? "Local summary is saved.")"
        case .localOnly, .none:
            aiText = "\nAI summary: not requested."
        }

        state.latestSummaryText = "Latest: \(latest.tutorSubject), \(Int(latest.durationSeconds))s, \(AppDateFormatter.shortDateTime(latest.endedAt))\n\(latest.summary)\(aiText)"
    }

    private func setSessionState(_ next: SessionState) {
        state.sessionState = next
        state.statusText = "State: \(next.rawValue)"
        state.isConnectEnabled = next == .idle || next == .ended || next.isFailure
        state.isStartEnabled = next == .connected
        state.isEndEnabled = next == .connected || next == .inSession || next.isFailure
        state.isReconnectEnabled = next.isFailure
        state.isTextInputEnabled = next == .connected || next == .inSession
        publish()
    }

    private func handleFailure(_ prefix: String, error: Error, category: AppLogger.Category) {
        let appError = AppError.wrap(error)
        setSessionState(.failureState(for: appError))
        let message = "\(prefix): \(appError.localizedDescription)"
        state.errorText = message
        appendError(message, category: category)
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
        appendTranscript(id: update.id, speaker: speaker, text: update.text, isFinal: update.isFinal)
    }

    private func appendTranscript(id: String, speaker: SessionTranscriptItem.Speaker, text: String, isFinal: Bool) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let index = transcriptItems.firstIndex(where: { $0.id == id }) {
            transcriptItems[index].text = trimmed
            transcriptItems[index].isFinal = isFinal
        } else {
            transcriptItems.append(SessionTranscriptItem(id: id, speaker: speaker, text: trimmed, isFinal: isFinal))
        }

        transcriptItems = Array(transcriptItems.suffix(40))
        state.transcriptText = transcriptItems.map(\.displayLine).joined(separator: "\n")
        publish()

        if isFinal, queuedSummaryTranscriptIDs.insert(id).inserted {
            let line = SessionTranscriptItem(id: id, speaker: speaker, text: trimmed, isFinal: true).displayLine
            pendingSummaryTurns.append(line)
            considerIncrementalSummary()
        }
    }

    private func publish() {
        onStateChange?(state)
    }
}
