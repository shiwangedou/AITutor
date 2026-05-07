import Foundation

enum AppConfig {
    static var backendBaseURL: URL {
        let value = Bundle.main.object(forInfoDictionaryKey: "BackendBaseURL") as? String
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = "http://127.0.0.1:8000"

        guard
            let rawValue = trimmed,
            !rawValue.isEmpty,
            let url = URL(string: rawValue)
        else {
            return URL(string: fallback)!
        }

        return url
    }
}
