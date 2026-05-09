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

protocol LiveKitAgentControlling {
    var isConnected: Bool { get }
    var isMicrophoneStarted: Bool { get }
    var diagnosticSummary: String { get }

    func setTranscriptHandler(_ handler: @escaping @MainActor (TranscriptUpdate) -> Void)
    func connect(using config: SessionConfig) async throws
    func startMicrophone() async throws
    func startConversation() async throws
    func sendText(_ text: String) async throws
    func disconnect() async
}

final class LiveKitAgentClient: NSObject, LiveKitAgentControlling, RoomDelegate, @unchecked Sendable {
    private let room = Room()
    private var lastConfig: SessionConfig?
    private var transcriptHandler: (@MainActor (TranscriptUpdate) -> Void)?
    private(set) var isConnected = false
    private(set) var isMicrophoneStarted = false

    var diagnosticSummary: String {
        [
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

    func setTranscriptHandler(_ handler: @escaping @MainActor (TranscriptUpdate) -> Void) {
        transcriptHandler = handler
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

    func startConversation() async throws {
        let prompt = "Say exactly one short sentence: Hi! Ready?"
        AppLogger.debug("Sending start-conversation signal to LiveKit agent", category: .livekit)
        try await sendText(prompt)
        AppLogger.debug("Start-conversation signal sent", category: .livekit)
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

    nonisolated func room(_ room: Room, participant: Participant, trackPublication: TrackPublication, didReceiveTranscriptionSegments segments: [TranscriptionSegment]) {
        let speaker: TranscriptUpdate.Speaker = participant.isAgent ? .tutor : .learner

        for segment in segments {
            let text = segment.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }

            let update = TranscriptUpdate(
                id: segment.id,
                speaker: speaker,
                text: text,
                isFinal: segment.isFinal
            )

            AppLogger.debug("Transcript \(speaker.rawValue) final=\(segment.isFinal) length=\(text.count)", category: .livekit)
            Task { @MainActor [weak self] in
                self?.transcriptHandler?(update)
            }
        }
    }
}
