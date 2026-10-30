import Foundation
import Testing
@testable import LunaHearth

@MainActor struct ReceiptScanSessionTests {
    @MainActor private final class PendingScan {
        var continuation: CheckedContinuation<ReceiptScan, Never>?
        func read() async -> ReceiptScan {
            await withCheckedContinuation { continuation = $0 }
        }
        func complete(_ text: String) {
            continuation?.resume(returning: ReceiptRules.scan(text: text))
            continuation = nil
        }
    }

    private func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0..<1_000 {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(1))
        }
        Issue.record("Receipt session did not reach its expected state")
    }

    @Test func successAndFailureReleaseControls() async throws {
        let session = ReceiptScanSession()
        var text = ""
        var message = ""
        session.start(operation: { ReceiptRules.scan(text: "Milk 2.00") },
                      completed: { text = $0.text }, failed: { message = $0 })
        try await waitUntil { !session.isReading }
        #expect(text == "Milk 2.00")
        #expect(message.isEmpty)
        session.start(operation: { throw ReceiptImportError.unreadable },
                      completed: { _ in Issue.record("Unexpected success") }, failed: { message = $0 })
        try await waitUntil { !session.isReading }
        #expect(message == ReceiptImportError.unreadable.errorDescription)
    }

    @Test func immediatelyCancelledScanDoesNotStartProvider() async throws {
        let session = ReceiptScanSession()
        var started = false
        session.start(operation: { started = true; return ReceiptRules.scan(text: "Milk 2.00") },
                      completed: { _ in Issue.record("Cancelled result") }, failed: { _ in Issue.record("Cancelled error") })
        session.cancel()
        try await Task.sleep(for: .milliseconds(20))
        #expect(!started)
        #expect(!session.isReading)
    }

    @Test func staleFailureCannotInterruptNewScan() async throws {
        let session = ReceiptScanSession()
        let first = PendingScan()
        let second = PendingScan()
        var failures = 0
        session.start(operation: {
            _ = await first.read()
            throw ReceiptImportError.unreadable
        }, completed: { _ in }, failed: { _ in failures += 1 })
        try await waitUntil { first.continuation != nil }
        session.start(operation: { await second.read() }, completed: { _ in }, failed: { _ in failures += 1 })
        try await waitUntil { second.continuation != nil }
        first.complete("Old result")
        try await Task.sleep(for: .milliseconds(20))
        #expect(session.isReading)
        #expect(failures == 0)
        second.complete("Milk 2.00")
        try await waitUntil { !session.isReading }
    }

    @Test func completedScanNeverReportsTimeout() async throws {
        let session = ReceiptScanSession()
        var successes = 0
        var failures = 0
        session.start(timeout: .milliseconds(40), operation: { ReceiptRules.scan(text: "Milk 2.00") },
                      completed: { _ in successes += 1 }, failed: { _ in failures += 1 })
        try await waitUntil { !session.isReading }
        try await Task.sleep(for: .milliseconds(80))
        #expect(successes == 1)
        #expect(failures == 0)
    }

    @Test func cancellationDiscardsUncooperativeWork() async throws {
        let session = ReceiptScanSession()
        let pending = PendingScan()
        var completed = false
        session.start(operation: { await pending.read() },
                      completed: { _ in completed = true }, failed: { _ in Issue.record("Cancellation is not an error") })
        try await waitUntil { pending.continuation != nil }
        session.cancel()
        #expect(!session.isReading)
        pending.complete("Old milk 2.00")
        try await Task.sleep(for: .milliseconds(10))
        #expect(!completed)
    }

    @Test func timeoutReleasesControlsWithoutWaitingForUnderlyingWork() async throws {
        let session = ReceiptScanSession()
        let pending = PendingScan()
        var message = ""
        session.start(timeout: .milliseconds(50), operation: { await pending.read() },
                      completed: { _ in Issue.record("Timed-out result must be discarded") }, failed: { message = $0 })
        try await waitUntil { pending.continuation != nil }
        try await waitUntil { !session.isReading }
        #expect(message.contains("too long"))
        pending.complete("Late milk 2.00")
    }

    @Test func previousScanCannotOverwriteRetry() async throws {
        let session = ReceiptScanSession()
        let first = PendingScan()
        let second = PendingScan()
        var results: [String] = []
        session.start(operation: { await first.read() }, completed: { results.append($0.text) }, failed: { _ in })
        try await waitUntil { first.continuation != nil }
        session.start(operation: { await second.read() }, completed: { results.append($0.text) }, failed: { _ in })
        try await waitUntil { second.continuation != nil }
        first.complete("Old 1.00")
        try await Task.sleep(for: .milliseconds(10))
        #expect(session.isReading)
        #expect(results.isEmpty)
        second.complete("New 2.00")
        try await waitUntil { !session.isReading }
        #expect(results == ["New 2.00"])
    }
}
