import Foundation

protocol SessionStorageManaging {
    func loadRecentSessions() -> [SessionRecord]
    func save(_ record: SessionRecord) throws
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
