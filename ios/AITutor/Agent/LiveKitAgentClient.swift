import Foundation
@preconcurrency import LiveKit

struct TranscriptUpdate: Equatable {
    enum Speaker: String {
        case learner = "You"
        case tutor = "Tutor"
    }

    let id: String
    let speaker: Speaker
    let text: String
    let isFinal: Bool
}

enum AgentConnectionState: String, Equatable {
    case disconnected
    case connecting
    case reconnecting
    case connected
    case disconnecting
}

struct AgentConnectionEvent: Equatable {
    let state: AgentConnectionState
    let reason: String?
}

@MainActor
protocol LiveKitAgentControlling {
    var isConnected: Bool { get }
    var isMicrophoneStarted: Bool { get }
    var diagnosticSummary: String { get }

    @discardableResult
    func addTranscriptHandler(_ handler: @escaping @MainActor (TranscriptUpdate) -> Void) -> UUID
    @discardableResult
    func addConnectionHandler(_ handler: @escaping @MainActor (AgentConnectionEvent) -> Void) -> UUID
    func removeTranscriptHandler(_ id: UUID)
    func removeConnectionHandler(_ id: UUID)
    func connect(using config: SessionConfig) async throws
    func startMicrophone() async throws
    func stopMicrophone() async
    func sendText(_ text: String) async throws
    func disconnect() async
}

@MainActor
final class LiveKitAgentClient: NSObject, LiveKitAgentControlling, RoomDelegate {
    private let room = Room()
    private var lastConfig: SessionConfig?
    private var transcriptHandlers: [UUID: (@MainActor (TranscriptUpdate) -> Void)] = [:]
    private var connectionHandlers: [UUID: (@MainActor (AgentConnectionEvent) -> Void)] = [:]
    private var seenTranscriptKeys = Set<String>()
    private let seenTranscriptLock = NSLock()
    private(set) var isConnected = false
    private(set) var isMicrophoneStarted = false

    var diagnosticSummary: String {
        return [
            "connected=\(isConnected)",
            "microphoneStarted=\(isMicrophoneStarted)",
            "room=\(lastConfig?.roomName ?? "none")",
            "identity=\(lastConfig?.participantIdentity ?? "none")"
        ].joined(separator: " | ")
    }

    override init() {
        super.init()
        room.add(delegate: self)
    }

    deinit {
        room.remove(delegate: self)
    }

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
        lastConfig = config
        AppLogger.debug("Connecting LiveKit room=\(config.roomName) identity=\(config.participantIdentity) url=\(config.livekitURL)", category: .livekit)

