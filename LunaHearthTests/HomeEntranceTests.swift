import Testing
@testable import LunaHearth

struct HomeEntranceTests {
    @Test func phoneHasAnExplicitDoorControl() {
        var entrance = HomeEntranceState()
        entrance.observe(.unavailable)
        #expect(!entrance.isOpen)
        entrance.toggleManually()
        #expect(entrance.isOpen)
        entrance.toggleManually()
        #expect(!entrance.isOpen)
    }
    @Test func physicalDoorSurvivesTransientDisplayHandoff() {
        var entrance = HomeEntranceState()
        entrance.observe(.fullyOpen)
        entrance.observe(.unavailable)
        entrance.observe(.unknown)
        #expect(entrance.isOpen)
        #expect(entrance.followsHinge)
        entrance.observe(.closed)
        entrance.toggleManually()
        #expect(!entrance.isOpen)
        entrance.observe(.partiallyOpen)
        #expect(entrance.isOpen)
    }
}
