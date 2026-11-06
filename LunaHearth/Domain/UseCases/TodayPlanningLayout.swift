import Foundation

/// Space-based planning only. Width is not evidence of a physical hinge posture.
enum TodayPlanningLayout {
    static func isExpanded(width: Double, accessibilityText: Bool) -> Bool {
        width.isFinite && width >= 720 && !accessibilityText
    }
}
