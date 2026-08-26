import RealityKit
import SwiftUI
import UIKit

struct RoomWalkthroughARView: UIViewRepresentable {
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
        private var initialCamera = WalkthroughCamera(eye: SIMD3(0, 1.5, 0), yaw: 0, pitch: 0)
        private var gestureSession = WalkthroughGestureSession(
            camera: WalkthroughCamera(eye: SIMD3(0, 1.5, 0), yaw: 0, pitch: 0)
        )
        private var lookPan: UIPanGestureRecognizer?
        private var strafePan: UIPanGestureRecognizer?
        private var pinchGesture: UIPinchGestureRecognizer?

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
            let framed =
                bounds.isEmpty
                ? WalkthroughCamera(eye: SIMD3(0, 1.5, 2), yaw: 0, pitch: 0)
                : WalkthroughCamera.framed(in: bounds)
            initialCamera = framed
            gestureSession.reset(to: framed)
            applyCamera()
        }

        func resetCamera() {
            gestureSession.reset(to: initialCamera)
            applyCamera()
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            if gestureRecognizer === lookPan {
                return gestureRecognizer.numberOfTouches == 1
            }
            return gestureRecognizer.numberOfTouches == 2
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            isStrafe(gestureRecognizer) && isPinch(otherGestureRecognizer)
                || isPinch(gestureRecognizer) && isStrafe(otherGestureRecognizer)
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
            look.cancelsTouchesInView = true
            look.delegate = self
            lookPan = look
            view.addGestureRecognizer(look)

            let strafe = UIPanGestureRecognizer(target: self, action: #selector(handleStrafe(_:)))
            strafe.minimumNumberOfTouches = 2
            strafe.maximumNumberOfTouches = 2
            strafe.cancelsTouchesInView = true
            strafe.delegate = self
            strafePan = strafe
            view.addGestureRecognizer(strafe)

            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            pinch.cancelsTouchesInView = true
            pinch.delegate = self
            pinchGesture = pinch
            view.addGestureRecognizer(pinch)
        }

        private func applyCamera() {
            cameraEntity?.look(
                at: gestureSession.camera.lookTarget(),
                from: gestureSession.camera.eye,
                relativeTo: nil
            )
        }

        @objc private func handleLook(_ gesture: UIPanGestureRecognizer) {
            let translation = cgSize(gesture.translation(in: gesture.view))
            switch gesture.state {
            case .began:
                gestureSession.lookBegan(translation: translation, touchCount: gesture.numberOfTouches)
            case .changed:
                gestureSession.lookChanged(translation: translation, touchCount: gesture.numberOfTouches)
                applyCamera()
            default:
                gestureSession.lookEnded()
            }
        }

        @objc private func handleStrafe(_ gesture: UIPanGestureRecognizer) {
            let translation = cgSize(gesture.translation(in: gesture.view))
            switch gesture.state {
            case .began:
                gestureSession.strafeBegan(translation: translation, touchCount: gesture.numberOfTouches)
            case .changed:
                gestureSession.strafeChanged(translation: translation, touchCount: gesture.numberOfTouches)
                applyCamera()
            default:
                gestureSession.strafeEnded()
            }
        }

        @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            switch gesture.state {
            case .began:
                gestureSession.pinchBegan(scale: gesture.scale, touchCount: gesture.numberOfTouches)
            case .changed:
                gestureSession.pinchChanged(scale: gesture.scale, touchCount: gesture.numberOfTouches)
                applyCamera()
            default:
                gestureSession.pinchEnded()
            }
        }

        private func isStrafe(_ gesture: UIGestureRecognizer) -> Bool {
            gesture === strafePan
        }

        private func isPinch(_ gesture: UIGestureRecognizer) -> Bool {
            gesture === pinchGesture
        }

        private func cgSize(_ point: CGPoint) -> CGSize {
            CGSize(width: point.x, height: point.y)
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
        .disableAREnvironmentLighting,
    ]
}
