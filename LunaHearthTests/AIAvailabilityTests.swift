import Foundation
import Testing
@testable import LunaHearth

struct AIAvailabilityTests {
    @Test(arguments: AIAvailability.allCases)
    func onlyReadyModelExposesAIActions(_ availability: AIAvailability) {
        #expect(availability.showsAIActions == (availability == .ready))
        #expect(availability.filterTitle == (availability == .ready ? "Filters & AI" : "Filters"))
    }

    @Test(arguments: AIAvailability.allCases)
    func imageCapabilityAlsoRequiresReadyModel(_ availability: AIAvailability) {
        for supportsImages in [false, true] {
            let snapshot = AIStatusSnapshot(device: "Test", hardware: "Test", system: "Test",
                                            availability: availability, supportsImageInput: supportsImages, checkedAt: .now)
            #expect(snapshot.imageAIReady == (availability == .ready && supportsImages))
        }
    }
}
