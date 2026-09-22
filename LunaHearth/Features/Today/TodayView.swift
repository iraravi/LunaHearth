import SwiftUI

struct TodayView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(PersonalShopping.self) private var personal
    @Environment(\.dynamicTypeSize) private var typeSize
    @AppStorage("warranty.horizon") private var warrantyHorizon = 30
    @State private var adding = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                TimelineView(.periodic(from: .now, by: 60)) { timeline in
                    dashboard(at: timeline.date, wide: geometry.size.width >= 850 && !typeSize.isAccessibilitySize)
                }
            }
            .background(TodayTheme.canvas).foregroundStyle(TodayTheme.ink).tint(TodayTheme.accent)
            .navigationTitle("Today").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Quick Add", systemImage: "plus") { adding = true }
                        .accessibilityIdentifier("today.quickAdd")
                }
            }
            .sheet(isPresented: $adding) { QuickAddView(kind: .task) }
        }
    }

    private func dashboard(at now: Date, wide: Bool) -> some View {
        let events = repository.events(on: now)
        let dueTasks = repository.dueTasks(on: now)
        let plans = repository.maintenance.filter {
            guard let due = $0.nextDueAt, let horizon = Calendar.current.date(byAdding: .day, value: 7, to: now) else { return false }
            return due <= horizon
        }.sorted { ($0.nextDueAt ?? .distantFuture) < ($1.nextDueAt ?? .distantFuture) }
        let warranties = repository.warranties.filter {
            guard let end = $0.endDate, let horizon = Calendar.current.date(byAdding: .day, value: warrantyHorizon, to: now) else { return false }
            return end >= Calendar.current.startOfDay(for: now) && end <= horizon
        }.sorted { ($0.endDate ?? .distantFuture) < ($1.endDate ?? .distantFuture) }
        let attention = TodayAttentionData(repository: repository, personal: personal, now: now)
        let day = HouseholdDay(now).key
        let facts = TodayBriefFacts(shoppingNeededNow: attention.shopping.count,
                                   shoppingOverdue: attention.shopping.filter { TodayAttentionRules.isOverdue($0, today: day) }.count,
                                   pantryDatesToCheck: attention.dates.count,
                                   pantryPastExpiry: attention.dates.filter { InventoryRules.expiryState($0.expiryDay, today: day) == .past }.count,
                                   lowStockIngredients: attention.restock.count, eventsToday: events.count,
                                   remindersDue: dueTasks.count, homeCareAlerts: plans.count + warranties.count)
        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TodayHero(now: now, household: repository.household?.name ?? "Your home", wide: wide)
                TodayPriorities(now: now, wide: wide)
                TodayBriefCard(facts: facts)
                    .id("\(repository.household?.id.uuidString ?? "none")|\(repository.household.flatMap { personal.memberID($0.id) }?.uuidString ?? "all")|\(day)")
                Text("Your household today").font(.title3.bold()).padding(.top, 4)
                TodayAlignedCards(columns: wide ? 2 : 1) {
                    TodayCard {
                        TodayIllustratedHeading(title: "Schedule", detail: "\(events.count) events today", art: "EditorialPlanning")
                        if events.isEmpty { quiet("No events saved for today.") }
                        ForEach(events.prefix(3)) { event in
                            NavigationLink { EventDetailView(event: event) } label: { EventRow(event: event) }.buttonStyle(.plain)
                        }
                        Spacer(minLength: 0)
                        NavigationLink { CalendarAgendaView() } label: { link("Open calendar") }
                    }
                    TodayCard {
                        TodayIllustratedHeading(title: "Reminders", detail: "\(dueTasks.count) need attention", art: "EditorialPlanning")
                        if dueTasks.isEmpty { quiet("No reminders due or overdue.") }
                        ForEach(dueTasks.prefix(3)) { TaskRow(task: $0) }
                        Spacer(minLength: 0)
                        NavigationLink { PlanningListView(kind: .task) } label: { link("All reminders & chores") }
                    }
                    TodayCard {
                        TodayIllustratedHeading(title: "Home care", detail: "\(plans.count + warranties.count) upcoming alerts", art: "WelcomeResidence")
                        if plans.isEmpty && warranties.isEmpty { quiet("No upcoming maintenance or warranty alerts.") }
                        ForEach(plans.prefix(3)) { plan in
                            NavigationLink { MaintenanceDetailView(plan: plan) } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(plan.title).font(.subheadline.weight(.semibold))
                                    if let due = plan.nextDueAt {
                                        Text("\(repository.assetName(plan.assetID)) · Due \(due.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.caption).foregroundStyle(TodayTheme.muted)
                                    }
                                }.frame(maxWidth: .infinity, alignment: .leading)
                            }.buttonStyle(.plain)
                        }
                        ForEach(warranties.prefix(2)) { warranty in
                            VStack(alignment: .leading, spacing: 5) {
                                Label(repository.assetName(warranty.assetID), systemImage: "clock.badge.exclamationmark").font(.subheadline.weight(.medium))
                                if let end = warranty.endDate { Text("Warranty ends \(end.formatted(date: .abbreviated, time: .omitted))").font(.caption).foregroundStyle(TodayTheme.muted) }
                            }
                        }
                        Spacer(minLength: 0)
                        NavigationLink { HomeAlertsView() } label: { link("See home care") }
                    }
                    TodayCard {
                        TodayIllustratedHeading(title: "At the table", detail: "Meals & preparation", art: "WelcomeTable")
                        if repository.meals(on: now).isEmpty { quiet("A little space for your next meal plan.") }
                        ForEach(repository.meals(on: now).prefix(3)) { meal in
                            NavigationLink { MealCookingView(meal: meal) } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(meal.cookedAt == nil ? meal.mealType : "Cooked").font(.caption.weight(.medium)).foregroundStyle(TodayTheme.muted)
                                    Text(meal.title).font(.subheadline.weight(.semibold))
                                    if let prep = repository.tasks.filter({ $0.mealID == meal.id && !$0.isCompleted }).sorted(by: { ($0.dueAt ?? .distantFuture) < ($1.dueAt ?? .distantFuture) }).first { Text("Next: \(prep.title)").font(.caption) }
                                }
                            }
                        }
                        if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) {
                            let tomorrowMeals = repository.meals(on: tomorrow).filter { $0.cookedAt == nil }
                            let prepTasks = repository.tasks.filter { task in !task.isCompleted && tomorrowMeals.contains { $0.id == task.mealID } }
                            if !prepTasks.isEmpty { Text("Prep for tomorrow").font(.subheadline.weight(.semibold)) }
                            ForEach(prepTasks.prefix(3)) { task in
                                if let meal = tomorrowMeals.first(where: { $0.id == task.mealID }) {
                                    NavigationLink { MealCookingView(meal: meal) } label: {
                                        Label(task.title, systemImage: "bell").font(.subheadline).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).contentShape(Rectangle())
                                    }
                                }
                            }
                        }
                        Spacer(minLength: 0)
                        NavigationLink { FamilyWeekView() } label: { link("Family week") }
                        NavigationLink { MealIdeasView() } label: { link("Get meal ideas") }
                    }
                }
            }.padding(20).frame(maxWidth: wide ? 1120 : 700).frame(maxWidth: .infinity)
                .padding(.bottom, 12)
        }.id(repository.household?.id)
    }

    private func quiet(_ text: String) -> some View {
        Text(text).font(.subheadline).foregroundStyle(TodayTheme.muted).fixedSize(horizontal: false, vertical: true)
    }
    private func link(_ title: String) -> some View {
        HStack { Text(title).multilineTextAlignment(.leading); Spacer(); Image(systemName: "arrow.right").accessibilityHidden(true) }
            .font(.subheadline.weight(.semibold)).foregroundStyle(TodayTheme.accent).frame(minHeight: 44).contentShape(Rectangle())
    }
}
