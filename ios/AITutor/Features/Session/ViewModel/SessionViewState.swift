import Foundation

struct SessionViewState: Equatable {
    var sessionState: SessionState = .idle
    var statusText: String = "State: Idle"
    var voiceStateText: String = "Ready"
    var primaryHint: String = "Practice English speaking with short, supportive voice feedback."
    var connectionText: String = "Not connected"
    var profileText: String = LearningProfile.default.summaryLine
    var latestSummaryText: String = "No local summary yet."
    var latestSummaryRecord: SessionRecord?
    var runningSummaryText: String = "AI summary draft will appear during longer sessions. Only transcript text is sent; raw audio is never sent."
    var transcriptText: String = "Transcript will appear after you speak or type."
    var logText: String = ""
    var errorText: String?
    var messages: [ChatMessage] = []
    var voiceInputMode: VoiceInputMode = .automatic
    var isMicrophoneActive = false
    var isConnectEnabled = true
    var isStartEnabled = false
    var isEndEnabled = false
    var isReconnectEnabled = false
    var isClearHistoryEnabled = false
    var isTextInputEnabled = false
    var isMicEnabled = false
    var micButtonTitle = "Start voice input"
}
