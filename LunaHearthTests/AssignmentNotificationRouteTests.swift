import Foundation
import Testing
@testable import LunaHearth

struct AssignmentNotificationRouteTests {
    @Test func assignmentsKeepTheirKindAndHome() throws {
        let home = UUID()
        for focus in [AssignmentFocus.shopping, .tasks] {
            let route = try #require(AssignmentNotificationRoute(identifier: "\(focus.rawValue).personal.\(home).notification"))
            #expect(route.focus == focus)
            #expect(route.householdID == home)
        }
    }
    @Test func unrelatedMalformedAndExtraPartsAreRejected() {
        for value in ["shopping.personal.bad.notification", "appointment.\(UUID())", "tasks.personal.\(UUID()).notification.extra", "shopping.other.\(UUID()).notification", "tasks.personal.\(UUID()).notice", ""] {
            #expect(AssignmentNotificationRoute(identifier: value) == nil)
        }
    }
}
