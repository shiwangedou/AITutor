import Foundation

struct SessionViewState: Equatable {
    var sessionState: SessionState = .idle
    var statusText: String = "State: Idle"
    var primaryHint: String = "Practice English speaking with short, supportive voice feedback."
    var connectionText: String = "Not connected"
    var latestSummaryText: String = "No local summary yet."
    var runningSummaryText: String = "AI summary draft will appear during longer sessions. Only transcript text is sent; raw audio is never sent."
    var transcriptText: String = "Transcript will appear after Start. Voice transcription depends on LiveKit agent transcription events."
    var logText: String = ""
    var errorText: String?
    var isConnectEnabled = true
    var isStartEnabled = false
    var isEndEnabled = false
    var isReconnectEnabled = false
    var isClearHistoryEnabled = false
    var isTextInputEnabled = false
}
