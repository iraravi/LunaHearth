import SwiftUI

struct MealIdeasView: View {
    @Environment(PublicConfigurationStore.self) private var publicStatus
    @Environment(\.aiAvailability) private var aiAvailability
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var day = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
    @AppStorage("mealIdeas.cookingStyle") private var styleRaw = ""
    private var cookingStyle: MealCookingStyle? { MealCookingStyle(rawValue: styleRaw) }
    @State private var context = ""
    @FocusState private var contextFocused: Bool
    @State private var result: MealSuggestionResult?
    @State private var generating = false
    @State private var reminderEnabled = false
    @State private var changingReminder = false
    @State private var draft: EntryDraft?
    @State private var error: String?
    @State private var generation: Task<Void, Never>?
    @State private var generationID = UUID()
    private let service: any MealSuggestionService = OnDeviceMealSuggestionService()
    private let reminders: any MealPlanningReminderService = MealPlanningReminder()
    private var accent: Color { AppTheme.sage }
    private var names: [String] {
        repository.inventory.filter { MealSuggestionRules.available(isUsedUp: $0.isUsedUp, expiryDay: $0.expiryDay, plannedDay: HouseholdDay(day).key) }.map(\.name).sorted()
    }
    private var columns: [GridItem] { typeSize.isAccessibilitySize ? [GridItem(.flexible())] : [GridItem(.adaptive(minimum: 290), spacing: 16)] }
    var body: some View {
        ScrollViewReader { scroll in
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HearthArtwork(name: "WelcomeTable", height: 150)
                VStack(alignment: .leading, spacing: 8) {
                    Text("From your pantry to your table.").font(AppTheme.sectionTitle)
                    Text("Plan tomorrow, or find something for today.").foregroundStyle(.secondary)
                    Picker("What do you like to cook?", selection: $styleRaw) {
                        Text("Choose a cooking style").tag("")
                        ForEach(MealCookingStyle.allCases) { style in Text(style.rawValue).tag(style.rawValue) }
                    }.pickerStyle(.menu).frame(minHeight: 44).accessibilityIdentifier("meals.cookingStyle")
                    Text("Choose a cuisine for your ideas. You can change it anytime.").font(.footnote).foregroundStyle(.secondary)
                    if (aiAvailability.showsAIActions && (publicStatus.configuration?.allows(.aiMeals) ?? true)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Anything else? (optional)").font(.subheadline.weight(.medium))
                            TextField("e.g. Vegetarian, mild spice, dinner for four in 20 minutes", text: $context, axis: .vertical)
                                .focused($contextFocused).lineLimit(2...4).padding(12).background(.background, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary.opacity(0.3)))
                                .accessibilityLabel("Meal preferences, optional").accessibilityIdentifier("meals.context")
                            Text("\(context.count)/\(MealSuggestionRules.contextLimit) · Used by on-device AI").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    DatePicker("Plan for", selection: $day, in: Calendar.current.startOfDay(for: .now)..., displayedComponents: .date)
                    Text("\(names.count) saved packs considered · check actual amounts and pack labels.").font(.footnote).foregroundStyle(.secondary)
                }
                Button { draft = EntryDraft(kind: .meal, date: day) } label: {
                    Label("Add a meal", systemImage: "plus").frame(minHeight: 44)
                }.buttonStyle(.bordered).accessibilityIdentifier("meals.addManually")
                VStack(alignment: .leading, spacing: 10) {
                    Toggle(isOn: Binding(get: { reminderEnabled }, set: { value in
                        changingReminder = true
                        Task { do { try await reminders.setEnabled(value); reminderEnabled = await reminders.enabled() } catch { self.error = error.localizedDescription }; changingReminder = false }
                    })) { Label("Plan tomorrow at 5 PM", systemImage: "clock") }.disabled(changingReminder).accessibilityIdentifier("meals.reminder")
                    Text("Daily reminder on this device, at local time. Open it to get meal ideas.").font(.footnote).foregroundStyle(.secondary)
                }.padding(20).background(.background, in: RoundedRectangle(cornerRadius: 18))
                HStack {
                    Button { generate() } label: { Label(generating ? "Finding ideas…" : "Get suggestions now", systemImage: "sparkles").padding(.vertical, 6) }
                        .hearthGlassButton(prominent: true, glassInLight: false).disabled(generating || cookingStyle == nil).accessibilityIdentifier("meals.suggest")
                    if generating { ProgressView(); Button("Cancel") { generation?.cancel(); generating = false } }
                }
                ReviewSafetyNotice(context: .meal)
                if let result {
                    Text(result.message).font(.subheadline).foregroundStyle(.secondary).id("meal.results")
                    if result.ideas.isEmpty { ContentUnavailableView("No matching ideas yet", systemImage: "fork.knife", description: Text("Try adding more pantry ingredients, or plan a meal yourself below.")) }
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                        ForEach(result.ideas) { idea in
                            VStack(alignment: .leading, spacing: 12) {
                                Label(idea.name, systemImage: "fork.knife.circle.fill").font(.title3.bold())
                                Text(idea.ingredients.joined(separator: " · ")).font(.subheadline)
                                let missing = idea.missing(from: names)
                                let toBuy = missing.filter { !repository.mealIngredientAvailability($0).inShopping }
                                if missing.isEmpty { Label("Main ingredients in pantry", systemImage: "checkmark.circle").font(.subheadline) }
                                else if !toBuy.isEmpty { Label("Need to buy: \(toBuy.joined(separator: ", "))", systemImage: "basket").font(.subheadline) }
                                let shoppingNames = idea.ingredients.filter { repository.mealIngredientAvailability($0).inShopping }
                                if !shoppingNames.isEmpty { Label("Already in shopping: \(shoppingNames.joined(separator: ", "))", systemImage: "checklist").font(.subheadline) }
                                Button("Review & plan") {
                                    draft = EntryDraft(kind: .meal, title: idea.name, date: day)
                                    draft?.mealIngredients = idea.ingredients.joined(separator: "\n")
                                }.buttonStyle(.bordered).frame(minHeight: 44).accessibilityLabel("Review and plan \(idea.name)")
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(20).background(.background, in: RoundedRectangle(cornerRadius: 18))
                        }
                    }
                }
                NavigationLink { WeeklyMealPlannerView(start: day) } label: { Label("Plan the week", systemImage: "calendar") }.frame(minHeight: 44).accessibilityIdentifier("meals.week")
                NavigationLink("View saved meal plans") { PlanningListView(kind: .meal, initialDay: day) }.frame(minHeight: 44)
            }.padding(20).frame(maxWidth: 1000).frame(maxWidth: .infinity)
        }.background(AppTheme.canvas).tint(accent)
            .toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { contextFocused = false }.accessibilityIdentifier("meals.keyboardDone") } }
            .scrollDismissesKeyboard(.interactively)
            .householdHelp(.meals)
        .featureAvailability(.mealIdeas).navigationTitle("Meal ideas").navigationBarTitleDisplayMode(.inline)
            .sheet(item: $draft) { QuickAddView(draft: $0) }
            .task {
                if ProcessInfo.processInfo.arguments.contains("--ui-testing") { styleRaw = "" }
                reminderEnabled = await reminders.enabled()
            }
            .onChange(of: scenePhase) { _, phase in if phase == .active { Task { reminderEnabled = await reminders.enabled() } } }
            .onChange(of: context) { _, value in
                if value.count > MealSuggestionRules.contextLimit { context = String(value.prefix(MealSuggestionRules.contextLimit)) }
                reset()
            }
            .onChange(of: styleRaw) { _, _ in reset() }
            .onChange(of: names) { _, _ in reset() }
            .onChange(of: repository.household?.id) { _, _ in reset(); draft = nil }
            .onDisappear { generation?.cancel(); generating = false }
            .saveError($error)
            .onChange(of: result != nil) { _, ready in
                if ready {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                        scroll.scrollTo("meal.results", anchor: .top)
                    }
                }
            }
        }
    }
    private func reset() { generationID = UUID(); generation?.cancel(); generating = false; result = nil }
    private func generate() {
        guard let style = cookingStyle else { return }
        contextFocused = false
        generation?.cancel(); result = nil; generating = true
        let snapshot = names
        let preferences = context
        let home = repository.household?.id
        let token = UUID(); generationID = token
        generation = Task {
            defer { if generationID == token { generating = false } }
            do {
                let value = try await service.suggest(names: snapshot, style: style, context: preferences)
                try Task.checkCancellation()
                guard generationID == token, home == repository.household?.id, snapshot == names, preferences == context, style == cookingStyle else { return }
                result = value
            }
            catch is CancellationError { }
            catch { self.error = error.localizedDescription }
        }
    }
}
