import Testing
@testable import LunaHearth

struct HomeWorkspaceLayoutTests {
    @Test func workspaceNeedsEnoughRoomForBothPanes() {
        #expect(!HomeWorkspaceLayout.isExpanded(width: 466, accessibilityText: false))
        #expect(!HomeWorkspaceLayout.isExpanded(width: 649, accessibilityText: false))
        #expect(HomeWorkspaceLayout.isExpanded(width: 650, accessibilityText: false))
        #expect(HomeWorkspaceLayout.isExpanded(width: 1000, accessibilityText: false))
    }
    @Test func accessibilityAndInvalidGeometryUseCompactContent() {
        #expect(!HomeWorkspaceLayout.isExpanded(width: 1000, accessibilityText: true))
        #expect(!HomeWorkspaceLayout.isExpanded(width: .nan, accessibilityText: false))
        #expect(!HomeWorkspaceLayout.isExpanded(width: .infinity, accessibilityText: false))
        #expect(!HomeWorkspaceLayout.isExpanded(width: -1, accessibilityText: false))
    }
}
