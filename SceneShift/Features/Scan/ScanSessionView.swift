import ARKit
import RoomPlan
import SwiftUI

struct ScanSessionView: View {
    @EnvironmentObject private var scanStore: ScanStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var isScanning = true
    @State private var isProcessing = false
    @State private var sessionGeneration = 0
    @State private var capturedRoom: CapturedRoom?
    @State private var scanName = ""
    @State private var showNamePrompt = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showInterruption = false
    @State private var showTimeHint = false

    var isLiDARAvailable: Bool {
        ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLiDARAvailable {
                    scanContent
                } else {
                    lidarRequired
                }
            }
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isScanning = false
                        dismiss()
                    }
                    .disabled(isProcessing)
                }
                if isLiDARAvailable {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            finishCapture()
                        }
                        .disabled(!isScanning || isProcessing)
                    }
                }
            }
            .alert("Name this scan", isPresented: $showNamePrompt) {
                TextField("Name", text: $scanName)
                Button("Save") {
                    saveScan()
                }
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            }
            .alert("Scan failed", isPresented: $showError) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(errorMessage)
            }
            .alert("Scan interrupted", isPresented: $showInterruption) {
                Button("Resume") {
                    resumeAfterInterruption()
                }
                Button("Discard", role: .destructive) {
                    isScanning = false
                    dismiss()
                }
            } message: {
                Text("The scan paused when the app left the foreground.")
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhase(newPhase)
        }
        .task(id: sessionGeneration) {
            await waitForTimeHint()
        }
    }

    private var scanContent: some View {
        ZStack(alignment: .bottom) {
            RoomCaptureRepresentable(
                isScanning: isScanning,
                sessionGeneration: sessionGeneration,
                onComplete: handleComplete
            )
            .ignoresSafeArea()

            if isProcessing {
                ProgressView("Processing scan…")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding()
            }

            if showTimeHint && isScanning {
                timeHintBanner
            }
        }
    }

    private var lidarRequired: some View {
        ContentUnavailableView(
            "LiDAR required",
            systemImage: "viewfinder",
            description: Text(
                "Room scanning needs an iPhone or iPad with a LiDAR Scanner. The simulator cannot capture rooms.")
        )
    }

    private var timeHintBanner: some View {
        VStack(spacing: 8) {
            Text("Long scans can heat the device and drift. Finish early if you can.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
            Button("Finish early") {
                finishCapture()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
    }

    private func finishCapture() {
        guard isScanning else { return }
        isScanning = false
        isProcessing = true
        showTimeHint = false
    }

    private func handleComplete(_ result: Result<CapturedRoom, Error>) {
        guard isProcessing else { return }
        isProcessing = false
        switch result {
        case .success(let room):
            capturedRoom = room
            if scanName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                scanName = "Scan"
            }
            showNamePrompt = true
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func saveScan() {
        guard let capturedRoom else { return }
        let trimmed = scanName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? "Scan" : trimmed
        do {
            _ = try scanStore.save(room: capturedRoom, name: name)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func handleScenePhase(_ newPhase: ScenePhase) {
        guard isLiDARAvailable else { return }
        guard isScanning, capturedRoom == nil, !isProcessing else { return }
        if newPhase == .background {
            isScanning = false
            showInterruption = true
        }
    }

    private func resumeAfterInterruption() {
        sessionGeneration += 1
        isScanning = true
        isProcessing = false
        showTimeHint = false
    }

    private func waitForTimeHint() async {
        showTimeHint = false
        do {
            try await Task.sleep(for: .seconds(3 * 60))
        } catch {
            return
        }
        guard !Task.isCancelled, isScanning else { return }
        showTimeHint = true
    }
}
