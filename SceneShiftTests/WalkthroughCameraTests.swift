import RealityKit
import XCTest

@testable import SceneShift

final class WalkthroughCameraTests: XCTestCase {
    func testLookRotatesWithoutMovingEye() {
        var camera = WalkthroughCamera(eye: SIMD3(1, 1.5, 2), yaw: 0, pitch: 0)
        camera.applyLook(translation: CGSize(width: 40, height: 20))

        XCTAssertEqual(camera.eye.x, 1, accuracy: 0.0001)
        XCTAssertEqual(camera.eye.y, 1.5, accuracy: 0.0001)
        XCTAssertEqual(camera.eye.z, 2, accuracy: 0.0001)
        XCTAssertNotEqual(camera.yaw, 0)
        XCTAssertNotEqual(camera.pitch, 0)
    }

    func testPanTranslatesOnGroundPlaneWithoutChangingLook() {
        var camera = WalkthroughCamera(eye: SIMD3(0, 1.5, 0), yaw: 0.4, pitch: -0.1)
        let yaw = camera.yaw
        let pitch = camera.pitch
        camera.applyPan(translation: CGSize(width: 50, height: -30))

        XCTAssertNotEqual(camera.eye.x, 0)
        XCTAssertNotEqual(camera.eye.z, 0)
        XCTAssertEqual(camera.eye.y, 1.5, accuracy: 0.0001)
        XCTAssertEqual(camera.yaw, yaw)
        XCTAssertEqual(camera.pitch, pitch)
    }

    func testDollyMovesThroughSpaceNotScalePivot() {
        var camera = WalkthroughCamera(eye: SIMD3(0, 1.5, 0), yaw: 0, pitch: 0)
        let start = camera.eye
        camera.applyDolly(scale: 2, previousScale: 1)

        XCTAssertEqual(camera.eye.x, start.x, accuracy: 0.001)
        XCTAssertLessThan(camera.eye.z, start.z)
        XCTAssertGreaterThan(simd_distance(camera.eye, start), 0.5)
    }

    func testPitchIsClamped() {
        var camera = WalkthroughCamera(eye: SIMD3(0, 1.5, 0), yaw: 0, pitch: 0)
        camera.applyLook(translation: CGSize(width: 0, height: 10_000))

        XCTAssertGreaterThan(camera.pitch, -WalkthroughCamera.pitchLimit - 0.001)
        XCTAssertLessThan(camera.pitch, WalkthroughCamera.pitchLimit + 0.001)
    }

    func testFramedCameraStandsInsideBounds() {
        let bounds = BoundingBox(min: SIMD3(0, -0.87, -3), max: SIMD3(4, 1.58, 1))
        let camera = WalkthroughCamera.framed(in: bounds)

        XCTAssertEqual(camera.eye.x, bounds.center.x, accuracy: 0.001)
        XCTAssertEqual(camera.eye.z, bounds.center.z, accuracy: 0.001)
        XCTAssertGreaterThan(camera.eye.y, bounds.min.y + 0.3)
        XCTAssertLessThan(camera.eye.y, bounds.max.y)
    }
}

final class WalkthroughGestureSessionTests: XCTestCase {
    private func makeSession() -> WalkthroughGestureSession {
        WalkthroughGestureSession(camera: WalkthroughCamera(eye: SIMD3(1, 1.5, 2), yaw: 0, pitch: 0))
    }

    private func dragLook(_ session: inout WalkthroughGestureSession, to translation: CGSize) {
        session.lookBegan(translation: .zero, touchCount: 1)
        session.lookChanged(
            translation: CGSize(width: WalkthroughGestureSession.lookDeadzone, height: 0), touchCount: 1)
        session.lookChanged(translation: translation, touchCount: 1)
    }

    func testOneFingerLookChangesRotationOnly() {
        var session = makeSession()
        let start = session.camera
        dragLook(&session, to: CGSize(width: 40, height: 20))

        XCTAssertEqual(session.camera.eye.x, start.eye.x, accuracy: 0.0001)
        XCTAssertEqual(session.camera.eye.y, start.eye.y, accuracy: 0.0001)
        XCTAssertEqual(session.camera.eye.z, start.eye.z, accuracy: 0.0001)
        XCTAssertNotEqual(session.camera.yaw, start.yaw)
        XCTAssertNotEqual(session.camera.pitch, start.pitch)
        XCTAssertEqual(session.mode, .look)
    }

    func testOneFingerStrafeEventsDoNotMoveCamera() {
        var session = makeSession()
        let start = session.camera
        dragLook(&session, to: CGSize(width: 24, height: 0))
        let yawAfterLook = session.camera.yaw

        session.strafeBegan(translation: CGSize(width: 80, height: 0), touchCount: 1)
        session.strafeChanged(translation: CGSize(width: 160, height: 0), touchCount: 1)

        XCTAssertEqual(session.camera.eye.x, start.eye.x, accuracy: 0.0001)
        XCTAssertEqual(session.camera.eye.z, start.eye.z, accuracy: 0.0001)
        XCTAssertEqual(session.camera.yaw, yawAfterLook)
        XCTAssertEqual(session.mode, .look)
    }

