import Combine
import Foundation
import RoomPlan
import os

enum ScanStoreError: Error, Equatable {
    case scanNotFound
    case corruptIndex
    case fileDeletionFailed(String)
}

@MainActor
final class ScanStore: ObservableObject {
    @Published private(set) var scans: [SavedScan] = []
    @Published private(set) var indexLoadError: ScanStoreError?

    private let directory: URL
    private let fileManager: FileManager
    private let indexEncoder: JSONEncoder
    private let indexDecoder: JSONDecoder
    private let roomEncoder: JSONEncoder
    private let roomDecoder: JSONDecoder
    private let logger = Logger(subsystem: "com.sceneshift.app", category: "ScanStore")

    init(directory: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        if let directory {
            self.directory = directory
        } else {
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            self.directory = appSupport.appendingPathComponent("Scans", isDirectory: true)
        }

        let indexEncoder = JSONEncoder()
        indexEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        indexEncoder.dateEncodingStrategy = .iso8601
        self.indexEncoder = indexEncoder

        let indexDecoder = JSONDecoder()
        indexDecoder.dateDecodingStrategy = .iso8601
        self.indexDecoder = indexDecoder

        self.roomEncoder = JSONEncoder()
        self.roomDecoder = JSONDecoder()

        try? fileManager.createDirectory(at: self.directory, withIntermediateDirectories: true)
        loadIndex()
    }

    func save(room: CapturedRoom, name: String) throws -> SavedScan {
        try save(roomData: try roomEncoder.encode(room), name: name)
    }

    /// Persists encoded room bytes. Production uses `save(room:name:)`; tests use this until a device fixture exists.
    func save(roomData: Data, name: String) throws -> SavedScan {
        let id = UUID()
        let roomFileName = "\(id.uuidString).room"
        try roomData.write(to: directory.appendingPathComponent(roomFileName), options: .atomic)

        let scan = SavedScan(
            id: id,
            name: name,
            createdAt: Date(),
            roomFileName: roomFileName,
            usdzFileName: nil
        )
        scans.append(scan)
        try persistIndex()
        return scan
    }

    func loadRoom(for scan: SavedScan) throws -> CapturedRoom {
        let data = try Data(contentsOf: roomURL(for: scan))
        return try roomDecoder.decode(CapturedRoom.self, from: data)
    }

    func delete(_ scan: SavedScan) throws {
        guard scans.contains(where: { $0.id == scan.id }) else {
            throw ScanStoreError.scanNotFound
        }
        try removeFileIfExists(at: roomURL(for: scan))
        if let usdzFileName = scan.usdzFileName {
            try removeFileIfExists(at: directory.appendingPathComponent(usdzFileName))
        }
        scans.removeAll { $0.id == scan.id }
        try persistIndex()
    }

    func rename(_ scan: SavedScan, to name: String) throws {
        guard let index = scans.firstIndex(where: { $0.id == scan.id }) else {
            throw ScanStoreError.scanNotFound
        }
        var updated = scans[index]
        updated.name = name
        scans[index] = updated
        try persistIndex()
    }

    func fileSize(for scan: SavedScan) -> Int64 {
        byteCount(at: roomURL(for: scan)) + usdzByteCount(for: scan)
    }

    func exportUSDZ(for scan: SavedScan) throws -> URL {
        if let cachedName = scan.usdzFileName {
            let cachedURL = directory.appendingPathComponent(cachedName)
            if fileManager.fileExists(atPath: cachedURL.path) {
                return cachedURL
            }
        }

        let room = try loadRoom(for: scan)
        let fileName = "\(scan.id.uuidString).usdz"
        let url = directory.appendingPathComponent(fileName)
        try room.export(to: url, exportOptions: .mesh)

        if let index = scans.firstIndex(where: { $0.id == scan.id }) {
            var updated = scans[index]
            updated.usdzFileName = fileName
            scans[index] = updated
            try persistIndex()
        }
        return url
    }

    private var indexURL: URL {
        directory.appendingPathComponent("scans.json")
    }

    private func roomURL(for scan: SavedScan) -> URL {
        directory.appendingPathComponent(scan.roomFileName)
    }

    private func loadIndex() {
        guard fileManager.fileExists(atPath: indexURL.path) else {
            scans = []
            indexLoadError = nil
            return
        }
        do {
            let data = try Data(contentsOf: indexURL)
            scans = try indexDecoder.decode([SavedScan].self, from: data)
            indexLoadError = nil
        } catch {
            logger.error("Failed to load scan index: \(error.localizedDescription, privacy: .public)")
            scans = []
            indexLoadError = .corruptIndex
        }
    }

    private func persistIndex() throws {
        let data = try indexEncoder.encode(scans)
        try data.write(to: indexURL, options: .atomic)
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
