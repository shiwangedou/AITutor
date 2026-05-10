import Foundation

protocol SessionStorageManaging {
    func loadRecentSessions() -> [SessionRecord]
    func save(_ record: SessionRecord) throws
    func deleteSession(id: String) throws
    func clear() throws
}

final class SessionStorageManager: SessionStorageManaging {
    private let maxRecords: Int
    private let fileManager: FileManager
    private let fileURL: URL

    init(maxRecords: Int = 20, fileManager: FileManager = .default, directoryURL: URL? = nil) {
        self.maxRecords = maxRecords
        self.fileManager = fileManager
        let directory = directoryURL ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let appDirectory = directory.appendingPathComponent("AITutor", isDirectory: true)
        try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        self.fileURL = appDirectory.appendingPathComponent("sessions.json")
    }

    func loadRecentSessions() -> [SessionRecord] {
        guard let data = try? Data(contentsOf: fileURL) else {
            return []
        }

        do {
            return try JSONDecoder().decode([SessionRecord].self, from: data)
        } catch {
            AppLogger.error("Failed to decode sessions: \(AppLogger.describe(error))", category: .storage)
            return []
        }
    }

    func save(_ record: SessionRecord) throws {
        var records = loadRecentSessions().filter { $0.id != record.id }
        records.insert(record, at: 0)
        records = Array(records.prefix(maxRecords))

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(records)
            try data.write(to: fileURL, options: [.atomic])
            AppLogger.debug("Saved session record id=\(record.id) count=\(records.count)", category: .storage)
        } catch {
            throw AppError.storageFailed(AppLogger.describe(error))
        }
    }

    func deleteSession(id: String) throws {
        let records = loadRecentSessions().filter { $0.id != id }
        do {
            if records.isEmpty {
                if fileManager.fileExists(atPath: fileURL.path) {
                    try fileManager.removeItem(at: fileURL)
                }
            } else {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(records)
                try data.write(to: fileURL, options: [.atomic])
            }
            AppLogger.debug("Deleted session record id=\(id) count=\(records.count)", category: .storage)
        } catch {
            throw AppError.storageFailed(AppLogger.describe(error))
        }
    }

    func clear() throws {
        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
            AppLogger.debug("Cleared local session history", category: .storage)
        } catch {
            throw AppError.storageFailed(AppLogger.describe(error))
        }
    }
}

protocol LearningProfileStoring {
    func loadDefaultProfile() -> LearningProfile
    func saveDefaultProfile(_ profile: LearningProfile)
    func resetDefaultProfile()
}

final class LearningProfileStore: LearningProfileStoring {
    private let userDefaults: UserDefaults
    private let key = "AITutor.defaultLearningProfile"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadDefaultProfile() -> LearningProfile {
        guard let data = userDefaults.data(forKey: key),
              let profile = try? JSONDecoder().decode(LearningProfile.self, from: data) else {
            return .default
        }
        return profile.normalized()
    }

    func saveDefaultProfile(_ profile: LearningProfile) {
        let normalized = profile.normalized()
        guard let data = try? JSONEncoder().encode(normalized) else { return }
        userDefaults.set(data, forKey: key)
    }

    func resetDefaultProfile() {
        userDefaults.removeObject(forKey: key)
    }
}

enum VoiceInputMode: String, Codable, CaseIterable, Equatable {
    case automatic
    case manual

    var displayName: String {
        switch self {
        case .automatic:
            return "Auto Voice"
        case .manual:
            return "Manual Voice"
        }
    }
}

protocol AppSettingsStoring: AnyObject {
    var voiceInputMode: VoiceInputMode { get set }
}

final class AppSettingsStore: AppSettingsStoring {
    private let userDefaults: UserDefaults
    private let voiceInputModeKey = "AITutor.voiceInputMode"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var voiceInputMode: VoiceInputMode {
        get {
            guard let rawValue = userDefaults.string(forKey: voiceInputModeKey),
                  let mode = VoiceInputMode(rawValue: rawValue) else {
                return .automatic
            }
            return mode
        }
        set { userDefaults.set(newValue.rawValue, forKey: voiceInputModeKey) }
    }
}
