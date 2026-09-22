import Foundation
import Testing
@testable import LunaHearth
struct AIStatusTests {
    @Test func imageCapabilityRequiresReadyModel() {
        for state in AIAvailability.allCases {
            let status = AIStatusSnapshot(device: "iPhone", hardware: "test", system: "iOS 27", availability: state, supportsImageInput: true, checkedAt: .now)
            #expect(status.imageAIReady == (state == .ready))
        }
    }
    @Test func textOnlyModelUsesLabelFallback() {
        let status = AIStatusSnapshot(device: "iPhone", hardware: "test", system: "iOS 26", availability: .ready, supportsImageInput: false, checkedAt: .now)
        #expect(!status.imageAIReady)
        #expect(status.pantryMode == "Product-label reading")
    }
}
