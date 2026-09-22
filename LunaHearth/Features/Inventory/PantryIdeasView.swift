import SwiftUI

struct PantryIdeasView: View {
    let householdID: UUID
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    @State private var style: PantryStyle = .southIndian
    @State private var request = ""
    @State private var generated: PantryIdeas?
    @State private var selected: Set<String> = []
    @State private var generating = false
    @State private var generationID = 0
    @State private var error: String?
    @State private var search = ""
    @State private var reviewing = false
    private let service: any PantrySuggestionService = OnDevicePantrySuggestionService()
    private var existing: [String] { repository.inventory.filter { $0.householdID == householdID && !$0.isUsedUp }.map(\.name) }
    private var savedCount: Int { Set(existing.map(IngredientMatching.key)).count }
    private var names: [String] { PantrySuggestionRules.reviewed(generated?.names ?? style.starters, existing: existing) }
    private var visibleNames: [String] { names.filter { IngredientMatching.matchesSearch($0, query: search) } }
    private var groups: [PantryTemplateSection] {
        PantryCategory.allCases.compactMap { category in
            let items = visibleNames.filter { name in
                let assigned = generated?.usedModel == true ? PantryVisualRules.category(name) :
                    (style.template.first { $0.names.contains(name) }?.category ?? PantryVisualRules.category(name))
                return assigned == category
            }
            return items.isEmpty ? nil : PantryTemplateSection(category: category, names: items)
        }
    }
    private var selectionCount: Int { selected.intersection(Set(names)).count }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
            List {
                Section {
                    Image("EditorialPantry").resizable().scaledToFill().frame(height: 130).clipped().clipShape(RoundedRectangle(cornerRadius: 18)).accessibilityHidden(true)
                    Text("Set up your kitchen").font(AppTheme.sectionTitle)
                    Text("Choose a kitchen template, select the ingredients you have, then review and add them together.").font(.subheadline).foregroundStyle(InventoryTheme.muted)
                    Label(savedCount == 1 ? "1 ingredient saved in this home" : "\(savedCount) ingredients saved in this home", systemImage: "cabinet")
                        .font(.subheadline).foregroundStyle(InventoryTheme.muted).accessibilityIdentifier("inventory.savedCount")
                    Picker("Kitchen template", selection: $style) { ForEach(PantryStyle.allCases) { Text($0.rawValue).tag($0) } }
                        .accessibilityIdentifier("inventory.ideasStyle")
                    TextField("Describe what you want, e.g. South Indian breakfast staples", text: $request, axis: .vertical).lineLimit(2...3)
                        .accessibilityIdentifier("inventory.ideasRequest")
                        .onChange(of: request) { _, value in if value.count > 300 { request = String(value.prefix(300)) } }
                    Button { generating = true; generationID += 1 } label: { Label(generating ? "Thinking on your device…" : "Tailor with on-device AI", systemImage: "sparkles") }
                        .disabled(generating).accessibilityIdentifier("inventory.generateIdeas")
                    if generating {
                        ProgressView("Making suggestions…").accessibilityIdentifier("inventory.ideasProgress")
                    }

                }.listRowBackground(InventoryTheme.surface)
                if let generated {
                    Section {
                        Label(generated.usedModel ? "AI result" : "Using starter ideas", systemImage: generated.usedModel ? "sparkles" : "info.circle")
                            .font(.headline).id("pantry.results")
                        ReviewSafetyNotice(context: .pantry)
                        Text(generated.outcome.explanation).font(.subheadline)
                            .accessibilityIdentifier("inventory.ideasStatus")
                    }.listRowBackground(InventoryTheme.surface)
                }
                Section {
                    TextField("Find an ingredient", text: $search).accessibilityIdentifier("inventory.templateSearch")
                    HStack {
                        Button("Select all \(visibleNames.count)") { selected.formUnion(visibleNames) }
                            .accessibilityIdentifier("inventory.selectAllIdeas").disabled(visibleNames.isEmpty)
                        Spacer()
                        Button("Clear") { selected = [] }.disabled(selected.isEmpty)
                            .accessibilityIdentifier("inventory.clearIdeas")
                    }
                    Text("\(selectionCount) selected · \(names.count) available · \(savedCount) saved at home")
                        .font(.subheadline).accessibilityIdentifier("inventory.templateCount")
                    Text("Templates are ready-made checklists, not a record of what you own.")
                        .font(.caption).foregroundStyle(InventoryTheme.muted)
                    if names.isEmpty {
                        Text(generated?.outcome == .noNewIdeas ? "No new suggestions. Change your request or choose another style." : "All suggestions in this style match saved ingredients. Choose another style or add an item manually.")
                    }
                } header: { Text(generated?.usedModel == true ? "AI suggestions" : "Starter suggestions") }
                    .listRowBackground(InventoryTheme.surface)
                ForEach(groups) { group in
                    Section {
                        Button {
                            if Set(group.names).isSubset(of: selected) { selected.subtract(group.names) }
                            else { selected.formUnion(group.names) }
                        } label: {
                            Label(Set(group.names).isSubset(of: selected) ? "Clear this category" : "Select this category", systemImage: "checklist")
                        }.accessibilityIdentifier("inventory.selectCategory.\(group.category.rawValue)")
                        ForEach(group.names, id: \.self) { name in
                            Button { if !selected.insert(name).inserted { selected.remove(name) } } label: {
                                HStack {
                                    Image(systemName: selected.contains(name) ? "checkmark.circle.fill" : "circle")
                                    Text(name).foregroundStyle(InventoryTheme.ink)
                                    Spacer()
                                }.frame(minHeight: 44).contentShape(Rectangle())
                            }.buttonStyle(.plain).accessibilityIdentifier("inventory.idea.\(name)")
                                .accessibilityAddTraits(selected.contains(name) ? .isSelected : [])
                        }
                    } header: { Text("\(group.category.icon) \(group.category.title) · \(group.names.count)") }
                        .listRowBackground(InventoryTheme.surface)
                }
            }.scrollContentBackground(.hidden).background(InventoryTheme.canvas).tint(InventoryTheme.accent)
                .navigationTitle("Pantry ideas").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Review \(selectionCount)") { reviewing = true }
                            .disabled(selectionCount == 0).accessibilityIdentifier("inventory.addIdeas")
                    }
                }
                .onChange(of: style) { _, _ in generated = nil; selected = []; search = ""; generating = false; generationID += 1 }
                .onChange(of: repository.household?.id) { _, id in if id != householdID { dismiss() } }
                .task(id: generationID) {
                    guard generating else { return }
                    let currentGeneration = generationID
                    do {
                        let result = try await service.suggest(style: style, request: request, existing: existing)
                        try Task.checkCancellation()
                        guard currentGeneration == generationID else { return }
                        generated = result; selected = []; generating = false
                    } catch {
                        guard !Task.isCancelled, currentGeneration == generationID else { return }
                        generating = false
                        self.error = "Couldn’t tailor ideas. The starter list is still available."
                    }
                }
                .onChange(of: generating) { _, busy in
                    if !busy, generated != nil {
                        withAnimation { proxy.scrollTo("pantry.results", anchor: .top) }
                    }
                }
                .sheet(isPresented: $reviewing) {
                    PantryTemplateReviewView(householdID: householdID, names: names, selected: $selected) { dismiss() }
                }
                .saveError($error)
            }
        }
    }
}

