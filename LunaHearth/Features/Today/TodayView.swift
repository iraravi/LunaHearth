import SwiftUI

struct TodayView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.horizontalSizeClass) private var sizeClass
    @AppStorage("warranty.horizon") private var warrantyHorizon = 30
    @State private var adding = false
    @State private var addKind: EntryKind = .task

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 60)) { timeline in
                dashboard(at: timeline.date)
            }
            .background(AppTheme.canvas)
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Label(repository.household?.name ?? "Your household", systemImage: "house.fill")
                        .font(.caption.weight(.medium)).foregroundStyle(AppTheme.accent)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Quick Add", systemImage: "plus") { addKind = .task; adding = true }.accessibilityIdentifier("today.quickAdd")
                }
            }
            .sheet(isPresented: $adding) { QuickAddView(kind: addKind) }
        }
    }

    private func dashboard(at now: Date) -> some View {
        let events = repository.events(on: now)
        let tasks = repository.dueTasks(on: now)
        let plans = repository.maintenance.filter {
            guard let due = $0.nextDueAt, let horizon = Calendar.current.date(byAdding: .day, value: 7, to: now) else { return false }
            return due <= horizon
        }
        let warranties = repository.warranties.filter {
            guard let end = $0.endDate, let horizon = Calendar.current.date(byAdding: .day, value: warrantyHorizon, to: now) else { return false }
            return end >= Calendar.current.startOfDay(for: now) && end <= horizon
        }
        let columns = Array(repeating: GridItem(.flexible(), alignment: .top), count: sizeClass == .regular ? 2 : 1)
        return ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ScreenIntro(eyebrow: now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()),
                            title: "Your day, at a glance.",
                            subtitle: "Plans, priorities, and everything at home.")
                Button {
                    addKind = .task
                    adding = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill").font(.title2).dynamicTypeSize(.large).accessibilityHidden(true)
                        Text("Quick Add").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                        Spacer(minLength: 4)
                        Image(systemName: "arrow.right").dynamicTypeSize(.large).accessibilityHidden(true)
                    }.foregroundStyle(AppTheme.canvas).padding(18)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(AppTheme.ink, in: RoundedRectangle(cornerRadius: 14))
                }.buttonStyle(.plain).accessibilityIdentifier("today.primaryAdd")
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) { metrics(events: events.count, tasks: tasks.count) }
                    VStack(spacing: 10) { metrics(events: events.count, tasks: tasks.count) }
                }
                LazyVGrid(columns: columns, alignment: .leading, spacing: 20) {
                    DashboardCard("Your schedule", symbol: "calendar", detail: "Family events") {
                        if events.isEmpty {
                            GentleEmptyState(title: "No events today", message: "Add an event to keep your household up to date.", symbol: "sun.horizon")
                        }
                        ForEach(events.prefix(3)) { event in
                            NavigationLink { EventDetailView(event: event) } label: { EventRow(event: event) }
                                .buttonStyle(.plain)
                        }
                        Divider()
                        NavigationLink { CalendarAgendaView() } label: { SectionLink(title: "Open calendar") }
                    }
                    DashboardCard("Tasks & chores", symbol: "checklist", detail: "Due & overdue tasks") {
                        if tasks.isEmpty {
                            GentleEmptyState(title: "Nothing due today", message: "View your tasks or add something new.", symbol: "checkmark.circle")
                        }
                        ForEach(tasks.prefix(5)) { TaskRow(task: $0) }
                        Divider()
                        NavigationLink { PlanningListView(kind: .task) } label: { SectionLink(title: "All tasks & chores") }
                    }
                    DashboardCard("Home care", symbol: "house", detail: "Maintenance & warranties") {
                        HearthArtwork(name: "HearthHome", height: 110)
                        if plans.isEmpty && warranties.isEmpty {
                            GentleEmptyState(title: "No upcoming home alerts", message: "Track maintenance and warranty dates for your belongings.", symbol: "house")
                        }
                        ForEach(plans.prefix(3)) { plan in
                            NavigationLink { MaintenanceDetailView(plan: plan) } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    Label(plan.title, systemImage: "wrench.and.screwdriver").font(.subheadline.weight(.medium))
                                    if let due = plan.nextDueAt { Text("\(repository.assetName(plan.assetID)) · Due \(due.formatted(date: .abbreviated, time: .omitted))").font(.caption).foregroundStyle(AppTheme.muted) }
                                }.frame(maxWidth: .infinity, alignment: .leading)
                            }.buttonStyle(.plain)
                        }
                        ForEach(warranties.prefix(3)) { warranty in
                            VStack(alignment: .leading, spacing: 5) {
                                Label(repository.assetName(warranty.assetID), systemImage: "exclamationmark.triangle").font(.subheadline.weight(.medium))
                                if let end = warranty.endDate { Text("Warranty ends \(end.formatted(date: .abbreviated, time: .omitted))").font(.caption).foregroundStyle(AppTheme.muted) }
                            }
                        }
                        Divider()
                        NavigationLink { HomeAlertsView() } label: { SectionLink(title: "See home care") }
                    }
                    DashboardCard("Meals & shopping", symbol: "fork.knife", detail: "Meals & shopping") {
                        HearthArtwork(name: "HearthTable", height: 120)
                        ForEach(repository.meals(on: now)) { meal in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(meal.mealType.uppercased()).font(.caption.weight(.semibold)).foregroundStyle(AppTheme.accent)
                                Text(meal.title).font(.headline)
                            }
                        }
                        if repository.meals(on: now).isEmpty {
                            NavigationLink { PlanningListView(kind: .meal) } label: { SectionLink(title: "Plan a meal") }
                        }
                        NavigationLink { PlanningListView(kind: .grocery) } label: {
                            SectionLink(title: "Shopping · \(repository.groceries.filter { !$0.isCompleted }.count) open items")
                        }
                    }
                }
                Label("Stored on this device", systemImage: "internaldrive")
                    .font(.caption).foregroundStyle(AppTheme.muted)
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
            }
            .padding(20).frame(maxWidth: 1000).frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder private func metrics(events: Int, tasks: Int) -> some View {
        SummaryMetric(count: events, title: "Events today", symbol: "calendar")
        SummaryMetric(count: tasks, title: "Tasks due", symbol: "checklist")
        SummaryMetric(count: repository.groceries.filter { !$0.isCompleted }.count, title: "To pick up", symbol: "basket")
    }
}
