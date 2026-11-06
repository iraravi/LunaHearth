import SwiftUI

enum TodayWorkspaceSection: String, CaseIterable, Identifiable {
    case day, shopping, home, meals
    var id: String { rawValue }
    var label: String {
        switch self { case .day: "Today"; case .shopping: "Shopping"; case .home: "Home care"; case .meals: "Meals" }
    }
    var title: String {
        switch self { case .day: "Your day"; case .shopping: "Keep things stocked"; case .home: "A well-kept home"; case .meals: "At the table" }
    }
    var subtitle: String {
        switch self {
        case .day: "Your schedule and what needs doing."
        case .shopping: "Buy what you need. Use what you have."
        case .home: "Maintenance and warranties, together."
        case .meals: "Today’s meals and tomorrow’s preparation."
        }
    }
    var symbol: String {
        switch self { case .day: "sun.max"; case .shopping: "basket"; case .home: "house"; case .meals: "fork.knife" }
    }
}

/// Decorative artwork, not a representation of the household’s saved rooms.
struct TodayResidence: View {
    var body: some View {
        Image("TodayResidenceV2")
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }
}
