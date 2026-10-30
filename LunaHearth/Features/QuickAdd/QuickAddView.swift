import SwiftUI

struct QuickAddView: View {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var reduceMotion: Bool { HearthMotion.reduced(systemReduceMotion) }
    @Environment(PublicConfigurationStore.self) private var publicStatus
    @Environment(\.aiAvailability) private var aiAvailability
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(AppleConnections.self) private var connections
    @State private var saving = false
    @State private var reminderID = UUID()
    @Environment(\.dismiss) private var dismiss
    @State private var draft: EntryDraft
    @State private var error: String?
    @State private var comparing = false
    @State private var aiMatches: Set<UUID> = []
    @State private var comparisonStatus: String?
    private let comparer: any IngredientComparisonService = OnDeviceIngredientComparisonService()
    private var comparisonCandidates: [GroceryItem] {
        repository.groceries.filter { !$0.isCompleted && $0.id != draft.recordID }
    }
    private var similarShopping: [GroceryItem] {
        guard draft.kind == .grocery && !appleOnlyEntry else { return [] }
        return comparisonCandidates.filter { IngredientMatching.same($0.name, draft.title) || IngredientMatching.possibleTypo($0.name, draft.title) || aiMatches.contains($0.id) }
    }
    private var shoppingNeedsReview: Bool { !similarShopping.isEmpty && !draft.allowDuplicateShoppingItem }
    private func resetComparison() { comparing = false; aiMatches = []; comparisonStatus = nil; draft.allowDuplicateShoppingItem = false }
    private enum Field: Hashable { case title, quantity, store, manufacturer, model, serial, shopping, notes, ingredients; case ingredientAmount(String) }
    @FocusState private var focusedField: Field?
    private let fixedKind: Bool
    private let appleDestination: Bool

    init(kind: EntryKind = .task, parentID: UUID? = nil, date: Date = .now, fixedKind: Bool = false, appleDestination: Bool = false) {
        self.appleDestination = appleDestination
        self.fixedKind = fixedKind
        _draft = State(initialValue: EntryDraft(kind: kind, date: date, endDate: date.addingTimeInterval(3600), parentID: parentID, quantityUnit: kind == .grocery && !appleDestination ? .piece : .custom))
    }

    init(draft: EntryDraft) { _draft = State(initialValue: draft); fixedKind = true; appleDestination = false }

    private var appleOnlyEntry: Bool { appleDestination && draft.recordID == nil && [.task, .grocery].contains(draft.kind) }
    private var purpose: ReminderPurpose { draft.kind == .grocery ? .shopping : .reminders }
    private var entryName: String { appleOnlyEntry ? purpose == .shopping ? "Shopping item" : "Reminder" : draft.kind.rawValue }

    private var streamlinedShopping: Bool { fixedKind && draft.kind == .grocery && !appleOnlyEntry }

