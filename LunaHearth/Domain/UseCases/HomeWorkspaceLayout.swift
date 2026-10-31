import Foundation

/// Available workspace width, not device identity or inferred hinge posture.
enum HomeWorkspaceLayout {
    static func isExpanded(width: Double, accessibilityText: Bool) -> Bool {
        width.isFinite && width >= 650 && !accessibilityText
    }
}
