import Foundation
import XCTest
@testable import SceneShift

final class SceneShiftTests: XCTestCase {
    func testSavedScanCodableRoundTrip() throws {
        let original = SavedScan(
            id: UUID(),
            name: "Living Room",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            roomFileName: "scan.room",
            usdzFileName: "scan.usdz"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(SavedScan.self, from: encoder.encode(original))

        XCTAssertEqual(decoded, original)
    }
}
