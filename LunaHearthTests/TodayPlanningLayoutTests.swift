import Testing
@testable import LunaHearth

struct TodayPlanningLayoutTests {
    @Test func planningRequiresRoomForBothPanels() {
        #expect(!TodayPlanningLayout.isExpanded(width: 390, accessibilityText: false))
        #expect(!TodayPlanningLayout.isExpanded(width: 849, accessibilityText: false))
        #expect(TodayPlanningLayout.isExpanded(width: 850, accessibilityText: false))
        #expect(TodayPlanningLayout.isExpanded(width: 1200, accessibilityText: false))
    }
    @Test func accessibilityAndInvalidSizesStayStacked() {
        #expect(!TodayPlanningLayout.isExpanded(width: 1400, accessibilityText: true))
        #expect(!TodayPlanningLayout.isExpanded(width: .infinity, accessibilityText: false))
        #expect(!TodayPlanningLayout.isExpanded(width: .nan, accessibilityText: false))
        #expect(!TodayPlanningLayout.isExpanded(width: -1, accessibilityText: false))
    }
}
