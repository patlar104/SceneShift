import CoreGraphics
import Foundation

/// Exclusive walkthrough controls: 1-finger look, 2-finger strafe, pinch dolly.
/// UIKit recognizers feed this session; camera math stays in `WalkthroughCamera`.
struct WalkthroughGestureSession {
    enum Mode: Equatable {
        case idle
        case look
        case twoFingerUndecided
        case strafe
        case pinch
    }

    static let lookDeadzone: CGFloat = 6
    static let pinchScaleDominance: CGFloat = 0.08
    static let strafeTranslationDominance: CGFloat = 10

    var camera: WalkthroughCamera
    private(set) var mode: Mode = .idle

    private var lastLookTranslation: CGSize = .zero
    private var lastStrafeTranslation: CGSize = .zero
    private var lastPinchScale: CGFloat = 1
    private var lookPastDeadzone = false
    private var strafeBaselinePending = false
    private var pinchBaselinePending = false
    private var strafeRecognizerActive = false
    private var pinchRecognizerActive = false
    private var twoFingerOriginTranslation: CGSize = .zero
    private var twoFingerOriginScale: CGFloat = 1

    init(camera: WalkthroughCamera) {
        self.camera = camera
    }

    mutating func reset(to camera: WalkthroughCamera) {
        self.camera = camera
        endAll()
    }

    mutating func endAll() {
        mode = .idle
        lastLookTranslation = .zero
        lastStrafeTranslation = .zero
        lastPinchScale = 1
        lookPastDeadzone = false
        strafeBaselinePending = false
        pinchBaselinePending = false
        strafeRecognizerActive = false
        pinchRecognizerActive = false
        twoFingerOriginTranslation = .zero
        twoFingerOriginScale = 1
    }

    // MARK: Look (exactly one touch)

    mutating func lookBegan(translation: CGSize, touchCount: Int) {
        guard touchCount == 1 else {
            cancelLook()
            return
        }
        switch mode {
        case .strafe, .pinch, .twoFingerUndecided:
            return
        case .idle, .look:
            mode = .look
            lastLookTranslation = translation
            lookPastDeadzone = false
        }
    }

    mutating func lookChanged(translation: CGSize, touchCount: Int) {
        guard touchCount == 1 else {
            cancelLook()
            return
        }
        guard mode == .look else { return }

        if !lookPastDeadzone {
            let total = hypot(translation.width, translation.height)
            lastLookTranslation = translation
            if total < Self.lookDeadzone {
                return
            }
            lookPastDeadzone = true
            return
        }

        let delta = CGSize(
            width: translation.width - lastLookTranslation.width,
            height: translation.height - lastLookTranslation.height
        )
        lastLookTranslation = translation
        camera.applyLook(translation: delta)
    }

    mutating func lookEnded() {
        if mode == .look {
            mode = .idle
        }
        lastLookTranslation = .zero
        lookPastDeadzone = false
    }

    mutating func cancelLook() {
        lookEnded()
    }

    // MARK: Strafe (exactly two touches)

    mutating func strafeBegan(translation: CGSize, touchCount: Int) {
        guard touchCount == 2 else { return }
        cancelLook()
        strafeRecognizerActive = true
        lastStrafeTranslation = translation
        twoFingerOriginTranslation = translation
        strafeBaselinePending = true
        enterTwoFingerIfNeeded()
    }

    mutating func strafeChanged(translation: CGSize, touchCount: Int) {
        guard touchCount == 2 else { return }
        guard mode != .look else { return }

        if strafeBaselinePending {
            lastStrafeTranslation = translation
            twoFingerOriginTranslation = translation
            strafeBaselinePending = false
            return
        }

        if mode == .pinch {
            lastStrafeTranslation = translation
            return
        }

        if mode == .idle {
            enterTwoFingerIfNeeded()
        }

        if mode == .twoFingerUndecided {
            lastStrafeTranslation = translation
            lockTwoFingerIfReady(translation: translation, scale: lastPinchScale)
            return
        }

        guard mode == .strafe else { return }
        let delta = CGSize(
            width: translation.width - lastStrafeTranslation.width,
            height: translation.height - lastStrafeTranslation.height
        )
        lastStrafeTranslation = translation
        camera.applyPan(translation: delta)
    }

    mutating func strafeEnded() {
        strafeRecognizerActive = false
        lastStrafeTranslation = .zero
        strafeBaselinePending = false
        finishTwoFingerIfIdle()
    }

    // MARK: Pinch (two touches)

    mutating func pinchBegan(scale: CGFloat, touchCount: Int) {
        guard touchCount == 2 else { return }
        cancelLook()
        pinchRecognizerActive = true
        lastPinchScale = scale
        twoFingerOriginScale = scale
        pinchBaselinePending = true
        enterTwoFingerIfNeeded()
    }

    mutating func pinchChanged(scale: CGFloat, touchCount: Int) {
        guard touchCount == 2 else { return }
        guard mode != .look else { return }

        if pinchBaselinePending {
            lastPinchScale = scale
            twoFingerOriginScale = scale
            pinchBaselinePending = false
            return
        }

        if mode == .strafe {
            lastPinchScale = scale
            return
        }

        if mode == .idle {
            enterTwoFingerIfNeeded()
        }

        if mode == .twoFingerUndecided {
            lastPinchScale = scale
            lockTwoFingerIfReady(translation: lastStrafeTranslation, scale: scale)
            return
        }

        guard mode == .pinch else { return }
        camera.applyDolly(scale: Float(scale), previousScale: Float(lastPinchScale))
        lastPinchScale = scale
    }

    mutating func pinchEnded() {
        pinchRecognizerActive = false
        lastPinchScale = 1
        pinchBaselinePending = false
        finishTwoFingerIfIdle()
    }

    // MARK: Two-finger lock

    private mutating func enterTwoFingerIfNeeded() {
        switch mode {
        case .idle, .look:
            mode = .twoFingerUndecided
        case .twoFingerUndecided, .strafe, .pinch:
            break
        }
    }

    private mutating func lockTwoFingerIfReady(translation: CGSize, scale: CGFloat) {
        let translationMagnitude = hypot(
            translation.width - twoFingerOriginTranslation.width,
            translation.height - twoFingerOriginTranslation.height
        )
        let scaleDelta = abs(scale - twoFingerOriginScale)
        let translationScore = strafeRecognizerActive
            ? translationMagnitude / Self.strafeTranslationDominance
            : 0
        let scaleScore = pinchRecognizerActive
            ? scaleDelta / Self.pinchScaleDominance
            : 0
        guard translationScore >= 1 || scaleScore >= 1 else { return }

        if scaleScore > translationScore {
            mode = .pinch
            lastPinchScale = scale
        } else {
            mode = .strafe
            lastStrafeTranslation = translation
        }
    }

    private mutating func finishTwoFingerIfIdle() {
        guard !strafeRecognizerActive, !pinchRecognizerActive else { return }
        switch mode {
        case .strafe, .pinch, .twoFingerUndecided:
            mode = .idle
        case .idle, .look:
            break
        }
    }
}
