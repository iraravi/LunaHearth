import SwiftUI

struct ListsView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @State private var adding = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ScreenIntro(eyebrow: "Household lists", title: "What needs doing?",
                                subtitle: "Manage tasks, shopping, and meals.", art: "HearthPlanning")
                    VStack(spacing: 0) {
                        NavigationLink { PlanningListView(kind: .task) } label: {
                            IllustratedListRow(title: "Tasks & chores", detail: "Open tasks: \(repository.tasks.filter { !$0.isCompleted }.count)", symbol: "checklist")
                        }
                        Divider().padding(.leading, 82)
                        NavigationLink { PlanningListView(kind: .grocery) } label: {
                            IllustratedListRow(title: "Groceries", detail: "Shopping items: \(repository.groceries.filter { !$0.isCompleted }.count)", symbol: "basket")
                        }
                        Divider().padding(.leading, 82)
                        NavigationLink { PlanningListView(kind: .meal) } label: {
                            IllustratedListRow(title: "Meals", detail: "Plan what to eat", symbol: "fork.knife")
                        }
                    }.background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                        .buttonStyle(.plain)
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "leaf").foregroundStyle(AppTheme.accent).accessibilityHidden(true)
                        Text("Your lists stay available, even offline.")
                            .font(.subheadline).foregroundStyle(AppTheme.muted)
                    }.padding(.horizontal, 8)
                }.padding(20).frame(maxWidth: 700).frame(maxWidth: .infinity)
            }.background(AppTheme.canvas)
            .navigationTitle("Lists").navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Quick Add", systemImage: "plus") { adding = true } }
            .sheet(isPresented: $adding) { QuickAddView() }
        }
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
    @Environment(LocalHouseholdRepository.self) private var repository
    let kind: EntryKind
    @State private var adding = false
    @State private var showCompleted = false
    @State private var selectedDay = Date.now
    @State private var error: String?

    var body: some View {
        List {
            Section {
                ScreenIntro(eyebrow: kind == .task ? "Tasks" : kind == .grocery ? "Shopping" : "Meal planning",
                            title: kind == .task ? "Tasks & chores." : kind == .grocery ? "Your shopping list." : "Plan your meals.",
                            subtitle: kind == .task ? "Tap a task to mark it complete." : kind == .grocery ? "Tap an item as it goes into your basket." : "Choose a day to see or add meals.",
                            art: kind == .task ? nil : "HearthTable")
            }.listRowBackground(Color.clear).listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 16, trailing: 12))
            if kind == .task {
                Toggle("Show completed", isOn: $showCompleted)
                let tasks = repository.tasks.filter { showCompleted || !$0.isCompleted }
                if tasks.isEmpty { empty }
                ForEach(tasks) { TaskRow(task: $0) }
            } else if kind == .grocery {
                Toggle("Show checked items", isOn: $showCompleted)
                let items = repository.groceries.filter { showCompleted || !$0.isCompleted }
                if items.isEmpty { empty }
                ForEach(items) { item in
                    Button {
                        do { try repository.toggle(item) } catch { self.error = userFacingError(error) }
                    } label: {
                        HStack {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle").font(.title2).foregroundStyle(AppTheme.accent)
                            VStack(alignment: .leading) {
                                Text(item.name).strikethrough(item.isCompleted)
                                if let quantity = item.quantityText, !quantity.isEmpty { Text(quantity).font(.caption).foregroundStyle(.secondary) }
                            }
                        }.frame(minHeight: 44)
                    }.buttonStyle(.plain)
                        .accessibilityLabel("\(item.name), \(item.isCompleted ? "checked" : "not checked")")
                        .accessibilityHint("Double tap to change shopping status")
                        .entryActions(.editing(item))
                }
            } else {
                DatePicker("Day", selection: $selectedDay, displayedComponents: .date)
                let meals = repository.meals(on: selectedDay)
                if meals.isEmpty { empty }
                ForEach(meals) { meal in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meal.mealType).font(.caption).foregroundStyle(.secondary)
                        Text(meal.title).font(.headline)
                        if let notes = meal.notes, !notes.isEmpty { Text(notes).font(.subheadline) }
                    }.entryActions(.editing(meal))
                }
            }
        }
        .hearthList()
        .navigationTitle(kind == .task ? "Tasks & Chores" : kind == .grocery ? "Groceries" : "Meals")
        .toolbar { Button("Add \(kind.rawValue)", systemImage: "plus") { adding = true } }
        .sheet(isPresented: $adding) { QuickAddView(kind: kind, date: selectedDay) }
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
