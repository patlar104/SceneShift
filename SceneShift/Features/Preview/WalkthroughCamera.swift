import CoreGraphics
import RealityKit
import simd

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
