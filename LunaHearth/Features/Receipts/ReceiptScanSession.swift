import Foundation
import Observation

/// A bounded UI session, including photo-library downloads. Late work cannot replace a newer review.
@MainActor @Observable
final class ReceiptScanSession {
    private(set) var isReading = false
    private var generation = UUID()
    private var work: Task<Void, Never>?
    private var watchdog: Task<Void, Never>?

    func start(
        timeout: Duration = .seconds(60),
        operation: @escaping @MainActor () async throws -> ReceiptScan,
        completed: @escaping @MainActor (ReceiptScan) -> Void,
        failed: @escaping @MainActor (String) -> Void
    ) {
        cancel()
        let current = generation
        isReading = true
        work = Task { [weak self] in
            do {
                try Task.checkCancellation()
                let result = try await operation()
                try Task.checkCancellation()
                guard let self, self.generation == current else { return }
                self.finish()
                completed(result)
            } catch {
                guard let self, self.generation == current else { return }
                self.finish()
                if !(error is CancellationError) { failed((error as? ReceiptImportError)?.errorDescription ?? "Couldn’t read this receipt. Try one clear photo with the whole page visible. If it is stored in iCloud, download it in Photos first.") }
            }
        }
        watchdog = Task { [weak self] in
            do { try await Task.sleep(for: timeout) } catch { return }
            guard let self, self.generation == current else { return }
            self.cancel()
            failed("Reading took too long. If the photo is in iCloud, download it in Photos first. Then retry with one clear page, or enter the receipt manually.")
        }
    }

    func cancel() {
        generation = UUID()
        work?.cancel()
        watchdog?.cancel()
        work = nil
        watchdog = nil
        isReading = false
    }

    private func finish() {
        generation = UUID()
        watchdog?.cancel()
        watchdog = nil
        work = nil
        isReading = false
    }
}
