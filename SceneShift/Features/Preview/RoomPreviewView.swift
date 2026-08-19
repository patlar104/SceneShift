import Combine
import RealityKit
import SwiftUI
import UIKit

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
                    walkthroughControls
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
        VStack {
            Spacer()
            HStack(alignment: .bottom) {
                Text("Drag to look · Two-finger pan · Pinch to move")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                Spacer()
                Button {
                    resetToken += 1
                } label: {
                    Label("Reset", systemImage: "camera.rotate")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
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
                try await Self.loadEntity(from: url)
            }
            loadedEntity = entity
            loadState = .ready
        } catch {
            loadedEntity = nil
            loadState = .finished(error: error)
        }
    }

    @MainActor
    private static func loadEntity(from url: URL) async throws -> Entity {
        if #available(iOS 18.0, *) {
            return try await Entity(contentsOf: url)
        }
        return try await loadEntityUsingLoadAsync(from: url)
    }

    @MainActor
    private static func loadEntityUsingLoadAsync(from url: URL) async throws -> Entity {
        let box = LoadAsyncBox()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                box.fail = { error in
                    box.resumeOnce {
                        continuation.resume(throwing: error)
                    }
                }
                box.cancellable = Entity.loadAsync(contentsOf: url).sink(
                    receiveCompletion: { completion in
                        if case let .failure(error) = completion {
                            box.fail?(error)
                        }
                        box.cancellable = nil
                    },
                    receiveValue: { entity in
                        box.resumeOnce {
                            continuation.resume(returning: entity)
                        }
                    }
                )
            }
        } onCancel: {
            box.cancellable?.cancel()
            box.fail?(CancellationError())
            box.cancellable = nil
        }
    }
}

private final class LoadAsyncBox {
    var cancellable: AnyCancellable?
    var fail: ((Error) -> Void)?
    private var didResume = false

    func resumeOnce(_ resume: () -> Void) {
        guard !didResume else { return }
        didResume = true
        resume()
    }
}

enum PreviewLoadState: Equatable {
    case loading
    case ready
    case failed(String)

    static func finished(error: Error?) -> PreviewLoadState {
        if let error {
            return .failed(error.localizedDescription)
        }
        return .ready
    }
}

enum PreviewLoadError: Error, Equatable, LocalizedError {
    case timedOut

    var errorDescription: String? {
        switch self {
        case .timedOut:
            return "Preview took too long to load."
        }
    }
}

enum PreviewLoad {
    static let timeoutNanoseconds: UInt64 = 15_000_000_000

    static func withTimeout<T>(
        nanoseconds: UInt64 = timeoutNanoseconds,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: nanoseconds)
                throw PreviewLoadError.timedOut
            }
            defer { group.cancelAll() }
            guard let value = try await group.next() else {
                throw PreviewLoadError.timedOut
            }
            return value
        }
    }
}

struct WalkthroughCamera: Equatable {
    var eye: SIMD3<Float>
    var yaw: Float
    var pitch: Float

    static let pitchLimit: Float = (.pi / 2) - 0.05
    static let lookSensitivity: Float = 0.005
    static let panSensitivity: Float = 0.008
    static let dollySensitivity: Float = 2.5

    var lookDirection: SIMD3<Float> {
        let cp = cos(pitch)
        let sp = sin(pitch)
        let cy = cos(yaw)
        let sy = sin(yaw)
        return simd_normalize(SIMD3(sy * cp, sp, -cy * cp))
    }

    var forwardOnGround: SIMD3<Float> {
        let look = lookDirection
        let flattened = SIMD3(look.x, 0, look.z)
        let length = simd_length(flattened)
        guard length > 1e-4 else { return SIMD3(0, 0, -1) }
        return flattened / length
    }

    var rightOnGround: SIMD3<Float> {
        simd_normalize(simd_cross(forwardOnGround, SIMD3(0, 1, 0)))
    }

    mutating func applyLook(translation: CGSize) {
        yaw -= Float(translation.width) * Self.lookSensitivity
        pitch -= Float(translation.height) * Self.lookSensitivity
        pitch = min(max(pitch, -Self.pitchLimit), Self.pitchLimit)
    }

    mutating func applyPan(translation: CGSize) {
        let dx = Float(translation.width) * Self.panSensitivity
        let dy = Float(translation.height) * Self.panSensitivity
        eye += rightOnGround * -dx
        eye += forwardOnGround * dy
    }

    mutating func applyDolly(scale: Float, previousScale: Float) {
        guard previousScale > 0, scale > 0 else { return }
        let amount = log(scale / previousScale) * Self.dollySensitivity
        eye += lookDirection * amount
    }

    func lookTarget() -> SIMD3<Float> {
        eye + lookDirection
    }

    static func framed(in bounds: BoundingBox) -> WalkthroughCamera {
        let roomHeight = max(bounds.extents.y, 0.5)
        let eyeHeight = min(1.55, max(0.4, roomHeight * 0.55))
        return WalkthroughCamera(
            eye: SIMD3(bounds.center.x, bounds.min.y + eyeHeight, bounds.center.z),
            yaw: 0,
            pitch: 0
        )
    }
}

private struct RoomWalkthroughARView: UIViewRepresentable {
    let entity: Entity
    var resetToken: Int

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        configureNonAR(view)
        context.coordinator.attach(to: view)
        context.coordinator.install(entity)
        context.coordinator.resetToken = resetToken
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        configureNonAR(uiView)
        if context.coordinator.installedEntity !== entity {
            context.coordinator.install(entity)
        }
        if context.coordinator.resetToken != resetToken {
            context.coordinator.resetToken = resetToken
            context.coordinator.resetCamera()
        }
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        uiView.session.pause()
        coordinator.detach()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var resetToken = 0
        private(set) var installedEntity: Entity?

