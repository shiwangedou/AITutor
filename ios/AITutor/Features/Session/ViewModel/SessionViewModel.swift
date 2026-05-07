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
        publish()
    }

    func connect() async {
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
        await agentClient.disconnect()
        audioManager.deactivate()
        saveSummary(status: .ended)
        currentConfig = nil
        sessionStartedAt = nil
        setSessionState(.ended)
        state.connectionText = "Ended"
        appendInfo("Session ended and local metadata/summary saved.", category: .session)
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
            try storage.clear()
            refreshLatestSummary()
            appendInfo("Local session history cleared.", category: .storage)
        } catch {
            handleFailure("Clear history failed", error: error, category: .storage)
        }
    }

    private func saveSummary(status: SessionState) {
        guard let config = currentConfig else {
            return
        }

        let startedAt = sessionStartedAt ?? Date()
        let endedAt = Date()
        let duration = max(0, endedAt.timeIntervalSince(startedAt))
        let summary = "English speaking practice completed for \(Int(duration)) seconds. Review the session log for connection and audio status."
        let record = SessionRecord(
            id: config.sessionID,
            roomName: config.roomName,
            tutorSubject: config.tutorSubject,
            startedAt: startedAt,
            endedAt: endedAt,
            durationSeconds: duration,
            status: status,
            summary: summary
        )

        do {
            try storage.save(record)
            refreshLatestSummary()
        } catch {
            appendError("Summary save failed: \(AppLogger.describe(error))", category: .storage)
        }
    }

    private func refreshLatestSummary() {
        let records = storage.loadRecentSessions()
        state.isClearHistoryEnabled = !records.isEmpty
        guard let latest = records.first else {
            state.latestSummaryText = "No local summary yet."
            return
        }
        state.latestSummaryText = "Latest: \(latest.tutorSubject), \(Int(latest.durationSeconds))s, \(AppDateFormatter.shortDateTime(latest.endedAt))\n\(latest.summary)"
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
    }

    private func publish() {
        onStateChange?(state)
    }
}
