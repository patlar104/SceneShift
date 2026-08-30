import RoomPlan
import SwiftUI

/// Wraps `RoomCaptureView` and reports processed results via `RoomCaptureViewDelegate`.
/// Coaching uses `RoomCaptureSession.Configuration.isCoachingEnabled` (default `true`);
/// do not add custom lighting or movement copy.
struct RoomCaptureRepresentable: UIViewRepresentable {
    var isScanning: Bool
    var sessionGeneration: Int
    var onComplete: (Result<CapturedRoom, Error>) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    func makeUIView(context: Context) -> RoomCaptureView {
        let captureView = RoomCaptureView(frame: .zero)
        captureView.delegate = context.coordinator
        return captureView
    }

    func updateUIView(_ uiView: RoomCaptureView, context: Context) {
        context.coordinator.onComplete = onComplete

        if context.coordinator.sessionGeneration != sessionGeneration {
            if context.coordinator.isRunning {
                uiView.captureSession.stop()
            }
            context.coordinator.sessionGeneration = sessionGeneration
            context.coordinator.didComplete = false
            context.coordinator.isRunning = false
            context.coordinator.hasStopped = false
        }

        if isScanning && !context.coordinator.isRunning {
            // Built-in coaching stays on (`isCoachingEnabled` defaults to true).
            uiView.captureSession.run(configuration: RoomCaptureSession.Configuration())
            context.coordinator.isRunning = true
            context.coordinator.hasStopped = false
        } else if !isScanning && context.coordinator.isRunning && !context.coordinator.hasStopped {
            uiView.captureSession.stop()
            context.coordinator.isRunning = false
            context.coordinator.hasStopped = true
        }
    }

    static func dismantleUIView(_ uiView: RoomCaptureView, coordinator: Coordinator) {
        if coordinator.isRunning {
            uiView.captureSession.stop()
            coordinator.isRunning = false
        }
        uiView.delegate = nil
    }

    @MainActor
    @objc(SceneShiftRoomCaptureCoordinator)
    final class Coordinator: NSObject, RoomCaptureViewDelegate {
        var onComplete: (Result<CapturedRoom, Error>) -> Void
        var isRunning = false
        var hasStopped = false
        var didComplete = false
        var sessionGeneration = -1

        init(onComplete: @escaping (Result<CapturedRoom, Error>) -> Void) {
            self.onComplete = onComplete
            super.init()
        }

        required init?(coder: NSCoder) {
            return nil
        }

        func encode(with coder: NSCoder) {}

        func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
            true
        }

        func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
            let generation = sessionGeneration
            let result: Result<CapturedRoom, Error> = {
                if let error {
                    return .failure(error)
                }
                return .success(processedResult)
            }()
            DispatchQueue.main.async { [weak self] in
                guard let self, generation == self.sessionGeneration, !self.didComplete else { return }
                self.didComplete = true
                self.onComplete(result)
            }
        }
    }
}
