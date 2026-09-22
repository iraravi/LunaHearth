import SwiftUI

struct WeeklyMealPlannerView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @State private var start = Calendar.current.startOfDay(for: Date.now)
    @State private var editing: EntryDraft?
    @State private var suggestions = false
    @State private var shopping: WeeklyShoppingPreview?
    @State private var error: String?
    private let types = ["Breakfast", "Lunch", "Dinner"]
    init(start: Date = .now) { _start = State(initialValue: Calendar.current.startOfDay(for: start)) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(spacing: 14) {
                    Image(systemName: "calendar.badge.clock").font(.largeTitle).foregroundStyle(InventoryTheme.accent).accessibilityHidden(true)
                    Text("A week of good meals.").font(AppTheme.sectionTitle)
                }
                Text("Your meals and shopping, planned together.").foregroundStyle(.secondary)
                DatePicker("Seven days from", selection: $start, displayedComponents: .date)
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 16) { actions }
                    VStack(alignment: .leading, spacing: 8) { actions }
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 16)], alignment: .leading, spacing: 16) {
                ForEach(WeeklyMealRules.days(from: start), id: \.self) { day in
                    VStack(alignment: .leading, spacing: 14) {
                        Text(day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())).font(.title3.bold())
                        ForEach(types, id: \.self) { type in
                            let meals = repository.meals(on: day).filter { $0.mealType == type }
                            if meals.isEmpty {
                                Button { editing = EntryDraft(kind: .meal, date: day, mealType: type) } label: {
                                    HStack { Text(type); Spacer(); Label("Plan", systemImage: "plus") }.frame(minHeight: 44).contentShape(Rectangle())
                                }.accessibilityIdentifier("week.add.\(HouseholdDay(day).key).\(type)")
                            }
                            ForEach(meals) { meal in
                                HStack {
                                    NavigationLink { MealCookingView(meal: meal) } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(type).font(.caption).foregroundStyle(.secondary)
                                            Text(meal.title).font(.headline)
                                            Text(meal.cookedAt == nil ? "\(meal.servings ?? 2) servings" : "Cooked").font(.caption).foregroundStyle(.secondary)
                                        }.frame(maxWidth: .infinity, minHeight: 60, alignment: .leading).contentShape(Rectangle())
                                    }.buttonStyle(.plain)
                                    Button { editing = .editing(meal) } label: { Image(systemName: "pencil").frame(width: 44, height: 44) }.accessibilityLabel("Edit or swap \(meal.title)")
                                }
                            }
                            if type != "Dinner" { Divider() }
                        }
                    }.padding(20).background(InventoryTheme.surface, in: RoundedRectangle(cornerRadius: 18))
                }
                }
            }.padding(20).frame(maxWidth: 1100).frame(maxWidth: .infinity)
        }.background(InventoryTheme.canvas).tint(InventoryTheme.accent)
            .navigationTitle("Weekly meals").navigationBarTitleDisplayMode(.inline)
            .sheet(item: $editing) { QuickAddView(draft: $0) }
            .sheet(isPresented: $suggestions) { WeeklyMealDraftView(start: start) }
            .sheet(isPresented: Binding(get: { shopping != nil }, set: { if !$0 { shopping = nil } })) { if let shopping { WeeklyShoppingReviewView(preview: shopping) } }
            .saveError($error)
    }
    @ViewBuilder private var actions: some View {
        Button { suggestions = true } label: { Label("Meal ideas", systemImage: "sparkles") }.font(.subheadline).buttonStyle(.bordered).accessibilityIdentifier("week.suggest")
        Button { do { shopping = try repository.weeklyShoppingPreview(start: start) } catch { self.error = userFacingError(error) } } label: { Label("Shopping review", systemImage: "basket") }.font(.subheadline).buttonStyle(.bordered).accessibilityIdentifier("week.shopping")
    }
}

