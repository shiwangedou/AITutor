import Foundation

enum AppConfig {
    private static let backendBaseURLOverrideKey = "AITutor.backendBaseURLOverride"
    private static let fallbackBackendBaseURL = "http://127.0.0.1:8000"

    static var backendBaseURL: URL {
        if let override = backendBaseURLOverride {
            return override
        }
        return bundledBackendBaseURL
    }

    static var bundledBackendBaseURL: URL {
        let value = Bundle.main.object(forInfoDictionaryKey: "BackendBaseURL") as? String
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            let rawValue = trimmed,
            !rawValue.isEmpty,
            let url = URL(string: rawValue)
        else {
            return URL(string: fallbackBackendBaseURL)!
        }

        return url
    }

    static var backendBaseURLOverride: URL? {
        guard
            let rawValue = UserDefaults.standard.string(forKey: backendBaseURLOverrideKey),
            let url = normalizedBackendBaseURL(from: rawValue)
        else {
            return nil
        }
        return url
    }

    static var backendBaseURLSourceDescription: String {
        backendBaseURLOverride == nil ? "Bundled build setting" : "Local override"
    }

    @discardableResult
    static func setBackendBaseURLOverride(_ value: String) -> Bool {
        guard let url = normalizedBackendBaseURL(from: value) else {
            return false
        }
        UserDefaults.standard.set(url.absoluteString, forKey: backendBaseURLOverrideKey)
        return true
    }

    static func clearBackendBaseURLOverride() {
        UserDefaults.standard.removeObject(forKey: backendBaseURLOverrideKey)
    }

    static func normalizedBackendBaseURL(from value: String) -> URL? {
        var trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if !trimmed.contains("://") {
            trimmed = "http://\(trimmed)"
        }

        while trimmed.hasSuffix("/") {
            trimmed.removeLast()
        }

        guard
            let url = URL(string: trimmed),
            let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https",
            url.host?.isEmpty == false
        else {
            return nil
        }

        return url
    }
}