    var body: some View {
        NavigationStack {
            ScrollViewReader { scroll in
            Group {
            if streamlinedShopping { shoppingEditor } else { Form {
                Section {
                    HStack(spacing: 14) {
                        HearthIcon(symbol: draft.kind.symbol)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(draft.recordID == nil ? (fixedKind ? "Add \(entryName.lowercased())." : "Add to your household.") : "Edit the details.")
                                .font(.system(.title2, design: .default, weight: .bold)).foregroundStyle(AppTheme.ink)
                            Text(appleOnlyEntry ? "Saved in Apple Reminders" : "\(draft.kind.rawValue) · Saved on this device")
                                .font(.caption).foregroundStyle(AppTheme.muted)
                        }
                    }.padding(.vertical, 6)
                }.listRowBackground(Color.clear)
                Section {
                    if !fixedKind { Picker("Add", selection: $draft.kind) {
                        ForEach(EntryKind.allCases) { kind in Label(kind == .task ? "Reminder" : kind == .grocery ? "Shopping item" : kind.rawValue, systemImage: kind.symbol).tag(kind) }
                    }.accessibilityIdentifier("quickAdd.kind").disabled(draft.recordID != nil) }
                    TextField(draft.kind == .warranty ? "Provider / warranty name" : "Name or title", text: $draft.title)
                        .accessibilityIdentifier("quickAdd.title").focused($focusedField, equals: .title)
                }
                details
                if appleOnlyEntry {
                    Section("Apple Reminders") {
                        NavigationLink { ConnectedRemindersView(purpose: purpose) } label: {
                            LabeledContent("List", value: connections.list(for: purpose)?.title ?? "Choose a list")
                        }
                        Text("Saved directly to this Apple list. No household copy is created.").font(.footnote)
                    }
                }
            }.hearthList()
            } }
            .background(streamlinedShopping ? ShoppingTheme.canvas : AppTheme.canvas)
            .tint(streamlinedShopping ? ShoppingTheme.accent : AppTheme.ink)
            .disabled(saving)
            .safeAreaInset(edge: .bottom) {
                if streamlinedShopping {
                    ShoppingBottomAction(title: draft.recordID == nil ? "Add item" : "Save", detail: "Saved to your home", disabled: saving || draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || shoppingNeedsReview, identifier: "quickAdd.save") { focusedField = nil; save() }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .interactiveDismissDisabled(saving)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(draft.recordID == nil ? (fixedKind ? "Add \(entryName)" : "Quick Add") : "Edit \(draft.kind.rawValue)")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    if focusedField == .store, let completion = storeCompletion {
                        Button {
                            do { draft.storeName = try repository.addStore(name: completion).displayName; focusedField = nil }
                            catch { self.error = userFacingError(error) }
                        } label: {
                            Text(completion).font(.subheadline.weight(.semibold)).lineLimit(1)
                        }.accessibilityIdentifier("shopping.keyboardStoreSuggestion")
                    }
                    Spacer()
                    Button("Done") { focusedField = nil }.accessibilityIdentifier("quickAdd.keyboardDone")
                }
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(saving) }
                if !streamlinedShopping { ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.bold().accessibilityIdentifier("quickAdd.save")
                        .disabled(saving || draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || shoppingNeedsReview || (appleOnlyEntry && connections.list(for: purpose)?.writable != true))
                }
                }
            }
            .onChange(of: draft.title) { _, _ in resetComparison() }
            .onChange(of: draft.kind) { _, _ in resetComparison(); draft.parentID = nil; draft.memberID = nil; draft.quantity = ""; draft.storeName = ""; draft.neededLater = false }
            .task(id: comparing) {
                guard comparing else { return }
                defer { comparing = false }
                let name = draft.title, home = repository.household?.id
                let snapshot = Array(comparisonCandidates.prefix(60).map { ($0.id, $0.name) })
                do {
                    let result = try await comparer.compare(name: name, candidates: snapshot.map { $0.1 })
                    try Task.checkCancellation()
                    guard name == draft.title, home == repository.household?.id, draft.kind == .grocery, !appleOnlyEntry else { return }
                    aiMatches = Set(result.matchingIndices.compactMap { snapshot.indices.contains($0) ? snapshot[$0].0 : nil })
                    comparisonStatus = result.usedModel ? "AI checked up to 60 pending items. Possible matches need your review; an empty result is not a guarantee." : "On-device AI is unavailable. Offline name and alias checks are still active."
                } catch { if !Task.isCancelled { comparisonStatus = "AI comparison couldn’t finish. Offline checks are still active." } }
            }
            .onChange(of: repository.household?.id) { _, _ in resetComparison() }
            .task { if appleDestination { await connections.refreshSources(.reminders) } }
            .saveError($error)
            .onChange(of: focusedField) { _, field in
                if field == .store {
                    withAnimation(reduceMotion ? nil : .default) { scroll.scrollTo("shopping.store", anchor: .top) }
                }
            }
            }
        }
    }

    private var storeCompletion: String? {
        guard !draft.storeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return repository.shoppingStoreNames.first { ShoppingStoreCatalog.matches($0, query: draft.storeName) }
            ?? ShoppingStoreCatalog.suggestions(query: draft.storeName, region: .all, excluding: repository.shoppingStoreNames).first?.name
    }

    @ViewBuilder private var duplicateReview: some View {
        if draft.kind == .grocery && !appleOnlyEntry && !comparisonCandidates.isEmpty && !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(similarShopping) { item in
                    VStack(alignment: .leading, spacing: 5) {
                        Label(IngredientMatching.same(item.name, draft.title) ? "Already on your list" : "Possibly the same item", systemImage: "square.on.square").font(.subheadline.bold())
                            .accessibilityIdentifier("shopping.duplicateItem")
                        Text(item.name).font(.headline)
                        Text([item.quantityText, repository.shoppingStoreName(for: item), item.assignedMemberID.map { repository.memberName($0) }, item.neededLater == true ? "Later" : "Now"].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")).font(.caption)
                    }
                }
                if !similarShopping.isEmpty {
                    Button("Keep existing item") { dismiss() }.buttonStyle(.borderless).accessibilityIdentifier("shopping.keepExisting")
                    Toggle("Keep a separate entry", isOn: $draft.allowDuplicateShoppingItem).font(.subheadline).accessibilityIdentifier("shopping.allowDuplicate")
                }
                if (aiAvailability.showsAIActions && (publicStatus.configuration?.allows(.aiDuplicates) ?? true)) {
                    Button { focusedField = nil; comparing = true } label: { Label(comparing ? "Comparing on your device…" : "Check similar names with AI", systemImage: "sparkles") }
                        .disabled(comparing).buttonStyle(.borderless).accessibilityIdentifier("shopping.compareAI")
                }
                if let comparisonStatus { Text(comparisonStatus).font(.caption).accessibilityIdentifier("shopping.comparisonStatus") }
                Text("Aliases and likely typos are checked offline. Compare store, buyer and amount before adding another purchase.").font(.caption).foregroundStyle(ShoppingTheme.muted)
            }.foregroundStyle(ShoppingTheme.ink).padding(12).background(ShoppingTheme.canvas, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var shoppingEditor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 16) {
                    Image(systemName: "leaf.fill").font(.system(size: 32)).foregroundStyle(ShoppingTheme.accent)
                        .frame(width: 68, height: 68).background(ShoppingTheme.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 20)).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(draft.recordID == nil ? "What do you need?" : "Make it yours.").font(AppTheme.sectionTitle)
                        Text("One item. All the right details.").font(.subheadline).foregroundStyle(.secondary)
                    }
                }.padding(.vertical, 8)
                ShoppingFormCard {
                    shoppingField("Item", placeholder: "Milk, fruit, washing liquid…", text: $draft.title, field: .title, id: "quickAdd.title")
                    duplicateReview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How much?").font(.subheadline.weight(.semibold))
                        HStack(alignment: .top, spacing: 12) {
                            TextField(draft.quantityUnit == .custom ? "e.g. a small bunch" : "e.g. 2", text: $draft.quantity)
                                .keyboardType(draft.quantityUnit == .custom ? .default : .decimalPad)
                                .focused($focusedField, equals: .quantity).shoppingInputStyle()
                                .accessibilityLabel("Amount").accessibilityIdentifier("shopping.quantity")
                            Picker("Unit", selection: $draft.quantityUnit) {
                                ForEach(ShoppingUnit.allCases) { Text($0.title).tag($0) }
                            }.pickerStyle(.menu).frame(minHeight: 52).accessibilityIdentifier("shopping.unit")
                        }
                        Text(draft.quantityUnit == .custom ? "Use a description for anything that needs it." : "Pieces, weight or volume · amount is optional").font(.caption).foregroundStyle(.secondary)
                    }
                }
                ShoppingFormCard {
                    ShoppingTimingPicker(neededLater: $draft.neededLater, date: $draft.shoppingDate)
                    Label("Plan the pickup", systemImage: "bag.fill").font(.headline).foregroundStyle(.primary)
                    shoppingField("Store", placeholder: "Any store", text: $draft.storeName, field: .store, id: "shopping.store")
                    ShoppingStoreSuggestions(store: $draft.storeName)
                    Text("Who will buy?").font(.subheadline.weight(.semibold))
                    Picker(selection: $draft.memberID) {
                        Text("Anyone").tag(nil as UUID?)
                        ForEach(repository.members) { Text($0.displayName).tag(Optional($0.id)) }
                    } label: { Label("Who will buy?", systemImage: "person.crop.circle") }
                        .tint(.primary).frame(minHeight: 44).accessibilityIdentifier("shopping.buyer")
                    if draft.memberID != nil {
                        Text("Appears in their Today → For you view. Alerts need a shared home and notification permission on their device.").font(.caption).foregroundStyle(.secondary)
                    }
                    if repository.members.isEmpty {
                        Text("Shopping solo? Leave Anyone selected. Add people later in More → Family.").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }.padding(20).frame(maxWidth: 640).frame(maxWidth: .infinity)
        }
    }

    private func shoppingField(_ label: String, placeholder: String, text: Binding<String>, field: Field, id: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.subheadline.weight(.semibold))
            TextField(placeholder, text: text).focused($focusedField, equals: field)
                .shoppingInputStyle().accessibilityLabel(label).accessibilityIdentifier(id)
        }.id(id)
    }

    @ViewBuilder private var details: some View {
        if draft.kind == .event {
            Section("When") {
                DatePicker("Starts", selection: $draft.date)
                DatePicker("Ends", selection: $draft.endDate)
            }
        }
        if [.task, .warranty, .maintenance].contains(draft.kind) {
            Section {
                Toggle(draft.kind == .warranty ? "Expiration date" : "Due date", isOn: $draft.hasDate)
                if draft.hasDate { DatePicker("Date", selection: $draft.date, displayedComponents: .date) }
            }
        }
        if (draft.kind == .task && !appleOnlyEntry) || draft.kind == .event {
            Section {
                Picker("Assigned to", selection: $draft.memberID) {
                    Text("Family").tag(nil as UUID?)
                    ForEach(repository.members) { Text($0.displayName).tag(Optional($0.id)) }
                }
            }
        }
        if draft.kind == .grocery {
            Section("Shopping item") {
                duplicateReview
                TextField("Quantity (e.g. 2 cartons)", text: $draft.quantity).focused($focusedField, equals: .quantity)
                    .accessibilityIdentifier("shopping.quantity")
                if !appleOnlyEntry {
                    ShoppingTimingPicker(neededLater: $draft.neededLater, date: $draft.shoppingDate)
                    LabeledContent("Store") {
                        TextField("Any store", text: $draft.storeName).multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .store)
                            .accessibilityIdentifier("shopping.store")
                    }.id("shopping.store")
                    ShoppingStoreSuggestions(store: $draft.storeName)
                    Picker("Who will buy?", selection: $draft.memberID) {
                        Text("Anyone").tag(nil as UUID?)
                        ForEach(repository.members) { Text($0.displayName).tag(Optional($0.id)) }
                    }.accessibilityIdentifier("shopping.buyer")
                    if repository.members.isEmpty {
                        Text("Add people in More → Family to assign shopping. You can leave this as Anyone.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
        }
        if draft.kind == .meal {
            Section {
                DatePicker("Day", selection: $draft.date, displayedComponents: .date)
                Stepper("Servings: \(draft.mealServings)", value: $draft.mealServings, in: 1...20)
                TextField("Ingredient names · one per line", text: $draft.mealIngredients, axis: .vertical).focused($focusedField, equals: .ingredients).lineLimit(3...8).accessibilityIdentifier("meal.ingredients")
                DisclosureGroup("Amounts per serving · optional") {
                    Text("For one person. Use g, kg, oz, lb, ml, l or pieces. Leave blank if unknown; weekly shopping will ask you to check.").font(.footnote).foregroundStyle(.secondary)
                    ForEach(Array(Set(MealCookingRules.lines(draft.mealIngredients))).sorted(), id: \.self) { name in
                        LabeledContent(name) {
                            TextField("100 g", text: Binding(get: { draft.mealAmountsPerServing[name] ?? "" }, set: { if $0.isEmpty { draft.mealAmountsPerServing.removeValue(forKey: name) } else { draft.mealAmountsPerServing[name] = $0 } }))
                                .focused($focusedField, equals: .ingredientAmount(name)).multilineTextAlignment(.trailing).accessibilityLabel("Amount per serving for \(name)").accessibilityIdentifier("meal.amount.\(name)")
                        }
                    }
                }
                ReviewSafetyNotice(context: .meal)
                Picker("Meal", selection: $draft.mealType) {
                    ForEach(["Breakfast", "Lunch", "Dinner", "Snack"], id: \.self) { Text($0) }
                }
            }
        }
        if draft.kind == .room {
            Section {
                Picker("Floor", selection: $draft.parentID) {
                    Text("No floor").tag(nil as UUID?)
                    ForEach(repository.floors) { Text($0.name).tag(Optional($0.id)) }
                }
            }
        }
        if draft.kind == .asset {
            Section("Home item") {
                if let room = repository.rooms.first(where: { $0.id == draft.parentID }) {
                    Label("This item will be added to \(room.name)", systemImage: "door.left.hand.open")
                        .font(.subheadline).accessibilityIdentifier("item.roomContext")
                }
                Picker("Room", selection: $draft.parentID) {
                    Text("Unassigned").tag(nil as UUID?)
                    ForEach(repository.rooms) { Text($0.name).tag(Optional($0.id)) }
                }
                Picker("Category", selection: $draft.category) {
                    ForEach(AssetCategory.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
                TextField("Manufacturer", text: $draft.manufacturer).focused($focusedField, equals: .manufacturer)
                TextField("Model", text: $draft.modelNumber).focused($focusedField, equals: .model)
                TextField("Serial number", text: $draft.serialNumber).focused($focusedField, equals: .serial).textInputAutocapitalization(.never)
            }
        }
        if draft.kind == .warranty || draft.kind == .maintenance {
            Section {
                Picker("Home item", selection: $draft.parentID) {
                    Text("Select an item").tag(nil as UUID?)
                    ForEach(repository.assets) { Text($0.name).tag(Optional($0.id)) }
                }
                if repository.assets.isEmpty { Text("Choose Home Item above to add your first item, then add its warranty or maintenance.").foregroundStyle(.secondary) }
            }
        }
        if draft.kind == .maintenance {
            Section {
                Toggle("Repeat after completion", isOn: $draft.repeats)
                if draft.repeats { Stepper("Every \(draft.intervalDays) days", value: $draft.intervalDays, in: 1...3650) }
                TextField("Replacement shopping item (optional)", text: $draft.shoppingItem).focused($focusedField, equals: .shopping)
            } footer: { Text("Review and save a replacement to add it to your household shopping list.") }
        }
        if [.event, .meal, .asset, .warranty].contains(draft.kind) {
            Section("Notes") { TextField("Optional notes", text: $draft.notes, axis: .vertical).focused($focusedField, equals: .notes).lineLimit(3...8) }
        }
    }

    private func save() {
        if appleOnlyEntry {
            guard let list = connections.list(for: purpose) else { return }
            saving = true
            Task { @MainActor in
                defer { saving = false }
                do {
                    try await connections.exportReminder(ReminderExportDraft(id: reminderID, title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines), due: draft.hasDate ? draft.date : nil, purpose: purpose, appleOnly: true, notes: draft.quantity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : "Quantity: " + draft.quantity), listID: list.id)
                    dismiss()
                } catch { self.error = "Could not save to Apple Reminders. Your draft is still here. Check access and try again." }
            }
            return
        }
        do { try repository.add(draft); dismiss() }
        catch { self.error = userFacingError(error) }
    }
}

func userFacingError(_ error: Error) -> String {
    (error as? HouseholdSharingError)?.errorDescription ?? (error as? HouseholdValidation)?.errorDescription ?? (error as? LayoutError)?.errorDescription ?? "Couldn't save this change. Your previously saved data is still available. Please try again."
}

private struct SaveErrorModifier: ViewModifier {
    @Binding var message: String?
    func body(content: Content) -> some View {
        content.alert("Couldn't save", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK", role: .cancel) { message = nil }
        } message: { Text(message ?? "Please try again.") }
    }
}

extension View {
    func saveError(_ message: Binding<String?>) -> some View { modifier(SaveErrorModifier(message: message)) }
}
