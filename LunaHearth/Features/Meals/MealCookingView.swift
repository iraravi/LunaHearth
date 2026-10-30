import SwiftUI

struct MealCookingView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    let meal: MealPlanEntry
    @State private var editing = false
    @State private var shopping = false
    @State private var preparation = false
    @State private var finishing = false
    @State private var editingPack: InventoryItem?
    private var ingredients: [String] { meal.ingredientNames ?? [] }
    private var packs: [InventoryItem] { repository.inventory.filter { item in !item.isUsedUp && ingredients.contains(where: { IngredientMatching.same($0, item.name) }) } }
    private var missing: [String] { ingredients.filter { !repository.mealIngredientAvailability($0).inPantry } }
    private var toBuy: [String] { missing.filter { !repository.mealIngredientAvailability($0).inShopping } }
    private var hasShopping: Bool { ingredients.contains { repository.mealIngredientAvailability($0).inShopping } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HearthArtwork(name: "WelcomeTable", height: 110).allowsHitTesting(false)
                Text(meal.title).font(AppTheme.displayTitle)
                Label(meal.cookedAt == nil ? "\(meal.servings ?? 2) servings · \(meal.mealType)" : "Cooked", systemImage: meal.cookedAt == nil ? "fork.knife" : "checkmark.seal.fill").font(.headline)
                if let notes = meal.notes, !notes.isEmpty { Text(notes).foregroundStyle(.secondary) }
                ReviewSafetyNotice(context: .meal)
                GroupBox("Ingredients · \(ingredients.count)") {
                    VStack(alignment: .leading, spacing: 12) {
                        if ingredients.isEmpty {
                            Text("This meal has no saved ingredients yet.").foregroundStyle(.secondary)
                            Button("Add ingredients", systemImage: "plus") { editing = true }
                        }
                        ForEach(Array(ingredients.enumerated()), id: \.offset) { _, name in
                            let availability = repository.mealIngredientAvailability(name)
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: availability.symbol).font(.title2).foregroundStyle(availability.inPantry ? ShoppingTheme.accent : InventoryTheme.accent).accessibilityHidden(true)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(name).font(.headline)
                                        if let amount = PantryAmount.parse(meal.ingredientAmountsPerServing?[name]) {
                                            Text("Need \(PantryAmount(amount: amount.amount * Decimal(meal.servings ?? 2), unit: amount.unit).text) · \(amount.text) per serving").font(.caption).foregroundStyle(.secondary)
                                        }
                                        Text(availability.label).font(.caption).foregroundStyle(.secondary).accessibilityIdentifier("meal.ingredientStatus.\(name)")
                                    }
                                    Spacer(minLength: 0)
                                }
                                ForEach(packs.filter { IngredientMatching.same($0.name, name) }) { pack in
                                    Button { editingPack = pack } label: {
                                        HStack { Text(pack.quantityText ?? "Set amount remaining"); Spacer(); Image(systemName: "pencil") }.font(.subheadline).frame(minHeight: 44).contentShape(Rectangle())
                                    }.accessibilityLabel("Update pantry amount for \(pack.name)")
                                }
                            }.padding(14).frame(maxWidth: .infinity, alignment: .leading).background(InventoryTheme.canvas, in: RoundedRectangle(cornerRadius: 16))
                        }
                        Text("Check pack amounts before cooking.").font(.footnote).foregroundStyle(.secondary)
                        if !toBuy.isEmpty && meal.cookedAt == nil {
                            Button("Review missing ingredients") { shopping = true }.buttonStyle(.bordered).accessibilityIdentifier("meal.missing")
                        }
                        if hasShopping { NavigationLink { ShoppingListView() } label: { Label("View shopping list", systemImage: "checklist") }.frame(minHeight: 44).accessibilityIdentifier("meal.viewShopping") }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                GroupBox("Prep reminders") {
                    VStack(alignment: .leading, spacing: 12) {
                        if !repository.tasks.contains(where: { $0.mealID == meal.id }) {
                            Text("Add your own reminder for this meal, such as setting the table.").font(.subheadline).foregroundStyle(.secondary)
                        }
                        ForEach(repository.tasks.filter { $0.mealID == meal.id }) { TaskRow(task: $0) }
                        if meal.cookedAt == nil { Button { preparation = true } label: { Label("Add preparation reminder", systemImage: "bell.badge") }.frame(minHeight: 44).accessibilityIdentifier("meal.prep") }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                if meal.cookedAt == nil {
                    Button { finishing = true } label: { Label("Mark cooked · review pantry", systemImage: "checkmark.circle") }.hearthGlassButton(prominent: true, glassInLight: false).accessibilityIdentifier("meal.finish")
                }
            }.padding(20).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.groupBoxStyle(MealCookingGroupBoxStyle()).background(InventoryTheme.canvas).tint(InventoryTheme.accent).navigationTitle("Meal details").navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Edit", systemImage: "pencil") { editing = true } }
            .sheet(item: $editingPack) { InventoryEditor(item: $0) }
            .sheet(isPresented: $editing) { QuickAddView(draft: .editing(meal)) }
            .sheet(isPresented: $shopping) { MealMissingItemsView(meal: meal, names: missing) }
            .sheet(isPresented: $preparation) { MealPreparationView(meal: meal) }
            .sheet(isPresented: $finishing) { MealPantryReviewView(meal: meal, packs: packs) }
    }
}