    func testTwoFingerStrafeChangesPositionNotYaw() {
        var session = makeSession()
        session.strafeBegan(translation: .zero, touchCount: 2)
        session.strafeChanged(translation: .zero, touchCount: 2)
        session.strafeChanged(translation: CGSize(width: 40, height: -20), touchCount: 2)
        session.strafeChanged(translation: CGSize(width: 50, height: -24), touchCount: 2)

        XCTAssertNotEqual(session.camera.eye.x, 1)
        XCTAssertNotEqual(session.camera.eye.z, 2)
        XCTAssertEqual(session.camera.eye.y, 1.5, accuracy: 0.0001)
        XCTAssertEqual(session.camera.yaw, 0)
        XCTAssertEqual(session.camera.pitch, 0)
        XCTAssertEqual(session.mode, .strafe)
    }

    func testSecondFingerCancelsLookWithoutTurningLeftoverIntoStrafe() {
        var session = makeSession()
        dragLook(&session, to: CGSize(width: 30, height: 0))
        let yawAfterLook = session.camera.yaw
        let eyeAfterLook = session.camera.eye

        session.lookChanged(translation: CGSize(width: 80, height: 0), touchCount: 2)
        XCTAssertEqual(session.camera.yaw, yawAfterLook)
        XCTAssertEqual(session.camera.eye.x, eyeAfterLook.x, accuracy: 0.0001)
        XCTAssertEqual(session.mode, .idle)

        session.strafeBegan(translation: CGSize(width: 80, height: 0), touchCount: 2)
        session.strafeChanged(translation: CGSize(width: 140, height: 0), touchCount: 2)
        XCTAssertEqual(session.camera.eye.x, eyeAfterLook.x, accuracy: 0.0001)
        XCTAssertEqual(session.camera.yaw, yawAfterLook)

        session.strafeChanged(translation: CGSize(width: 160, height: 0), touchCount: 2)
        XCTAssertEqual(session.camera.eye.x, eyeAfterLook.x, accuracy: 0.0001)

        session.strafeChanged(translation: CGSize(width: 180, height: 0), touchCount: 2)
        XCTAssertNotEqual(session.camera.eye.x, eyeAfterLook.x)
        XCTAssertEqual(session.camera.yaw, yawAfterLook)
        XCTAssertEqual(session.mode, .strafe)
    }

    func testLookDeadzoneDoesNotTwitchCamera() {
        var session = makeSession()
        session.lookBegan(translation: .zero, touchCount: 1)
        session.lookChanged(translation: CGSize(width: 3, height: 2), touchCount: 1)

        XCTAssertEqual(session.camera.yaw, 0)
        XCTAssertEqual(session.camera.pitch, 0)
        XCTAssertEqual(session.camera.eye, SIMD3(1, 1.5, 2))
    }

    func testPinchDominanceIgnoresStrafeTranslation() {
        var session = makeSession()
        session.pinchBegan(scale: 1, touchCount: 2)
        session.strafeBegan(translation: .zero, touchCount: 2)
        session.pinchChanged(scale: 1, touchCount: 2)
        session.strafeChanged(translation: .zero, touchCount: 2)

        session.pinchChanged(scale: 1.2, touchCount: 2)
        session.strafeChanged(translation: CGSize(width: 4, height: 0), touchCount: 2)
        XCTAssertEqual(session.mode, .pinch)

        let eyeAfterLock = session.camera.eye
        session.pinchChanged(scale: 1.4, touchCount: 2)
        session.strafeChanged(translation: CGSize(width: 80, height: 0), touchCount: 2)

        XCTAssertEqual(session.mode, .pinch)
        XCTAssertEqual(session.camera.yaw, 0)
        XCTAssertNotEqual(session.camera.eye, eyeAfterLock)
        XCTAssertEqual(session.camera.eye.x, eyeAfterLock.x, accuracy: 0.001)
    }

    func testStrafeDominanceIgnoresPinchScale() {
        var session = makeSession()
        session.strafeBegan(translation: .zero, touchCount: 2)
        session.pinchBegan(scale: 1, touchCount: 2)
        session.strafeChanged(translation: .zero, touchCount: 2)
        session.pinchChanged(scale: 1, touchCount: 2)

        session.strafeChanged(translation: CGSize(width: 24, height: 0), touchCount: 2)
        session.pinchChanged(scale: 1.02, touchCount: 2)
        XCTAssertEqual(session.mode, .strafe)

        let eyeAfterLock = session.camera.eye
        let yaw = session.camera.yaw
        session.strafeChanged(translation: CGSize(width: 40, height: 0), touchCount: 2)
        session.pinchChanged(scale: 1.5, touchCount: 2)

        XCTAssertEqual(session.mode, .strafe)
        XCTAssertEqual(session.camera.yaw, yaw)
        XCTAssertNotEqual(session.camera.eye.x, eyeAfterLock.x)
    }
}

final class PreviewLoadStateTests: XCTestCase {
    func testFinishedClearsLoadingOnSuccess() {
        XCTAssertEqual(PreviewLoadState.finished(error: nil), .ready)
    }

    func testFinishedSurfacesFailureMessage() {
        XCTAssertEqual(
            PreviewLoadState.finished(error: PreviewLoadError.timedOut),
            .failed("Preview took too long to load.")
        )
    }

    func testTimeoutWinsOverSlowOperation() async {
        do {
            _ = try await PreviewLoad.withTimeout(nanoseconds: 50_000_000) {
                try await Task.sleep(nanoseconds: 2_000_000_000)
                return 1
            }
            XCTFail("Expected timeout")
        } catch {
            XCTAssertEqual(error as? PreviewLoadError, .timedOut)
        }
    }

    func testTimeoutReturnsFastResult() async throws {
        let value = try await PreviewLoad.withTimeout(nanoseconds: 1_000_000_000) {
            42
        }
        XCTAssertEqual(value, 42)
    }
}
