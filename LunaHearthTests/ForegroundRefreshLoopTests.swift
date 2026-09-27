import Foundation
import Testing
@testable import LunaHearth

struct ForegroundRefreshLoopTests {
    @MainActor @Test func periodicRefreshWaitsFirstAndStopsOnCancellation() async {
        var events: [String] = []
        var waits = 0
        await ForegroundRefreshLoop.run(wait: {
            waits += 1
            events.append("wait")
            if waits == 2 { throw CancellationError() }
        }, refresh: { events.append("refresh") })
        #expect(events == ["wait", "refresh", "wait"])
    }

    @MainActor @Test func interruptedInitialWaitDoesNotRefresh() async {
        var refreshed = false
        await ForegroundRefreshLoop.run(wait: { throw CancellationError() }, refresh: { refreshed = true })
        #expect(!refreshed)
    }
}
