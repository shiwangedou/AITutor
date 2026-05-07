import Foundation
import os

enum AppLogger {
    enum Category: String {
        case session
        case audio
        case livekit
        case network
        case storage
        case app
    }

    private static let subsystem = Bundle.main.bundleIdentifier ?? "AITutor"

    static func debug(_ message: String, category: Category) {
        #if DEBUG
        let logger = Logger(subsystem: subsystem, category: category.rawValue)
        logger.debug("[test] \(message, privacy: .public)")
        #endif
    }

    static func error(_ message: String, category: Category) {
        #if DEBUG
        let logger = Logger(subsystem: subsystem, category: category.rawValue)
        logger.error("[test] \(message, privacy: .public)")
        #endif
    }

    static func describe(_ error: Error) -> String {
        let nsError = error as NSError
        var parts = [
            error.localizedDescription,
            "domain=\(nsError.domain)",
            "code=\(nsError.code)"
        ]

        if !nsError.userInfo.isEmpty {
            let details = nsError.userInfo
                .map { "\($0.key)=\($0.value)" }
                .sorted()
                .joined(separator: ", ")
            parts.append("userInfo={\(details)}")
        }

        return parts.joined(separator: " | ")
    }
}
