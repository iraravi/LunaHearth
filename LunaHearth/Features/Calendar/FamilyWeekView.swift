import SwiftUI

struct FamilyWeekView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var start = Calendar.current.startOfDay(for: Date.now)
    @State private var dayIndex = 0
    @State private var memberID: UUID?
    @State private var planning = false
    @State private var shopping: WeeklyShoppingPreview?
    @State private var error: String?
    private var days: [Date] { WeeklyMealRules.days(from: start) }

    init(start: Date = .now) {
        _start = State(initialValue: Calendar.current.startOfDay(for: start))
    }

    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width >= 700 && !typeSize.isAccessibilitySize
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header(wide: wide)
                    controls
                    if wide {
                        ScrollView(.horizontal) {
                            HStack(alignment: .top, spacing: 14) {
                                ForEach(days, id: \.self) { day in dayCard(day).frame(width: 280) }
                            }.padding(.bottom, 8)
                        }.accessibilityLabel("Seven day planner. Scroll horizontally for more days.")
                    } else {
                        daySelector
                        if days.indices.contains(dayIndex) {
                            dayCard(days[dayIndex])
                                .gesture(DragGesture(minimumDistance: 45).onEnded { value in
                                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                                    dayIndex = min(6, max(0, dayIndex + (value.translation.width < 0 ? 1 : -1)))
                                })
                        }
                    }
                    shoppingCard
                    NavigationLink { WeeklyMealPlannerView(start: start) } label: {
                        Label("Breakfast, lunch & dinner planner", systemImage: "fork.knife").frame(minHeight: 44)
                    }
                    Text("Household plans only. Undated tasks and shopping stay in their lists. Personal Apple calendars remain in Calendar’s connected calendars section.")
                        .font(.caption).foregroundStyle(.secondary)
                }.padding(20).frame(maxWidth: 1600).frame(maxWidth: .infinity)
            }.background(AppTheme.canvas)
        }.navigationTitle("Family week").navigationBarTitleDisplayMode(.inline).tint(AppTheme.slate)
            .sheet(isPresented: $planning) { WeeklyMealDraftView(start: start, familyPlanning: true) }
            .sheet(isPresented: Binding(get: { shopping != nil }, set: { if !$0 { shopping = nil } })) {
                if let shopping { WeeklyShoppingReviewView(preview: shopping) }
            }.saveError($error)
            .onChange(of: repository.household?.id) { _, _ in memberID = nil; planning = false; shopping = nil }
    }

    private func header(wide: Bool) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(repository.household?.name ?? "Your household").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Text("A little more together.").font(AppTheme.sectionTitle).fixedSize(horizontal: false, vertical: true)
                Text("Appointments, to-dos and meals. One shared week.").font(.subheadline).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading)
            if !typeSize.isAccessibilitySize {
                Image("EditorialPlanning").resizable().scaledToFill().frame(width: wide ? 230 : 105, height: 130)
                    .clipped().clipShape(RoundedRectangle(cornerRadius: 20)).accessibilityHidden(true)
            }
        }.padding(20).background(AppTheme.slate.opacity(0.07), in: RoundedRectangle(cornerRadius: 20))
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            DatePicker("Week starting", selection: $start, displayedComponents: .date).accessibilityIdentifier("familyWeek.start")
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { weekActions }
                VStack(alignment: .leading, spacing: 8) { weekActions }
            }
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    person("Everyone", id: nil)
                    ForEach(repository.members) { person($0.displayName, id: $0.id) }
                }
            }.scrollIndicators(.hidden)
            if memberID != nil { Text("Showing this person’s appointments and tasks, plus unassigned household plans. Meals are shared.").font(.caption).foregroundStyle(.secondary) }
        }
    }

    @ViewBuilder private var weekActions: some View {
        Button { start = Calendar.current.date(byAdding: .day, value: -7, to: start) ?? start; dayIndex = 0 } label: {
            Label("Previous week", systemImage: "chevron.left").labelStyle(.iconOnly).frame(width: 44, height: 44)
        }
        Button("This week") { start = Calendar.current.startOfDay(for: .now); dayIndex = 0 }.frame(minHeight: 44)
        Button { start = Calendar.current.date(byAdding: .day, value: 7, to: start) ?? start; dayIndex = 0 } label: {
            Label("Next week", systemImage: "chevron.right").labelStyle(.iconOnly).frame(width: 44, height: 44)
        }.accessibilityIdentifier("familyWeek.next")
        Button { planning = true } label: { Label("Plan our week", systemImage: "sparkles") }
            .buttonStyle(.bordered).accessibilityIdentifier("familyWeek.plan")
    }

    private func person(_ name: String, id: UUID?) -> some View {
        Button { memberID = id } label: {
            HStack(spacing: 8) {
                if id != nil { CalendarPersonAvatar(name: name, id: id) }
                Text(name).font(.subheadline.weight(.medium))
            }.padding(.horizontal, 12).frame(minHeight: 48)
                .background(memberID == id ? AppTheme.slate.opacity(0.12) : AppTheme.surface, in: Capsule())
        }.buttonStyle(.plain).accessibilityAddTraits(memberID == id ? .isSelected : [])
            .accessibilityIdentifier("familyWeek.member.\(name)")
    }

    private var daySelector: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                    Button { dayIndex = index } label: {
                        VStack(spacing: 5) {
                            Text(day, format: .dateTime.weekday(.abbreviated)).font(.caption)
                            Text(day, format: .dateTime.day()).font(.headline)
                        }.padding(12).frame(minWidth: 50)
                            .background(dayIndex == index ? AppTheme.slate.opacity(0.15) : AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                    }.buttonStyle(.plain).accessibilityLabel(day.formatted(date: .complete, time: .omitted))
                        .accessibilityAddTraits(dayIndex == index ? .isSelected : []).accessibilityIdentifier("familyWeek.day.\(index)")
                }
            }
        }.scrollIndicators(.hidden)
    }

    private func matches(_ id: UUID?) -> Bool { memberID == nil || id == nil || id == memberID }

    private func dayCard(_ day: Date) -> some View {
        let events = repository.events.filter { FamilyWeekRules.occurs(start: $0.startAt, end: $0.endAt, on: day) && matches($0.assignedMemberID) }.sorted { $0.startAt < $1.startAt }
        let tasks = repository.tasks.filter { !$0.isCompleted && matches($0.assignedMemberID) && ($0.dueAt.map { Calendar.current.isDate($0, inSameDayAs: day) } ?? false) }
            .sorted { ($0.dueAt ?? .distantFuture) < ($1.dueAt ?? .distantFuture) }
        let meals = repository.meals(on: day)
        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(day, format: .dateTime.weekday(.wide)).font(.title3.bold())
                Text(day, format: .dateTime.month(.abbreviated).day()).font(.subheadline).foregroundStyle(.secondary)
            }.accessibilityAddTraits(.isHeader)
            sectionTitle("Appointments", symbol: "calendar", color: .indigo)
            if events.isEmpty { quiet("An open day") }
            ForEach(events) { event in
                NavigationLink { EventDetailView(event: event) } label: {
                    entry(event.title, detail: "\(event.startAt.formatted(date: .omitted, time: .shortened)) · \(repository.memberName(event.assignedMemberID))", symbol: AppointmentKind(rawValue: event.appointmentKind ?? "")?.symbol ?? "calendar", color: .indigo)
                }.buttonStyle(.plain)
            }
            Divider()
            sectionTitle("To do", symbol: "checklist", color: .teal)
            if tasks.isEmpty { quiet("Nothing due") }
            ForEach(tasks) { task in
                NavigationLink { TaskDetailView(task: task) } label: {
                    entry(task.title, detail: "\(task.dueAt?.formatted(date: .omitted, time: .shortened) ?? "") · \(repository.memberName(task.assignedMemberID))", symbol: task.mealID == nil ? "circle" : "fork.knife", color: .teal)
                }.buttonStyle(.plain)
            }
            Divider()
            sectionTitle("At the table", symbol: "fork.knife", color: .orange)
            if meals.isEmpty { NavigationLink { WeeklyMealPlannerView(start: day) } label: { Label("Plan a meal", systemImage: "plus").font(.subheadline).frame(minHeight: 44) } }
            ForEach(meals) { meal in
                NavigationLink { MealCookingView(meal: meal) } label: {
                    entry(meal.title, detail: meal.cookedAt == nil ? meal.mealType : "\(meal.mealType) · Cooked", symbol: "fork.knife", color: .orange)
                }.buttonStyle(.plain)
            }
        }.padding(18).frame(maxWidth: .infinity, alignment: .topLeading)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18))
    }

    private func sectionTitle(_ title: String, symbol: String, color: Color) -> some View {
        Label { Text(title).foregroundStyle(.primary) } icon: { Image(systemName: symbol).foregroundStyle(color) }.font(.subheadline.weight(.semibold)).accessibilityAddTraits(.isHeader)
    }
    private func quiet(_ text: String) -> some View { Text(text).font(.subheadline).foregroundStyle(.secondary) }
    private func entry(_ title: String, detail: String, symbol: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol).foregroundStyle(color).frame(width: 22).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading)
        }.padding(12).frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
            .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: 14)).contentShape(Rectangle())
    }

    private var shoppingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Ready for the week", systemImage: "basket").font(.headline)
            Text("\(repository.groceries.filter { !$0.isCompleted }.count) items on your household shopping list").font(.subheadline).foregroundStyle(.secondary)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 20) { shoppingActions }
                VStack(alignment: .leading, spacing: 8) { shoppingActions }
            }
        }.padding(20).frame(maxWidth: .infinity, alignment: .leading).background(ShoppingTheme.hero, in: RoundedRectangle(cornerRadius: 18)).tint(ShoppingTheme.accent)
    }
    @ViewBuilder private var shoppingActions: some View {
        Button { do { shopping = try repository.weeklyShoppingPreview(start: start) } catch { self.error = userFacingError(error) } } label: {
            Label("Review meal ingredients", systemImage: "checklist")
        }.frame(minHeight: 44).accessibilityIdentifier("familyWeek.shopping")
        NavigationLink { PlanningListView(kind: .grocery) } label: { Label("Open shopping", systemImage: "arrow.up.right") }.frame(minHeight: 44)
    }
}