        private weak var arView: ARView?
        private var cameraEntity: PerspectiveCamera?
        private var roomAnchor: AnchorEntity?
        private var cameraState = WalkthroughCamera(eye: SIMD3(0, 1.5, 0), yaw: 0, pitch: 0)
        private var initialCamera = WalkthroughCamera(eye: SIMD3(0, 1.5, 0), yaw: 0, pitch: 0)
        private var lastLookTranslation: CGSize = .zero
        private var lastPanTranslation: CGSize = .zero
        private var lastPinchScale: CGFloat = 1

        func attach(to view: ARView) {
            arView = view
            installGestures(on: view)
            installCamera(in: view)
        }

        func detach() {
            if let roomAnchor, let arView {
                arView.scene.removeAnchor(roomAnchor)
            }
            roomAnchor = nil
            installedEntity = nil
            arView = nil
        }

        func install(_ entity: Entity) {
            guard let arView else { return }

            if let roomAnchor {
                arView.scene.removeAnchor(roomAnchor)
                self.roomAnchor = nil
            }

            entity.removeFromParent()
            let anchor = AnchorEntity(world: .zero)
            anchor.anchoring = AnchoringComponent(.world(transform: matrix_identity_float4x4))
            anchor.addChild(entity)
            addLights(to: anchor, around: entity)
            arView.scene.addAnchor(anchor)
            roomAnchor = anchor
            installedEntity = entity

            let bounds = entity.visualBounds(relativeTo: nil)
            let framed = bounds.isEmpty
                ? WalkthroughCamera(eye: SIMD3(0, 1.5, 2), yaw: 0, pitch: 0)
                : WalkthroughCamera.framed(in: bounds)
            initialCamera = framed
            cameraState = framed
            applyCamera()
        }

        func resetCamera() {
            cameraState = initialCamera
            applyCamera()
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }

        private func installCamera(in view: ARView) {
            let camera = PerspectiveCamera()
            camera.camera.fieldOfViewInDegrees = 70
            let cameraAnchor = AnchorEntity(world: .zero)
            cameraAnchor.anchoring = AnchoringComponent(.world(transform: matrix_identity_float4x4))
            cameraAnchor.addChild(camera)
            view.scene.addAnchor(cameraAnchor)
            cameraEntity = camera
            applyCamera()
        }

        private func addLights(to anchor: AnchorEntity, around entity: Entity) {
            let bounds = entity.visualBounds(relativeTo: nil)
            let center = bounds.isEmpty ? SIMD3<Float>(0, 1.5, 0) : bounds.center
            let ceiling = bounds.isEmpty ? SIMD3<Float>(0, 3, 0) : SIMD3(center.x, bounds.max.y + 0.4, center.z)

            let key = DirectionalLight()
            key.light.color = .white
            key.light.intensity = 1200
            key.look(at: center, from: ceiling + SIMD3(2, 1, 2), relativeTo: nil)
            anchor.addChild(key)

            let fill = PointLight()
            fill.light.color = .white
            fill.light.intensity = 8000
            fill.light.attenuationRadius = 12
            fill.position = ceiling
            anchor.addChild(fill)
        }

        private func installGestures(on view: ARView) {
            let look = UIPanGestureRecognizer(target: self, action: #selector(handleLook(_:)))
            look.minimumNumberOfTouches = 1
            look.maximumNumberOfTouches = 1
            look.delegate = self
            view.addGestureRecognizer(look)

            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            pan.minimumNumberOfTouches = 2
            pan.maximumNumberOfTouches = 2
            pan.delegate = self
            view.addGestureRecognizer(pan)

            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            pinch.delegate = self
            view.addGestureRecognizer(pinch)
        }

        private func applyCamera() {
            cameraEntity?.look(at: cameraState.lookTarget(), from: cameraState.eye, relativeTo: nil)
        }

        @objc private func handleLook(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: gesture.view)
            switch gesture.state {
            case .began:
                lastLookTranslation = CGSize(width: translation.x, height: translation.y)
            case .changed:
                let delta = CGSize(
                    width: translation.x - lastLookTranslation.width,
                    height: translation.y - lastLookTranslation.height
                )
                lastLookTranslation = CGSize(width: translation.x, height: translation.y)
                cameraState.applyLook(translation: delta)
                applyCamera()
            default:
                lastLookTranslation = .zero
            }
        }

        @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: gesture.view)
            switch gesture.state {
            case .began:
                lastPanTranslation = CGSize(width: translation.x, height: translation.y)
            case .changed:
                let delta = CGSize(
                    width: translation.x - lastPanTranslation.width,
                    height: translation.y - lastPanTranslation.height
                )
                lastPanTranslation = CGSize(width: translation.x, height: translation.y)
                cameraState.applyPan(translation: delta)
                applyCamera()
            default:
                lastPanTranslation = .zero
            }
        }

        @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            switch gesture.state {
            case .began:
                lastPinchScale = gesture.scale
            case .changed:
                cameraState.applyDolly(scale: Float(gesture.scale), previousScale: Float(lastPinchScale))
                lastPinchScale = gesture.scale
                applyCamera()
            default:
                lastPinchScale = 1
            }
        }
    }
}

private func configureNonAR(_ view: ARView) {
    view.automaticallyConfigureSession = false
    view.cameraMode = .nonAR
    view.session.pause()
    view.environment.background = .color(UIColor.black)
    view.environment.lighting.intensityExponent = 1.2
    view.environment.sceneUnderstanding.options = []
    view.renderOptions = [
        .disablePersonOcclusion,
        .disableDepthOfField,
        .disableMotionBlur,
        .disableCameraGrain,
        .disableGroundingShadows,
        .disableAREnvironmentLighting
    ]
}
