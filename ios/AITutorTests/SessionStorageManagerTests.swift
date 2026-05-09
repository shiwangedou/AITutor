import Foundation
import XCTest
@testable import AITutor

final class SessionStorageManagerTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AITutorStorageTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let tempDirectory, FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.removeItem(at: tempDirectory)
        }
        tempDirectory = nil
    }

    func testSaveKeepsLatestTwentyRecords() throws {
        let manager = makeManager(maxRecords: 20)

        for index in 0..<25 {
            try manager.save(makeRecord(index: index))
        }

        let records = manager.loadRecentSessions()
        XCTAssertEqual(records.count, 20)
        XCTAssertEqual(records.first?.id, "session-24")
        XCTAssertEqual(records.last?.id, "session-5")
    }

    func testSaveReplacesExistingRecordAndMovesItToFront() throws {
        let manager = makeManager(maxRecords: 20)
        try manager.save(makeRecord(index: 1, summary: "old summary"))
        try manager.save(makeRecord(index: 2))
        try manager.save(makeRecord(index: 1, summary: "updated summary"))

        let records = manager.loadRecentSessions()
        XCTAssertEqual(records.count, 2)
        XCTAssertEqual(records.first?.id, "session-1")
        XCTAssertEqual(records.first?.summary, "updated summary")
    }

    func testClearRemovesPersistedSessions() throws {
        let manager = makeManager(maxRecords: 20)
        try manager.save(makeRecord(index: 1))

        try manager.clear()

        XCTAssertTrue(manager.loadRecentSessions().isEmpty)
    }

    private func makeManager(maxRecords: Int) -> SessionStorageManager {
        SessionStorageManager(maxRecords: maxRecords, fileManager: .default, directoryURL: tempDirectory)
    }

    private func makeRecord(index: Int, summary: String? = nil) -> SessionRecord {
        let startedAt = Date(timeIntervalSince1970: TimeInterval(index * 60))
        let endedAt = startedAt.addingTimeInterval(45)
        return SessionRecord(
            id: "session-\(index)",
            roomName: "room-\(index)",
            tutorSubject: "english-speaking",
            startedAt: startedAt,
            endedAt: endedAt,
            durationSeconds: 45,
            status: .ended,
            summary: summary ?? "summary-\(index)",
            aiSummary: nil,
            aiSummaryStatus: .localOnly
        )
    }
}
