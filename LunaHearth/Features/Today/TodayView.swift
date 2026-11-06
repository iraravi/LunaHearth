import SwiftUI

struct TodayView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(PersonalShopping.self) private var personal
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var section: TodayWorkspaceSection = .day
    @State private var priority: TodayPriority = .buy
    @AppStorage("warranty.horizon") private var warrantyHorizon = 30
    @State private var adding = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                TimelineView(.periodic(from: .now, by: 60)) { timeline in
                    dashboard(at: timeline.date, wide: TodayPlanningLayout.isExpanded(width: geometry.size.width, accessibilityText: typeSize.isAccessibilitySize), height: geometry.size.height)
                }
            }
            .background(TodayTheme.canvas).foregroundStyle(TodayTheme.ink).tint(TodayTheme.accent)
            .householdHelp(.today)
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

    private func dashboard(at now: Date, wide: Bool, height: CGFloat) -> some View {
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
            (wide ? AnyLayout(HStackLayout(alignment: .top, spacing: 28)) : AnyLayout(VStackLayout(alignment: .leading, spacing: 24))) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        TodayHero(now: now, household: repository.household?.name ?? "Your home", wide: wide)
                        if wide { sectionPicker(vertical: true) }
                        if wide { TodayBriefCard(facts: facts) }
                    }.padding(.bottom, 8)
                }
                .scrollDisabled(!wide)
                .fixedSize(horizontal: false, vertical: !wide)
                .frame(maxWidth: wide ? 320 : .infinity)
                .frame(height: wide ? max(0, height - 40) : nil)
                .accessibilityIdentifier("today.overview")

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if !wide { sectionPicker(vertical: false) }
                        VStack(alignment: .leading, spacing: 6) {
                            Text(section.title).font(.system(.largeTitle, design: .default).weight(.bold))
                                .accessibilityAddTraits(.isHeader)
                            Text(section.subtitle).font(.subheadline).foregroundStyle(TodayTheme.muted)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        switch section {
                        case .day:
                            scheduleCard(events: events)
                            remindersCard(dueTasks: dueTasks)
                            VStack(spacing: 0) {
                                overviewLink("Shopping", detail: "\(attention.shopping.count) needed now", symbol: "basket", section: .shopping)
                                Divider()
                                overviewLink("Home care", detail: "\(plans.count + warranties.count) alerts", symbol: "house", section: .home)
                                Divider()
                                overviewLink("Meals", detail: "\(repository.meals(on: now).count) planned today", symbol: "fork.knife", section: .meals)
                            }.padding(.horizontal, 18).background(TodayTheme.surface, in: RoundedRectangle(cornerRadius: 18))
                        case .shopping:
                            TodayPriorities(now: now, wide: false, selection: $priority)
                        case .home:
                            homeCareCard(plans: plans, warranties: warranties)
                        case .meals:
                            mealsCard(now: now)
                        }
                        if !wide { TodayBriefCard(facts: facts) }
                    }.padding(.bottom, 24)
                }
                .scrollDisabled(!wide)
                .fixedSize(horizontal: false, vertical: !wide)
                .frame(maxWidth: .infinity)
                .frame(height: wide ? max(0, height - 40) : nil)
                .accessibilityIdentifier("today.workspace")
            }.padding(20).frame(maxWidth: 1200).frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .id(repository.household?.id)
    }

    private func scheduleCard(events: [FamilyEvent]) -> some View {
        TodayCard {
            TodayPanelHeading(title: "Schedule", detail: "\(events.count) events today")
            if events.isEmpty { quiet("No events saved for today.") }
            ForEach(events.prefix(3)) { event in
                NavigationLink { EventDetailView(event: event) } label: { EventRow(event: event) }.buttonStyle(.plain)
            }
            NavigationLink { CalendarAgendaView() } label: { link("Open calendar") }
        }
    }

    private func remindersCard(dueTasks: [HouseholdTask]) -> some View {
        TodayCard {
            TodayPanelHeading(title: "Reminders", detail: "\(dueTasks.count) need attention")
            if dueTasks.isEmpty { quiet("No reminders due or overdue.") }
            ForEach(dueTasks.prefix(3)) { TaskRow(task: $0) }
            NavigationLink { PlanningListView(kind: .task) } label: { link("All reminders & chores") }
        }
    }

    private func homeCareCard(plans: [MaintenancePlan], warranties: [Warranty]) -> some View {
        TodayCard {
            TodayPanelHeading(title: "Home care", detail: "\(plans.count + warranties.count) upcoming alerts")
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
            NavigationLink { HomeAlertsView() } label: { link("See home care") }
        }
    }

    private func mealsCard(now: Date) -> some View {
        TodayCard {
            TodayPanelHeading(title: "At the table", detail: "Meals & preparation")
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
            NavigationLink { FamilyWeekView() } label: { link("Family week") }
            NavigationLink { MealIdeasView() } label: { link("Get meal ideas") }
        }
    }

    private func sectionPicker(vertical: Bool) -> some View {
        (vertical || typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 4))) {
            ForEach(TodayWorkspaceSection.allCases) { item in
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { section = item }
                } label: {
                    if vertical || typeSize.isAccessibilitySize {
                        HStack(spacing: 14) {
                            Image(systemName: item.symbol).font(.title3).frame(width: typeSize.isAccessibilitySize ? nil : 26)
                            Text(item.label).font(.subheadline.weight(.semibold))
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                        }.padding(16).frame(minHeight: 56).contentShape(Rectangle())
                    } else {
                        VStack(spacing: 7) {
                            Image(systemName: item.symbol).font(.title3)
                            Text(item.label).font(.caption.weight(.semibold))
                        }.frame(maxWidth: .infinity, minHeight: 66).contentShape(Rectangle())
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(section == item ? TodayTheme.canvas : TodayTheme.ink)
                .background(section == item ? TodayTheme.ink : TodayTheme.surface, in: RoundedRectangle(cornerRadius: 14))
                .accessibilityAddTraits(section == item ? .isSelected : [])
                .accessibilityIdentifier("today.section.\(item.rawValue)")
            }
        }
    }

    private func overviewLink(_ title: String, detail: String, symbol: String, section destination: TodayWorkspaceSection) -> some View {
        Button { withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { section = destination } } label: {
            HStack(spacing: 14) {
                Image(systemName: symbol).font(.title3).frame(width: typeSize.isAccessibilitySize ? nil : 24)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.subheadline.weight(.semibold))
                    Text(detail).font(.caption).foregroundStyle(TodayTheme.muted)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.semibold))
            }.frame(minHeight: 68).contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityIdentifier("today.open.\(destination.rawValue)")
    }

    private func quiet(_ text: String) -> some View {
        Text(text).font(.subheadline).foregroundStyle(TodayTheme.muted).fixedSize(horizontal: false, vertical: true)
    }
    private func link(_ title: String) -> some View {
        HStack { Text(title).multilineTextAlignment(.leading); Spacer(); Image(systemName: "arrow.right").accessibilityHidden(true) }
            .font(.subheadline.weight(.semibold)).foregroundStyle(TodayTheme.accent).frame(minHeight: 44).contentShape(Rectangle())
    }
}
