import XCTest
@testable import SceneShift

/// ScanStore index CRUD + room file I/O.
/// Full CapturedRoom JSON round-trip waits for SceneShiftTests/Fixtures/sample.room
/// from Task 3 device test. CapturedRoom has no public memberwise initializer
/// (only `init(from: Decoder)`); do not invent JSON that will not decode.
@MainActor
final class ScanStoreTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ScanStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        directory = nil
    }

    func testSaveAndLoadRoundTrip() throws {
        let store = ScanStore(directory: directory)
        let roomData = Data("stub-room-bytes".utf8)

        let saved = try store.save(roomData: roomData, name: "Living Room")

        XCTAssertEqual(saved.name, "Living Room")
        XCTAssertEqual(saved.roomFileName, "\(saved.id.uuidString).room")
        XCTAssertNil(saved.usdzFileName)
        XCTAssertEqual(store.scans, [saved])

        let writtenRoom = try Data(contentsOf: directory.appendingPathComponent(saved.roomFileName))
        XCTAssertEqual(writtenRoom, roomData)

        let reloaded = ScanStore(directory: directory)
        XCTAssertEqual(reloaded.scans.map(\.id), [saved.id])
        XCTAssertEqual(reloaded.scans.map(\.name), ["Living Room"])
        XCTAssertEqual(reloaded.scans.map(\.roomFileName), [saved.roomFileName])
        XCTAssertNil(reloaded.scans.first?.usdzFileName)
    }

    func testRenameUpdatesIndex() throws {
        let store = ScanStore(directory: directory)
        let saved = try store.save(roomData: Data("stub".utf8), name: "Old Name")

        try store.rename(saved, to: "New Name")

        XCTAssertEqual(store.scans.first?.name, "New Name")

        let reloaded = ScanStore(directory: directory)
        XCTAssertEqual(reloaded.scans.first?.id, saved.id)
        XCTAssertEqual(reloaded.scans.first?.name, "New Name")
    }

    func testDeleteRemovesScanAndFiles() throws {
        let store = ScanStore(directory: directory)
        let saved = try store.save(roomData: Data("stub".utf8), name: "To Delete")
        let roomURL = directory.appendingPathComponent(saved.roomFileName)

        XCTAssertTrue(FileManager.default.fileExists(atPath: roomURL.path))

        try store.delete(saved)

        XCTAssertTrue(store.scans.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: roomURL.path))

        let reloaded = ScanStore(directory: directory)
        XCTAssertTrue(reloaded.scans.isEmpty)
    }

    func testFileSizeReturnsRoomByteCount() throws {
        let store = ScanStore(directory: directory)
        let roomData = Data(repeating: 0xAB, count: 128)
        let saved = try store.save(roomData: roomData, name: "Sized")

        XCTAssertEqual(store.fileSize(for: saved), Int64(roomData.count))
    }

    func testFileSizeIncludesCachedUSDZ() throws {
        let store = ScanStore(directory: directory)
        let roomData = Data(repeating: 0x01, count: 10)
        let saved = try store.save(roomData: roomData, name: "With USDZ")
        let usdzData = Data(repeating: 0x02, count: 25)
        let usdzName = "\(saved.id.uuidString).usdz"
        try usdzData.write(to: directory.appendingPathComponent(usdzName))

        var withUsdz = saved
        withUsdz.usdzFileName = usdzName

        XCTAssertEqual(store.fileSize(for: withUsdz), Int64(roomData.count + usdzData.count))
    }

    func testLoadRoomThrowsForStubbedRoomFile() throws {
        let store = ScanStore(directory: directory)
        let saved = try store.save(roomData: Data("not-a-captured-room".utf8), name: "Stub")

        XCTAssertThrowsError(try store.loadRoom(for: saved))
    }
}
