import Combine
import Foundation
import RoomPlan

enum ScanStoreError: Error, Equatable {
    case scanNotFound
    case corruptIndex
    case fileDeletionFailed(String)
}

@MainActor
final class ScanStore: ObservableObject {
    @Published private(set) var scans: [SavedScan] = []
    @Published private(set) var indexLoadError: ScanStoreError?

    private let persistence: ScanPersistence
    private var hasLoadedIndex = false

    init(directory: URL? = nil) {
        let resolvedDirectory: URL
        if let directory {
            resolvedDirectory = directory
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            resolvedDirectory = appSupport.appendingPathComponent("Scans", isDirectory: true)
        }
        self.persistence = ScanPersistence(directory: resolvedDirectory)
    }

    func loadIndexIfNeeded() async {
        guard !hasLoadedIndex else { return }
        hasLoadedIndex = true
        do {
            let (loadedScans, loadError) = try await persistence.loadIndex()
            scans = loadedScans
            indexLoadError = loadError
        } catch {
            scans = []
            indexLoadError = .corruptIndex
        }
    }

    func save(room: CapturedRoom, name: String) async throws -> SavedScan {
        let scan = try await persistence.save(room: room, name: name)
        scans.append(scan)
        try await persistence.persistIndex(scans)
        return scan
    }

    /// Persists encoded room bytes. Production uses `save(room:name:)`; tests use this until a device fixture exists.
    func save(roomData: Data, name: String) async throws -> SavedScan {
        let scan = try await persistence.save(roomData: roomData, name: name)
        scans.append(scan)
        try await persistence.persistIndex(scans)
        return scan
    }

    func loadRoom(for scan: SavedScan) async throws -> CapturedRoom {
        try await persistence.loadRoom(for: scan)
    }

    func delete(_ scan: SavedScan) async throws {
        guard scans.contains(where: { $0.id == scan.id }) else {
            throw ScanStoreError.scanNotFound
        }
        try await persistence.deleteFiles(for: scan)
        scans.removeAll { $0.id == scan.id }
        try await persistence.persistIndex(scans)
    }

    func rename(_ scan: SavedScan, to name: String) async throws {
        guard let index = scans.firstIndex(where: { $0.id == scan.id }) else {
            throw ScanStoreError.scanNotFound
        }
        var updated = scans[index]
        updated.name = name
        scans[index] = updated
        try await persistence.persistIndex(scans)
    }

    func fileSize(for scan: SavedScan) async -> Int64 {
        await persistence.fileSize(for: scan)
    }

    func exportUSDZ(for scan: SavedScan) async throws -> URL {
        let result = try await persistence.exportUSDZ(for: scan)
        if let usdzFileName = result.usdzFileName,
            let index = scans.firstIndex(where: { $0.id == scan.id })
        {
            var updated = scans[index]
            updated.usdzFileName = usdzFileName
            scans[index] = updated
            try await persistence.persistIndex(scans)
        }
        return result.url
    }
}