struct WeeklyMealDraftView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    let start: Date
    var familyPlanning = false
    @State private var includePrep = false
    @State private var mealTypes: Set<String> = ["Breakfast", "Lunch", "Dinner"]
    @State private var prepTimes: [UUID: Date] = [:]
    @State private var style = MealCookingStyle.any
    @State private var context = ""
    @State private var drafts: [EntryDraft] = []
    @State private var ideas: [PantryMealIdea] = []
    @State private var selected: Set<UUID> = []
    @State private var working = false
    @State private var generation: Task<Void, Never>?
    @State private var generationID = UUID()
    @State private var message = ""
    @State private var error: String?
    @State private var homeID: UUID?
    private var types: [String] { ["Breakfast", "Lunch", "Dinner"].filter { !familyPlanning || mealTypes.contains($0) } }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(familyPlanning ? "Let’s plan your week." : "A starting point for your week.").font(AppTheme.sectionTitle)
                    Text("Review every meal and serving count. Existing plans stay in place. Suggestions may repeat; swap or deselect any meal.").font(.subheadline).foregroundStyle(.secondary)
                    if familyPlanning {
                        Text("Meal ideas from your pantry. Busy evenings favor quicker dinners; only household appointment times are checked. Personal Apple calendars are not included.").font(.subheadline).foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Meals to plan").font(.headline)
                            ForEach(["Breakfast", "Lunch", "Dinner"], id: \.self) { type in
                                Toggle(type, isOn: Binding(get: { mealTypes.contains(type) }, set: { enabled in
                                    if enabled { mealTypes.insert(type) } else { mealTypes.remove(type) }
                                    clearDraft()
                                })).accessibilityIdentifier("familyWeek.meal.\(type)")
                            }
                        }.padding(16).background(InventoryTheme.surface, in: RoundedRectangle(cornerRadius: 20))
                        Toggle("Include dinner prep reminders", isOn: $includePrep).accessibilityIdentifier("familyWeek.prep")
                        Text("Optional reminders use an open 30-minute window between 4 and 7 PM. They are unassigned household tasks; notification settings stay unchanged.").font(.caption).foregroundStyle(.secondary)
                    }
                    ReviewSafetyNotice(context: .meal)
                    Picker("Cooking style", selection: $style) { ForEach(MealCookingStyle.allCases) { Text($0.rawValue).tag($0) } }.accessibilityIdentifier("week.style")
                    TextField("Preferences · optional", text: $context, axis: .vertical).lineLimit(2...4).padding(12).background(.background, in: RoundedRectangle(cornerRadius: 12))
                        .onChange(of: context) { _, value in context = MealSuggestionRules.boundedContext(value); clearDraft() }
                    Button { generate() } label: { Label(working ? "Finding ideas…" : "Generate draft", systemImage: "sparkles") }.buttonStyle(.bordered).disabled(working || types.isEmpty).accessibilityIdentifier("week.generate")
                    if working { ProgressView(); Button("Cancel generation") { generation?.cancel(); working = false } }
                    if !message.isEmpty { Text(message).font(.subheadline).foregroundStyle(.secondary) }
                    ForEach($drafts) { $draft in
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: Binding(get: { selected.contains(draft.id) }, set: { if $0 { selected.insert(draft.id) } else { selected.remove(draft.id) } })) {
                                Text("\(draft.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())) · \(draft.mealType)").font(.subheadline)
                            }
                            Text(draft.title).font(.headline)
                            if familyPlanning && includePrep && draft.mealType == "Dinner" {
                                if let time = prepTimes[draft.id] { Label("Prep reminder · \(time.formatted(date: .omitted, time: .shortened))", systemImage: "clock").font(.subheadline) }
                                else { Text("No future prep window available · meal only").font(.caption).foregroundStyle(.secondary) }
                            }
                            Stepper("\(draft.mealServings) servings", value: $draft.mealServings, in: 1...20)
                            Menu("Swap meal", systemImage: "arrow.triangle.2.circlepath") {
                                ForEach(ideas) { idea in Button(idea.name) { draft.title = idea.name; draft.mealIngredients = idea.ingredients.joined(separator: "\n"); draft.mealSteps = ""; draft.mealAmountsPerServing = [:] } }
                            }
                            Text("Amounts are not assumed. Add per-serving quantities in the saved meal before reviewing weekly shopping.").font(.caption).foregroundStyle(.secondary)
                        }.padding(16).background(InventoryTheme.surface, in: RoundedRectangle(cornerRadius: 20))
                    }
                }.padding(20).frame(maxWidth: 760).frame(maxWidth: .infinity)
            }.background(InventoryTheme.canvas).tint(InventoryTheme.accent).navigationTitle("Review week").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") {
                        do { guard let homeID else { throw MealCookingError.changed }; try repository.saveWeeklyDrafts(drafts.filter { selected.contains($0.id) }, householdID: homeID, prepTimes: includePrep ? prepTimes.filter { selected.contains($0.key) } : [:]); dismiss() } catch { self.error = userFacingError(error) }
                    }.disabled(selected.isEmpty || working).accessibilityIdentifier("week.save") }
                }.onChange(of: style) { _, _ in clearDraft() }.onDisappear { generation?.cancel() }.saveError($error)
        }
    }
    private func clearDraft() { generationID = UUID(); generation?.cancel(); working = false; drafts = []; selected = []; prepTimes = [:]; message = "" }
    private func generate() {
        clearDraft(); working = true; homeID = repository.household?.id
        let home = homeID
        let token = generationID
        let today = HouseholdDay(.now).key
        let packs = repository.inventory.filter { !$0.isUsedUp && ($0.expiryDay.map { $0 >= today } ?? true) }.sorted { ($0.expiryDay ?? "9999") < ($1.expiryDay ?? "9999") }
        let names = packs.map(\.name)
        let expiring = packs.filter { $0.expiryDay != nil }.map(\.name)
        generation = Task {
            defer { if token == generationID { working = false } }
            do {
                let result = try await OnDeviceMealSuggestionService().suggest(names: names, style: style, context: context)
                try Task.checkCancellation()
                guard token == generationID, repository.household?.id == home else { throw MealCookingError.changed }
                ideas = result.ideas.sorted { lhs, rhs in
                    let left = lhs.ingredients.filter { name in expiring.prefix(10).contains { IngredientMatching.same($0, name) } }.count
                    let right = rhs.ingredients.filter { name in expiring.prefix(10).contains { IngredientMatching.same($0, name) } }.count
                    return left == right ? lhs.id < rhs.id : left > right
                }
                message = result.message + " Earlier slots prioritize ideas using dated pantry packs. Expiry and quantity checks happen again in shopping review."
                guard !ideas.isEmpty else { return }
                var proposed: [EntryDraft] = []
                let appointments = repository.events.map { AppointmentSlot(start: $0.startAt, end: $0.endAt) }
                if familyPlanning { message += " Breakfast, lunch and dinner follow your selection. Quicker dinner ideas are prioritized when household appointments occupy an hour or more between 4 and 8 PM." }
                for day in WeeklyMealRules.days(from: start) {
                    for type in types where !repository.meals(on: day).contains(where: { $0.mealType == type }) {
                        let busy = familyPlanning && type == "Dinner" && FamilyWeekRules.isBusyEvening(on: day, appointments: appointments)
                        let candidates = busy ? ideas.sorted { $0.minutes == $1.minutes ? $0.id < $1.id : $0.minutes < $1.minutes } : ideas
                        let idea = candidates[busy ? 0 : proposed.count % candidates.count]
                        var draft = EntryDraft(kind: .meal, title: idea.name, date: day, mealType: type)
                        draft.mealIngredients = idea.ingredients.joined(separator: "\n"); draft.mealSteps = ""
                        if familyPlanning, type == "Dinner", let time = FamilyWeekRules.prepTime(on: day, appointments: appointments), time > Date.now { prepTimes[draft.id] = time }
                        proposed.append(draft)
                    }
                }
                drafts = proposed; selected = Set(drafts.map(\.id))
                if drafts.isEmpty { message = "All requested meal slots are already planned for these seven days." }
            } catch is CancellationError { }
            catch { self.error = userFacingError(error) }
        }
    }
}

