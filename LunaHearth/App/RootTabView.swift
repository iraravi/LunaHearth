import SwiftUI

enum RootTab: Hashable {
    case today, calendar, home, more
}

struct RootTabView: View {
    @State private var canvas = FeatureCanvasCoordinator()
    @State private var selection: RootTab

    init(initialTab: RootTab = .today) { _selection = State(initialValue: initialTab) }

    var body: some View {
        TabView(selection: $selection) {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(RootTab.today)

            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(RootTab.calendar)

            HomeView()
                .environment(\.featureCanvasScope, .home)
                .tabItem { Label("Home", systemImage: "house") }
                .tag(RootTab.home)

            MoreView()
                .tabItem { Label("More", systemImage: "ellipsis.circle") }
                .tag(RootTab.more)
        }
        .tint(AppTheme.accent)
        .hearthNavigationMaterial(AppTheme.canvas, for: .tabBar)
        .environment(\.featureCanvasCoordinator, canvas)
        .background((selection == .home ? canvas.color(for: .home) : AppTheme.canvas).ignoresSafeArea())
    }
}
