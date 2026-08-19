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

    func testPanTranslatesOnGroundPlane() {
        var camera = WalkthroughCamera(eye: SIMD3(0, 1.5, 0), yaw: 0, pitch: 0)
        camera.applyPan(translation: CGSize(width: 50, height: -30))

        XCTAssertNotEqual(camera.eye.x, 0)
        XCTAssertNotEqual(camera.eye.z, 0)
        XCTAssertEqual(camera.eye.y, 1.5, accuracy: 0.0001)
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
