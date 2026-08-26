import Combine
import Foundation
import RealityKit

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

    @MainActor
    static func entity(from url: URL) async throws -> Entity {
        if #available(iOS 18.0, *) {
            return try await Entity(contentsOf: url)
        }
        return try await entityUsingLoadAsync(from: url)
    }

    @MainActor
    private static func entityUsingLoadAsync(from url: URL) async throws -> Entity {
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
                        if case .failure(let error) = completion {
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