        do {
            try await room.connect(url: config.livekitURL, token: config.token)
            isConnected = true
            AppLogger.debug("Connected LiveKit room=\(config.roomName)", category: .livekit)
        } catch {
            isConnected = false
            throw AppError.liveKitConnectFailed(AppLogger.describe(error))
        }
    }

    func startMicrophone() async throws {
        AppLogger.debug("Starting LiveKit microphone publish", category: .livekit)

        do {
            try await room.localParticipant.setMicrophone(enabled: true)
            isMicrophoneStarted = true
            AppLogger.debug("LiveKit microphone publish started", category: .livekit)
        } catch {
            isMicrophoneStarted = false
            throw AppError.microphonePublishFailed(AppLogger.describe(error))
        }
    }

    func stopMicrophone() async {
        AppLogger.debug("Stopping LiveKit microphone publish", category: .livekit)
        do {
            try await room.localParticipant.setMicrophone(enabled: false)
        } catch {
            AppLogger.error("LiveKit microphone stop failed: \(AppLogger.describe(error))", category: .livekit)
        }
        isMicrophoneStarted = false
        AppLogger.debug("LiveKit microphone publish stopped", category: .livekit)
    }

    func sendText(_ text: String) async throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        AppLogger.debug("Sending text message to LiveKit agent topic=lk.chat length=\(trimmed.count)", category: .livekit)

        do {
            try await room.localParticipant.sendText(trimmed, for: "lk.chat")
            AppLogger.debug("Text message sent to LiveKit agent", category: .livekit)
        } catch {
            throw AppError.unknown("Text send failed: \(AppLogger.describe(error))")
        }
    }

    func disconnect() async {
        let roomName = lastConfig?.roomName ?? "unknown"
        AppLogger.debug("Disconnecting LiveKit room=\(roomName)", category: .livekit)
        await room.disconnect()
        isConnected = false
        isMicrophoneStarted = false
        AppLogger.debug("Disconnected LiveKit room=\(roomName)", category: .livekit)
    }

    nonisolated func room(_ room: Room, didUpdateConnectionState connectionState: ConnectionState, from oldConnectionState: ConnectionState) {
        let mapped = AgentConnectionState(connectionState)
        AppLogger.debug("LiveKit connection state=\(mapped.rawValue) from=\(AgentConnectionState(oldConnectionState).rawValue)", category: .livekit)
        Task { @MainActor [weak self] in
            self?.setConnected(mapped == .connected)
            self?.emitConnection(AgentConnectionEvent(state: mapped, reason: nil))
        }
    }

    nonisolated func roomIsReconnecting(_ room: Room) {
        AppLogger.debug("LiveKit room is reconnecting", category: .livekit)
        Task { @MainActor [weak self] in
            self?.setConnected(false)
            self?.emitConnection(AgentConnectionEvent(state: .reconnecting, reason: "LiveKit is reconnecting"))
        }
    }

    nonisolated func roomDidReconnect(_ room: Room) {
        AppLogger.debug("LiveKit room reconnected", category: .livekit)
        Task { @MainActor [weak self] in
            self?.setConnected(true)
            self?.emitConnection(AgentConnectionEvent(state: .connected, reason: "LiveKit reconnected"))
        }
    }

    nonisolated func room(_ room: Room, didDisconnectWithError error: LiveKitError?) {
        let reason = error.map(AppLogger.describe)
        AppLogger.debug("LiveKit room disconnected reason=\(reason ?? "none")", category: .livekit)
        Task { @MainActor [weak self] in
            self?.setConnected(false)
            self?.setMicrophoneStarted(false)
            self?.emitConnection(AgentConnectionEvent(state: .disconnected, reason: reason))
        }
    }

    nonisolated func room(_ room: Room, participant: Participant, trackPublication: TrackPublication, didReceiveTranscriptionSegments segments: [TranscriptionSegment]) {
        let speaker: TranscriptUpdate.Speaker = participant.isAgent ? .tutor : .learner

        for segment in segments {
            Task { @MainActor [weak self] in
                self?.emitTranscript(
                    id: segment.id,
                    speaker: speaker,
                    text: segment.text,
                    isFinal: segment.isFinal,
                    source: "delegate"
                )
            }
        }
    }

    nonisolated func room(
        _ room: Room,
        participant: RemoteParticipant?,
        didReceiveData data: Data,
        forTopic topic: String,
        encryptionType: EncryptionType
    ) {
        guard topic == "lk.transcription" else { return }
        guard let payload = parseFallbackPayload(data: data) else {
            AppLogger.debug("Fallback transcription payload decode failed topic=\(topic) bytes=\(data.count)", category: .livekit)
            return
        }

        let speaker: TranscriptUpdate.Speaker
        if let payloadSpeaker = payload.speaker {
            speaker = payloadSpeaker
        } else if let participant {
            speaker = participant.isAgent ? .tutor : .learner
        } else {
            speaker = .tutor
        }

        Task { @MainActor [weak self] in
            self?.emitTranscript(
                id: payload.id,
                speaker: speaker,
                text: payload.text,
                isFinal: payload.isFinal,
                source: "lk.transcription"
            )
        }
    }

    @MainActor
    private func emitTranscript(
        id: String,
        speaker: TranscriptUpdate.Speaker,
        text: String,
        isFinal: Bool,
        source: String
    ) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let key = "\(id)|\(speaker.rawValue)|\(isFinal)|\(text)"
        seenTranscriptLock.lock()
        defer { seenTranscriptLock.unlock() }
        let inserted = seenTranscriptKeys.insert(key).inserted
        if seenTranscriptKeys.count > 600 {
            seenTranscriptKeys.removeAll(keepingCapacity: true)
        }
        guard inserted else { return }

        let update = TranscriptUpdate(id: id, speaker: speaker, text: trimmed, isFinal: isFinal)
        AppLogger.debug("Transcript \(speaker.rawValue) final=\(isFinal) length=\(trimmed.count) source=\(source)", category: .livekit)
        emitTranscript(update)
    }

    private nonisolated func parseFallbackPayload(data: Data) -> (id: String, text: String, isFinal: Bool, speaker: TranscriptUpdate.Speaker?)? {
        guard
            let object = try? JSONSerialization.jsonObject(with: data),
            let dict = object as? [String: Any]
        else {
            return nil
        }

        if let segments = dict["segments"] as? [[String: Any]] {
            for segment in segments {
                if let parsed = parseSegmentDict(segment) {
                    return parsed
                }
            }
            return nil
        }

        return parseSegmentDict(dict)
    }

    private nonisolated func parseSegmentDict(_ dict: [String: Any]) -> (id: String, text: String, isFinal: Bool, speaker: TranscriptUpdate.Speaker?)? {
        guard let text = dict["text"] as? String else { return nil }
        let id = (dict["id"] as? String) ?? UUID().uuidString
        let isFinal = (dict["is_final"] as? Bool) ?? (dict["isFinal"] as? Bool) ?? true
        let speakerRaw = (dict["speaker"] as? String)?.lowercased()
        let speaker: TranscriptUpdate.Speaker?
        switch speakerRaw {
        case "learner", "user", "you":
            speaker = .learner
        case "tutor", "assistant", "agent", "ai":
            speaker = .tutor
        default:
            speaker = nil
        }
        return (id: id, text: text, isFinal: isFinal, speaker: speaker)
    }

    @MainActor
    private func emitTranscript(_ update: TranscriptUpdate) {
        let handlers = Array(transcriptHandlers.values)
        handlers.forEach { $0(update) }
    }

    @MainActor
    private func emitConnection(_ event: AgentConnectionEvent) {
        let handlers = Array(connectionHandlers.values)
        handlers.forEach { $0(event) }
    }

    @MainActor
    private func setConnected(_ value: Bool) {
        isConnected = value
    }

    @MainActor
    private func setMicrophoneStarted(_ value: Bool) {
        isMicrophoneStarted = value
    }
}

private extension AgentConnectionState {
    init(_ state: ConnectionState) {
        switch state {
        case .disconnected:
            self = .disconnected
        case .connecting:
            self = .connecting
        case .reconnecting:
            self = .reconnecting
        case .connected:
            self = .connected
        case .disconnecting:
            self = .disconnecting
        }
    }
}
