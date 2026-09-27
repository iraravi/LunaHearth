import Foundation

/// The caller performs the initial refresh. Periodic work always waits first and
/// stops when SwiftUI cancels the scene task on backgrounding or home changes.
@MainActor enum ForegroundRefreshLoop {
    static func run(
        wait: () async throws -> Void = { try await Task.sleep(for: .seconds(20)) },
        refresh: () async -> Void
    ) async {
        while !Task.isCancelled {
            do { try await wait() } catch { return }
            guard !Task.isCancelled else { return }
            await refresh()
        }
    }
}