private struct MealMissingItemsView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    let meal: MealPlanEntry
    let names: [String]
    @State private var selected: Set<String>
    @State private var error: String?
    private var toAdd: [String] { names.filter { selected.contains($0) && !repository.mealIngredientAvailability($0).inShopping } }
    init(meal: MealPlanEntry, names: [String]) { self.meal = meal; self.names = names; _selected = State(initialValue: Set(names)) }
    var body: some View {
        NavigationStack {
            List {
                Text("Choose what to buy. Items already on shopping are skipped.").foregroundStyle(.secondary)
                ForEach(names, id: \.self) { name in
                    if repository.mealIngredientAvailability(name).inShopping { Label("\(name) · Already in shopping", systemImage: "checkmark.circle") }
                    else { Toggle(name, isOn: Binding(get: { selected.contains(name) }, set: { if $0 { selected.insert(name) } else { selected.remove(name) } })) }
                }
            }.navigationTitle("Missing ingredients").navigationBarTitleDisplayMode(.inline).toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Add to shopping") { do { try repository.addMealShopping(meal, names: toAdd); dismiss() } catch { self.error = userFacingError(error) } }.disabled(toAdd.isEmpty).accessibilityIdentifier("meal.addMissing") }
            }.saveError($error)
        }
    }
}

private struct MealPreparationView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    let meal: MealPlanEntry
    @State private var title = ""
    @State private var due = Date.now.addingTimeInterval(3600)
    @State private var member: UUID?
    @State private var notify = false
    @State private var saved = false
    @State private var saving = false
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                TextField("e.g. Set the table", text: $title).accessibilityIdentifier("meal.prepTitle")
                DatePicker("Remind me", selection: $due, in: Date.now...)
                Picker("Who?", selection: $member) { Text("Anyone").tag(nil as UUID?); ForEach(repository.members) { Text($0.displayName).tag(Optional($0.id)) } }
                Toggle("Alert on this device", isOn: $notify)
                Text("Saved as a household task. This optional timed alert is for this device; household members can see the task when synced.").font(.footnote)
            }.scrollContentBackground(.hidden).background(InventoryTheme.canvas).tint(InventoryTheme.accent).navigationTitle("Meal preparation").navigationBarTitleDisplayMode(.inline).disabled(saving || saved).toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(saved ? "Done" : "Cancel") { dismiss() }.disabled(saving) }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || saving || saved).accessibilityIdentifier("meal.savePrep") }
            }.saveError($error)
        }
    }
    private func save() {
        saving = true
        Task {
            defer { saving = false }
            do {
                let task = try repository.addMealPrep(meal, title: title, due: due, memberID: member); saved = true
                if notify { try await MealPrepReminder().schedule(id: task.id, householdID: task.householdID, due: due) }
                dismiss()
            } catch { self.error = userFacingError(error) }
        }
    }
}

private struct MealPantryReviewView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    let meal: MealPlanEntry
    let packs: [InventoryItem]
    let mealModifiedAt: Date
    @State private var reviews: [PantryUseReview]
    @State private var error: String?
    init(meal: MealPlanEntry, packs: [InventoryItem]) {
        self.meal = meal; self.packs = packs; mealModifiedAt = meal.modifiedAt
        _reviews = State(initialValue: packs.map { PantryUseReview(id: $0.id, modifiedAt: $0.modifiedAt, unit: PantryAmount.parse($0.quantityText)?.unit ?? .g) })
    }
    var body: some View {
        NavigationStack {
            Form {
                Section { Text("Choose what changed in each pack. Unselected packs stay unchanged. This also completes the meal’s preparation tasks.") }
                ForEach($reviews) { $review in
                    if let pack = packs.first(where: { $0.id == review.id }) {
                        Section(pack.name) {
                            Text([pack.quantityText ?? "Amount unknown", pack.location, pack.expiryDay.map { "Expiry: \($0)" }].compactMap { $0 }.joined(separator: " · ")).foregroundStyle(.secondary)
                            Picker("After cooking", selection: $review.action) { ForEach(PantryUseAction.allCases) { Text($0.rawValue).tag($0) } }.accessibilityIdentifier("meal.packAction.\(pack.name)")
                            if review.action == .amount {
                                LabeledContent("Amount used") { TextField("0", text: $review.amount).keyboardType(.decimalPad).multilineTextAlignment(.trailing).accessibilityLabel("Amount used").accessibilityIdentifier("meal.usedAmount.\(pack.name)") }
                                Picker("Unit", selection: $review.unit) { ForEach(PantryUnit.allCases) { Text($0.label).tag($0) } }
                                if let current = PantryAmount.parse(pack.quantityText), let amount = PantryAmount.number(review.amount), let remaining = try? current.subtract(.init(amount: amount, unit: review.unit)) { Text("Remaining: \(remaining.text)").font(.subheadline) }
                                else { Text("Use a compatible unit and no more than the saved amount. Edit the pantry pack first if its amount is unknown.").font(.footnote) }
                            }
                        }
                    }
                }
            }.scrollContentBackground(.hidden).background(InventoryTheme.canvas).tint(InventoryTheme.accent).navigationTitle("Finish cooking").navigationBarTitleDisplayMode(.inline).toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Confirm cooked") { do { try repository.finishMeal(meal, expectedModifiedAt: mealModifiedAt, reviews: reviews); dismiss() } catch { self.error = userFacingError(error) } }.accessibilityIdentifier("meal.confirmCooked") }
            }.saveError($error)
        }
    }
}

private struct MealCookingGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            configuration.label.font(.headline)
            configuration.content
        }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(InventoryTheme.surface, in: RoundedRectangle(cornerRadius: 18))
    }
}
