import RealityKit
import SwiftUI

struct RoomPreviewView: View {
    let url: URL

    @State private var resetToken = 0
    @State private var retryCount = 0
    @State private var loadState: PreviewLoadState = .loading
    @State private var loadedEntity: Entity?

    var body: some View {
        ZStack {
            switch loadState {
            case .loading:
                ProgressView("Loading preview…")
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            case .failed(let message):
                ContentUnavailableView {
                    Label("Preview unavailable", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Retry") {
                        retryLoad()
                    }
                }
            case .ready:
                if let loadedEntity {
                    RoomWalkthroughARView(entity: loadedEntity, resetToken: resetToken)
                        .id(url)
                        .ignoresSafeArea(edges: .bottom)
                        .overlay(alignment: .bottom) {
                            walkthroughControls
                        }
                }
            }
        }
        .task(id: loadTaskID) {
            await loadPreview()
        }
        .onChange(of: url) { _, _ in
            retryCount = 0
            loadedEntity = nil
            loadState = .loading
        }
    }

    private var loadTaskID: String {
        "\(url.absoluteString)#\(retryCount)"
    }

    private var walkthroughControls: some View {
        HStack(alignment: .bottom) {
            Text("Drag to look · Two fingers to slide · Pinch to move")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .allowsHitTesting(false)
            Spacer()
                .allowsHitTesting(false)
            Button {
                resetToken += 1
            } label: {
                Label("Reset", systemImage: "camera.rotate")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func retryLoad() {
        loadedEntity = nil
        loadState = .loading
        retryCount += 1
    }

    @MainActor
    private func loadPreview() async {
        loadState = .loading
        loadedEntity = nil
        do {
            let entity = try await PreviewLoad.withTimeout {
                try await PreviewLoad.entity(from: url)
            }
            loadedEntity = entity
            loadState = .ready
        } catch {
            loadedEntity = nil
            loadState = .finished(error: error)
        }
    }
}
