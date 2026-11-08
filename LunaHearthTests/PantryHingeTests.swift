import Testing
@testable import LunaHearth

struct PantryHingeTests {
    @Test func physicalStatesDriveInterior() {
        #expect(PantryHingeState.closed.interiorVisible == false)
        #expect(PantryHingeState.partiallyOpen.interiorVisible == true)
        #expect(PantryHingeState.fullyOpen.interiorVisible == true)
    }
    @Test func missingOrUnknownUpdatesDoNotInventPosture() {
        #expect(PantryHingeState.unavailable.interiorVisible == nil)
        #expect(PantryHingeState.unknown.interiorVisible == nil)
        #expect(!PantryHingeState.unavailable.supportsVirtualPantry)
        #expect(PantryHingeState.closed.supportsVirtualPantry)
    }
}
