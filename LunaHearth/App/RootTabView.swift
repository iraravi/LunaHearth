import SwiftUI

enum RootTab: Hashable {
    case today, calendar, home, lists, more
}

struct RootTabView: View {
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
                .tabItem { Label("Home", systemImage: "house") }
                .tag(RootTab.home)

            ListsView()
                .tabItem { Label("Lists", systemImage: "checklist") }
                .tag(RootTab.lists)

            MoreView()
                .tabItem { Label("More", systemImage: "ellipsis.circle") }
                .tag(RootTab.more)
        }
    }
}
