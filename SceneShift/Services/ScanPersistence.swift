import Foundation
import RoomPlan
import os

/// Off-main-actor disk I/O for scan library files. `ScanStore` owns published state on `@MainActor`.
actor ScanPersistence {
    private let directory: URL
    private let fileManager: FileManager
    private let indexEncoder: JSONEncoder
    private let indexDecoder: JSONDecoder
    private let roomEncoder: JSONEncoder
    private let roomDecoder: JSONDecoder
    private let logger = Logger(subsystem: "com.sceneshift.app", category: "ScanPersistence")

    init(directory: URL) {
        self.directory = directory
        self.fileManager = .default

        let indexEncoder = JSONEncoder()
        indexEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        indexEncoder.dateEncodingStrategy = .iso8601
        self.indexEncoder = indexEncoder

        let indexDecoder = JSONDecoder()
        indexDecoder.dateDecodingStrategy = .iso8601
        self.indexDecoder = indexDecoder

        self.roomEncoder = JSONEncoder()
        self.roomDecoder = JSONDecoder()

        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func loadIndex() throws -> ([SavedScan], ScanStoreError?) {
        let indexURL = directory.appendingPathComponent("scans.json")
        guard fileManager.fileExists(atPath: indexURL.path) else {
            return ([], nil)
        }
        do {
            let data = try Data(contentsOf: indexURL)
            return (try indexDecoder.decode([SavedScan].self, from: data), nil)
        } catch {
            logger.error("Failed to load scan index: \(error.localizedDescription, privacy: .public)")
            return ([], .corruptIndex)
        }
    }

    func persistIndex(_ scans: [SavedScan]) throws {
        let data = try indexEncoder.encode(scans)
        try data.write(to: directory.appendingPathComponent("scans.json"), options: .atomic)
    }

    func save(room: CapturedRoom, name: String) throws -> SavedScan {
        try save(roomData: try roomEncoder.encode(room), name: name)
    }

    func save(roomData: Data, name: String) throws -> SavedScan {
        let id = UUID()
        let roomFileName = "\(id.uuidString).room"
        try roomData.write(to: directory.appendingPathComponent(roomFileName), options: .atomic)

        return SavedScan(
            id: id,
            name: name,
            createdAt: Date(),
            roomFileName: roomFileName,
            usdzFileName: nil
        )
    }

    func loadRoom(for scan: SavedScan) throws -> CapturedRoom {
        let data = try Data(contentsOf: roomURL(for: scan))
        return try roomDecoder.decode(CapturedRoom.self, from: data)
    }

    func deleteFiles(for scan: SavedScan) throws {
        try removeFileIfExists(at: roomURL(for: scan))
        if let usdzFileName = scan.usdzFileName {
            try removeFileIfExists(at: directory.appendingPathComponent(usdzFileName))
        }
    }

    func exportUSDZ(for scan: SavedScan) throws -> (url: URL, usdzFileName: String?) {
        if let cachedName = scan.usdzFileName {
            let cachedURL = directory.appendingPathComponent(cachedName)
            if fileManager.fileExists(atPath: cachedURL.path) {
                return (cachedURL, nil)
            }
        }

        let room = try loadRoom(for: scan)
        let fileName = "\(scan.id.uuidString).usdz"
        let url = directory.appendingPathComponent(fileName)
        try room.export(to: url, exportOptions: .mesh)
        return (url, fileName)
    }

    func fileSize(for scan: SavedScan) -> Int64 {
        byteCount(at: roomURL(for: scan)) + usdzByteCount(for: scan)
    }

    private func roomURL(for scan: SavedScan) -> URL {
        directory.appendingPathComponent(scan.roomFileName)
    }

    private func usdzByteCount(for scan: SavedScan) -> Int64 {
        guard let usdzFileName = scan.usdzFileName else { return 0 }
        return byteCount(at: directory.appendingPathComponent(usdzFileName))
    }

    private func byteCount(at url: URL) -> Int64 {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(values?.fileSize ?? 0)
    }

    private func removeFileIfExists(at url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else { return }
        do {
            try fileManager.removeItem(at: url)
        } catch {
            logger.error(
                "Failed to delete scan file \(url.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            throw ScanStoreError.fileDeletionFailed(url.lastPathComponent)
        }
    }
}
