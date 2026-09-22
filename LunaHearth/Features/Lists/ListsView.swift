import SwiftUI

struct ListsView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var adding = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("A lighter everyday.").font(AppTheme.displayTitle)
                        Text("Remember it. Buy it. Make something good.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    VStack(spacing: 16) {
                        NavigationLink { PlanningListView(kind: .task) } label: {
                            listCard(title: "Reminders", detail: "What needs doing", count: "\(repository.tasks.filter { !$0.isCompleted }.count) open tasks", symbol: "checklist", art: "EditorialPlanning", color: .indigo)
                        }.accessibilityIdentifier("lists.tasks")
                        NavigationLink { ShoppingListView() } label: {
                            listCard(title: "Shopping", detail: "What to buy", count: "\(repository.groceries.filter { !$0.isCompleted }.count) items to buy", symbol: "basket", art: "WelcomeTable", color: ShoppingTheme.accent)
                        }.accessibilityIdentifier("lists.shopping")
                        NavigationLink { MealIdeasView() } label: {
                            listCard(title: "Meal ideas", detail: "What to cook", count: "Ideas from your pantry", symbol: "fork.knife", art: "EditorialPantry", color: InventoryTheme.accent)
                        }.accessibilityIdentifier("lists.meals")
                    }.buttonStyle(.plain)
                    Label("Made for your household. Available offline.", systemImage: "house")
                        .font(.footnote).foregroundStyle(.secondary)
                }.padding(20).frame(maxWidth: 800).frame(maxWidth: .infinity)
            }.background(AppTheme.canvas)
            .navigationTitle("Lists").navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Quick Add", systemImage: "plus") { adding = true } }
            .sheet(isPresented: $adding) { QuickAddView() }
        }
    }

    private func listCard(title: String, detail: String, count: String, symbol: String, art: String, color: Color) -> some View {
        HStack(spacing: 18) {
            if !textSize.isAccessibilitySize {
                Image(art).resizable().scaledToFill().frame(width: 82, height: 100)
                    .clipped().clipShape(RoundedRectangle(cornerRadius: 18))
                    .allowsHitTesting(false).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: symbol).font(.title3.bold()).foregroundStyle(color)
                Text(detail).font(.subheadline.weight(.medium)).foregroundStyle(.primary)
                Text(count).font(.caption).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(color).accessibilityHidden(true)
        }.padding(18).frame(maxWidth: .infinity, minHeight: 136, alignment: .leading)
            .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
            .contentShape(Rectangle())
    }
}

struct IllustratedListRow: View {
    let title: String
    let detail: String
    let symbol: String
    var body: some View {
        HStack(spacing: 16) {
            HearthIcon(symbol: symbol)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline).foregroundStyle(AppTheme.ink)
                Text(detail).font(.subheadline).foregroundStyle(AppTheme.muted)
            }.frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.muted)
                .accessibilityHidden(true)
        }.padding(20).contentShape(Rectangle())
    }
}

struct PlanningListView: View {
    let kind: EntryKind
    var initialDay: Date = .now
    var body: some View {
        if kind == .grocery { ShoppingListView() }
        else if kind == .meal { MealPlansView(initialDay: initialDay) }
        else { HouseholdPlanningListView(kind: kind, initialDay: initialDay) }
    }
}

private struct HouseholdPlanningListView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    let kind: EntryKind
    @State private var adding = false
    @State private var showCompleted = false
    @State private var selectedDay: Date
    init(kind: EntryKind, initialDay: Date) {
        self.kind = kind
        _selectedDay = State(initialValue: initialDay)
    }
    @State private var error: String?

    var body: some View {
        List {
            Section {
                ScreenIntro(eyebrow: kind == .task ? "Tasks" : kind == .grocery ? "Shopping" : "Meal planning",
                            title: kind == .task ? "Tasks & chores." : kind == .grocery ? "Your shopping list." : "Plan your meals.",
                            subtitle: kind == .task ? "Tap a task to mark it complete." : kind == .grocery ? "Tap an item as it goes into your basket." : "Choose a day to see or add meals.",
                            art: kind == .task ? nil : "WelcomeTable")
            }.listRowBackground(Color.clear).listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 16, trailing: 12))
            if kind == .task {
                Toggle("Show completed", isOn: $showCompleted)
                let tasks = repository.tasks.filter { showCompleted || !$0.isCompleted }
                if tasks.isEmpty { empty }
                ForEach(tasks) { TaskRow(task: $0) }
            } else {
                DatePicker("Day", selection: $selectedDay, displayedComponents: .date)
                let meals = repository.meals(on: selectedDay)
                if meals.isEmpty { empty }
                ForEach(meals) { meal in
                    NavigationLink { MealCookingView(meal: meal) } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(meal.mealType).font(.caption).foregroundStyle(.secondary)
                            Text(meal.title).font(.headline)
                            Label(meal.cookedAt == nil ? "Meal details" : "Cooked", systemImage: meal.cookedAt == nil ? "fork.knife" : "checkmark.circle")
                        }
                    }.entryActions(.editing(meal))
                }
            }
        }
        .hearthList()
        .navigationTitle(kind == .task ? "Tasks & Chores" : kind == .grocery ? "Groceries" : "Meals")
        .toolbar { Button("Add \(kind.rawValue)", systemImage: "plus") { adding = true } }
        .sheet(isPresented: $adding) { QuickAddView(kind: kind, date: selectedDay, fixedKind: true) }
        .saveError($error)
    }

    private var empty: some View {
        ContentUnavailableView("A fresh list", systemImage: kind.symbol, description: Text("Tap + to add your first \(kind.rawValue.lowercased())."))
    }
}

struct TaskRow: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    let task: HouseholdTask
    @State private var error: String?
    var body: some View {
        Button {
            do { try repository.toggle(task) } catch { self.error = userFacingError(error) }
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle").font(.title2).foregroundStyle(AppTheme.accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title).strikethrough(task.isCompleted)
                    Text(repository.memberName(task.assignedMemberID)).font(.caption).foregroundStyle(.secondary)
                    if let due = task.dueAt {
                        Text("\(due < Calendar.current.startOfDay(for: .now) && !task.isCompleted ? "Overdue · " : "Due ")\(due.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }.frame(minHeight: 44)
        }.buttonStyle(.plain)
            .accessibilityLabel("\(task.title), \(task.isCompleted ? "completed" : "not completed")")
            .accessibilityHint("Double tap to change completion")
            .accessibilityIdentifier("task.toggle.\(task.id)")
            .entryActions(.editing(task))
            .saveError($error)
    }
}
