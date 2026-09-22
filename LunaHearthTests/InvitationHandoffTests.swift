import Foundation
import Testing
@testable import LunaHearth

@MainActor struct InvitationHandoffTests {
    @Test func browserActivityRetainsInvitationUntilTheViewCanHandleIt() throws {
        let delegate = SharingAppDelegate()
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        let url = try #require(URL(string: "https://www.icloud.com/share/test-invitation"))
        activity.webpageURL = url
        #expect(delegate.receiveActivity(activity))
        #expect(delegate.invitationURL == url)
        // Consume, then open the same link again: retries must remain possible.
        delegate.invitationURL = nil
        #expect(delegate.receiveActivity(activity))
        #expect(delegate.invitationURL == url)
    }
    @Test func unrelatedLinksAndActivitiesNeverBecomeAnInvitation() throws {
        let delegate = SharingAppDelegate()
        let activity = NSUserActivity(activityType: "unrelated.activity")
        activity.webpageURL = try #require(URL(string: "https://www.icloud.com/share/test"))
        #expect(!delegate.receiveActivity(activity))
        #expect(!delegate.receiveInvitationURL(try #require(URL(string: "https://example.com/share/test"))))
        #expect(delegate.invitationURL == nil)
    }
}
