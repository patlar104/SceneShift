import Darwin
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var scanStore: ScanStore
    @State private var isPresentingScan = false
    @State private var scanPendingRename: SavedScan?
    @State private var renameDraft = ""
    @State private var showRenameAlert = false
    @State private var showLibraryError = false
    @State private var libraryErrorMessage = ""

    var body: some View {
        NavigationStack {
            Group {
                if scanStore.scans.isEmpty {
                    ContentUnavailableView(
                        "No Scans Yet",
                        systemImage: "cube.transparent",
                        description: Text("Tap New Scan to capture a room.")
                    )
                } else {
                    List {
                        ForEach(scanStore.scans) { scan in
                            NavigationLink(value: scan.id) {
                                scanRow(scan)
                            }
                            .swipeActions(edge: .leading) {
                                Button("Rename") {
                                    beginRename(scan)
                                }
                                .tint(.blue)
                            }
                            .contextMenu {
                                Button("Rename") {
                                    beginRename(scan)
                                }
                                Button("Delete", role: .destructive) {
                                    delete(scan)
                                }
                            }
                        }
                        .onDelete(perform: deleteAtOffsets)
                    }
                }
            }
            .navigationTitle("SceneShift")
            .navigationDestination(for: UUID.self) { scanID in
                ScanPreviewContainer(scanID: scanID)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Scan") {
                        isPresentingScan = true
                    }
                }
            }
            .fullScreenCover(isPresented: $isPresentingScan) {
                ScanSessionView()
                    .environmentObject(scanStore)
            }
            .alert("Rename scan", isPresented: $showRenameAlert) {
                TextField("Name", text: $renameDraft)
                Button("Save") {
                    commitRename()
                }
                Button("Cancel", role: .cancel) {
                    scanPendingRename = nil
                }
            }
            .alert("Could not update library", isPresented: $showLibraryError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(libraryErrorMessage)
            }
        }
    }

    private func scanRow(_ scan: SavedScan) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(scan.name)
            Text(formattedFileSize(for: scan))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func formattedFileSize(for scan: SavedScan) -> String {
        ByteCountFormatter.string(fromByteCount: scanStore.fileSize(for: scan), countStyle: .file)
    }

    private func beginRename(_ scan: SavedScan) {
        scanPendingRename = scan
        renameDraft = scan.name
        showRenameAlert = true
    }

    private func commitRename() {
        guard let scan = scanPendingRename else { return }
        scanPendingRename = nil
        let trimmed = renameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            try scanStore.rename(scan, to: trimmed)
        } catch {
            presentLibraryError(error)
        }
    }

    private func deleteAtOffsets(_ offsets: IndexSet) {
        let scansToDelete = offsets.map { scanStore.scans[$0] }
        for scan in scansToDelete {
            delete(scan)
        }
    }

    private func delete(_ scan: SavedScan) {
        do {
            try scanStore.delete(scan)
        } catch {
            presentLibraryError(error)
        }
    }

    private func presentLibraryError(_ error: Error) {
        libraryErrorMessage = error.localizedDescription
        showLibraryError = true
    }
}

struct ScanPreviewContainer: View {
    @EnvironmentObject private var scanStore: ScanStore
    let scanID: UUID

    @State private var previewURL: URL?
    @State private var isExporting = true
    @State private var showDiskFullAlert = false
    @State private var exportErrorMessage: String?

    private var currentScan: SavedScan? {
        scanStore.scans.first(where: { $0.id == scanID })
    }

    var body: some View {
        Group {
            if let previewURL {
                RoomPreviewView(url: previewURL)
                    .ignoresSafeArea(edges: .bottom)
            } else if isExporting {
                ProgressView("Exporting scan…")
            } else {
                ContentUnavailableView {
                    Label("Preview unavailable", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(exportErrorMessage ?? "Could not export this scan.")
                } actions: {
                    Button("Retry") {
                        isExporting = true
                        Task { await exportPreview() }
                    }
                }
            }
        }
        .navigationTitle(currentScan?.name ?? "Scan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let previewURL {
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: previewURL) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .alert("Not enough storage to export scan", isPresented: $showDiskFullAlert) {
            Button("OK", role: .cancel) {}
        }
        .task {
            await exportPreview()
        }
    }

    @MainActor
    private func exportPreview() async {
        // Let the navigation/view update finish before touching ScanStore or @State.
        await Task.yield()
        guard let scan = currentScan else {
            previewURL = nil
            exportErrorMessage = "Scan not found"
            isExporting = false
            return
        }
        exportErrorMessage = nil
        do {
            // Cached USDZ stays on disk until the user deletes the scan so share can finish.
            previewURL = try scanStore.exportUSDZ(for: scan)
        } catch {
            previewURL = nil
            if isInsufficientStorage(error) {
                showDiskFullAlert = true
                exportErrorMessage = "Not enough storage to export scan"
            } else {
                exportErrorMessage = error.localizedDescription
            }
        }
        isExporting = false
    }
}

private func isInsufficientStorage(_ error: Error) -> Bool {
    let nsError = error as NSError
    if nsError.domain == NSCocoaErrorDomain, nsError.code == NSFileWriteOutOfSpaceError {
        return true
    }
    if nsError.domain == NSPOSIXErrorDomain, nsError.code == Int(ENOSPC) {
        return true
    }
    if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
        return isInsufficientStorage(underlying)
    }
    return false
}
