import Foundation

enum SessionState: String {
    case idle = "Idle"
    case connecting = "Connecting"
    case connected = "Connected"
    case inSession = "In Session"
    case ended = "Ended"
    case failed = "Failed"
}
