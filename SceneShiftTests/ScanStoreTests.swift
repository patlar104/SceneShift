import Combine
import XCTest
@testable import SceneShift

/// ScanStore index CRUD + room file I/O.
/// Full CapturedRoom JSON round-trip waits for SceneShiftTests/Fixtures/sample.room
/// from Task 3 device test. CapturedRoom has no public memberwise initializer
/// (only `init(from: Decoder)`); do not invent JSON that will not decode.
@MainActor
final class ScanStoreTests: XCTestCase {
    private var directory = FileManager.default.temporaryDirectory

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ScanStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testSaveAndLoadRoundTrip() async throws {
        let store = ScanStore(directory: directory)
        let roomData = Data("stub-room-bytes".utf8)

        let saved = try await store.save(roomData: roomData, name: "Living Room")

        XCTAssertEqual(saved.name, "Living Room")
        XCTAssertEqual(saved.roomFileName, "\(saved.id.uuidString).room")
        XCTAssertNil(saved.usdzFileName)
        XCTAssertEqual(store.scans, [saved])

        let writtenRoom = try Data(contentsOf: directory.appendingPathComponent(saved.roomFileName))
        XCTAssertEqual(writtenRoom, roomData)

        let reloaded = ScanStore(directory: directory)
        await reloaded.loadIndexIfNeeded()
        XCTAssertEqual(reloaded.scans.map(\.id), [saved.id])
        XCTAssertEqual(reloaded.scans.map(\.name), ["Living Room"])
        XCTAssertEqual(reloaded.scans.map(\.roomFileName), [saved.roomFileName])
        XCTAssertNil(reloaded.scans.first?.usdzFileName)
        XCTAssertNil(reloaded.indexLoadError)
    }

    func testRenameUpdatesIndex() async throws {
        let store = ScanStore(directory: directory)
        let saved = try await store.save(roomData: Data("stub".utf8), name: "Old Name")

        try await store.rename(saved, to: "New Name")

        XCTAssertEqual(store.scans.first?.name, "New Name")

        let reloaded = ScanStore(directory: directory)
        await reloaded.loadIndexIfNeeded()
        XCTAssertEqual(reloaded.scans.first?.id, saved.id)
        XCTAssertEqual(reloaded.scans.first?.name, "New Name")
    }

    func testDeleteRemovesScanAndFiles() async throws {
        let store = ScanStore(directory: directory)
        let saved = try await store.save(roomData: Data("stub".utf8), name: "To Delete")
        let roomURL = directory.appendingPathComponent(saved.roomFileName)

        XCTAssertTrue(FileManager.default.fileExists(atPath: roomURL.path))

        try await store.delete(saved)

        XCTAssertTrue(store.scans.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: roomURL.path))

        let reloaded = ScanStore(directory: directory)
        await reloaded.loadIndexIfNeeded()
        XCTAssertTrue(reloaded.scans.isEmpty)
    }

    func testFileSizeReturnsRoomByteCount() async throws {
        let store = ScanStore(directory: directory)
        let roomData = Data(repeating: 0xAB, count: 128)
        let saved = try await store.save(roomData: roomData, name: "Sized")

        let byteCount = await store.fileSize(for: saved)
        XCTAssertEqual(byteCount, Int64(roomData.count))
    }

    func testFileSizeIncludesCachedUSDZ() async throws {
        let store = ScanStore(directory: directory)
        let roomData = Data(repeating: 0x01, count: 10)
        let saved = try await store.save(roomData: roomData, name: "With USDZ")
        let usdzData = Data(repeating: 0x02, count: 25)
        let usdzName = "\(saved.id.uuidString).usdz"
        try usdzData.write(to: directory.appendingPathComponent(usdzName))

        var withUsdz = saved
        withUsdz.usdzFileName = usdzName

        let byteCount = await store.fileSize(for: withUsdz)
        XCTAssertEqual(byteCount, Int64(roomData.count + usdzData.count))
    }

    func testLoadRoomThrowsForStubbedRoomFile() async throws {
        let store = ScanStore(directory: directory)
        let saved = try await store.save(roomData: Data("not-a-captured-room".utf8), name: "Stub")

        do {
            _ = try await store.loadRoom(for: saved)
            XCTFail("Expected loadRoom to throw")
        } catch {
            // expected
        }
    }

    func testFileSizeDoesNotMutateScans() async throws {
        let store = ScanStore(directory: directory)
        let saved = try await store.save(roomData: Data(repeating: 0xAB, count: 64), name: "Sized")
        let scansBefore = store.scans
        var published = false
        let cancellable = store.objectWillChange.sink { published = true }

        _ = await store.fileSize(for: saved)

        XCTAssertFalse(published)
        XCTAssertEqual(store.scans, scansBefore)
        _ = cancellable
    }

    func testCachedUSDZExportDoesNotMutatePublishedScans() async throws {
        let store = ScanStore(directory: directory)
        let saved = try await store.save(roomData: Data("stub".utf8), name: "Cached")
        let usdzName = "\(saved.id.uuidString).usdz"
        try Data("usdz".utf8).write(to: directory.appendingPathComponent(usdzName))

        var indexed = saved
        indexed.usdzFileName = usdzName
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode([indexed]).write(to: directory.appendingPathComponent("scans.json"))

        let reloaded = ScanStore(directory: directory)
        await reloaded.loadIndexIfNeeded()
        let scan = try XCTUnwrap(reloaded.scans.first)
        var published = false
        let cancellable = reloaded.objectWillChange.sink { published = true }

        let url = try await reloaded.exportUSDZ(for: scan)

        XCTAssertEqual(url.lastPathComponent, usdzName)
        XCTAssertFalse(published)
        XCTAssertEqual(reloaded.scans.first?.usdzFileName, usdzName)
        _ = cancellable
    }

    func testCorruptIndexSetsLoadError() async throws {
        try Data("{ not valid json".utf8).write(to: directory.appendingPathComponent("scans.json"))

        let store = ScanStore(directory: directory)
        await store.loadIndexIfNeeded()

        XCTAssertTrue(store.scans.isEmpty)
        XCTAssertEqual(store.indexLoadError, .corruptIndex)
    }

    func testScanPreviewContainerInitDoesNotExport() async throws {
        let store = ScanStore(directory: directory)
        let saved = try await store.save(roomData: Data("stub".utf8), name: "Preview")
        let scansBefore = store.scans
        var published = false
        let cancellable = store.objectWillChange.sink { published = true }

        _ = ScanPreviewContainer(scanID: saved.id)

        XCTAssertFalse(published)
        XCTAssertEqual(store.scans, scansBefore)
        XCTAssertNil(store.scans.first?.usdzFileName)
        _ = cancellable
    }
}