struct WeeklyShoppingReviewView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    let preview: WeeklyShoppingPreview
    @State private var selected: Set<String> = []
    @State private var error: String?
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Choose what to add for the next seven days. Suggestions use saved pantry amounts and dates, which may be incomplete or out of date.")
                    Text("Check unknown amounts before buying. Selecting an unknown amount adds its name only. Existing shopping items are not duplicated.").font(.footnote).foregroundStyle(.secondary)
                }
                if preview.rows.isEmpty { ContentUnavailableView("No ingredients to review", systemImage: "basket", description: Text("Plan meals and add their ingredients first.")) }
                ForEach(preview.rows) { row in
                    if row.covered || row.alreadyListed {
                        Label { VStack(alignment: .leading, spacing: 5) { Text(row.name).font(.headline); Text(row.detail).font(.caption).foregroundStyle(.secondary) } } icon: { Image(systemName: "checkmark.circle") }
                    } else {
                        Button {
                            if !selected.insert(row.id).inserted { selected.remove(row.id) }
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: selected.contains(row.id) ? "checkmark.circle.fill" : "circle").font(.title2).accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 5) { Text(row.name).font(.headline); Text(row.detail).font(.caption).foregroundStyle(.secondary) }
                                Spacer(minLength: 0)
                            }.frame(maxWidth: .infinity, minHeight: 48, alignment: .leading).contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityValue(selected.contains(row.id) ? "Selected" : "Not selected").accessibilityIdentifier("week.need.\(row.name)")
                    }
                }
            }.scrollContentBackground(.hidden).background(ShoppingTheme.canvas).tint(ShoppingTheme.accent)
                .navigationTitle("Weekly shopping").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Add") { do { try repository.addWeeklyShopping(preview, selected: selected); dismiss() } catch { self.error = userFacingError(error) } }.disabled(selected.isEmpty).accessibilityIdentifier("week.addShopping") }
                }.saveError($error)
        }
    }
}
