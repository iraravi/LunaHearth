import Testing
@testable import LunaHearth

struct V2FeatureAvailabilityTests {
    @Test func quickAddOffersOnlyReachableWorkflows() {
        #expect(EntryKind.availableForQuickAdd == [.event, .task, .grocery, .meal])
        // Hiding presentation must not remove the kinds used by existing records.
        #expect(EntryKind.allCases.contains(.room))
        #expect(EntryKind.allCases.contains(.floor))
        #expect(EntryKind.allCases.contains(.warranty))
        #expect(EntryKind.allCases.contains(.maintenance))
    }
    @Test func todayHasNoHomeCareDestination() {
        #expect(TodayWorkspaceSection.allCases.map(\.rawValue) == ["day", "shopping", "meals"])
    }
}