private struct PantryTemplateReviewView: View {
    let householdID: UUID
    let names: [String]
    @Binding var selected: Set<String>
    let onAdded: () -> Void
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    @State private var error: String?
    private var eligible: [String] {
        PantrySuggestionRules.reviewed(names.filter { selected.contains($0) }, existing:
            repository.inventory.filter { $0.householdID == householdID && !$0.isUsedUp }.map(\.name))
    }
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("\(eligible.count) ingredients to add", systemImage: "cabinet").font(AppTheme.sectionTitle)
                    Text("Keep only what is actually at home. Amounts, stores and expiry dates can be added later.")
                        .foregroundStyle(InventoryTheme.muted)
                    Text("Already-saved ingredients are skipped automatically. Nothing is added until you confirm.")
                        .font(.caption).foregroundStyle(InventoryTheme.muted)
                }.listRowBackground(InventoryTheme.surface)
                Section("Your selection") {
                    ForEach(eligible, id: \.self) { name in
                        HStack {
                            Text(name)
                            Spacer()
                            Button { selected.remove(name) } label: { Image(systemName: "minus.circle").frame(minWidth: 44, minHeight: 44) }
                                .accessibilityLabel("Remove \(name)").accessibilityIdentifier("inventory.reviewRemove.\(name)")
                        }
                    }
                    if eligible.isEmpty { Text("Nothing new to add. Go back to choose ingredients.") }
                }.listRowBackground(InventoryTheme.surface)
            }.scrollContentBackground(.hidden).background(InventoryTheme.canvas).tint(InventoryTheme.accent)
                .navigationTitle("Review pantry").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Back") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add \(eligible.count)") {
                            do { try repository.addPantryIdeas(eligible, householdID: householdID); onAdded() }
                            catch { self.error = error.localizedDescription }
                        }.disabled(eligible.isEmpty).accessibilityIdentifier("inventory.confirmIdeas")
                    }
                }.saveError($error)
        }
    }
}
