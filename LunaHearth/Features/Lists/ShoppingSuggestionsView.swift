import SwiftUI

struct ShoppingSuggestionsView: View {
    let householdID: UUID
    var service: any ShoppingSuggestionService = OnDeviceShoppingSuggestionService()
    @Environment(PublicConfigurationStore.self) private var publicStatus
    @Environment(\.aiAvailability) private var aiAvailability
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    @State private var prompt = ""
    @State private var includeHistory = true
    @State private var generation = 0
    @State private var working = false
    @State private var items: [ShoppingSuggestion] = []
    @State private var selected: Set<UUID> = []
    @State private var explanation: String?
    @State private var usedModel = false
    @State private var store = ""
    @State private var neededLater = false
    @State private var plannedDate = ShoppingEntryRules.tomorrow()
    @State private var buyer: UUID?
    @State private var error: String?
    @FocusState private var editing: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if explanation == nil { requestStep } else { reviewStep }
                }.padding(20).frame(maxWidth: 640).frame(maxWidth: .infinity)
            }.background(ShoppingTheme.canvas)
                .featureAvailability(.shoppingIdeas).navigationTitle(explanation == nil ? "Shopping ideas" : "Review your list").navigationBarTitleDisplayMode(.inline)
                .scrollDismissesKeyboard(.interactively)
                .safeAreaInset(edge: .bottom) { if publicStatus.configuration?.allows(.shoppingIdeas) ?? true { bottomAction } }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    if explanation != nil { ToolbarItem(placement: .confirmationAction) { Button("Start over") { explanation = nil; items = []; selected = [] } } }
                    ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { editing = false } }
                }
                .saveError($error)
                .task(id: generation) {
                    guard generation > 0 else { return }
                    defer { working = false }
                    guard repository.household?.id == householdID else { return }
                    let request = ShoppingSuggestionRequest(prompt: prompt,
                        recentItems: includeHistory ? repository.groceries.filter(\.isCompleted).sorted { $0.modifiedAt > $1.modifiedAt }.prefix(20).map(\.name) : [],
                        pendingItems: repository.groceries.filter { !$0.isCompleted }.map(\.name),
                        pantryItems: repository.stockedShoppingSuggestionNames)
                    do {
                        let result = try await service.suggest(request)
                        try Task.checkCancellation()
                        guard repository.household?.id == householdID else { return }
                        items = ShoppingSuggestionRules.reviewed(result.items, excluding: repository.groceries.filter { !$0.isCompleted }.map(\.name) + repository.stockedShoppingSuggestionNames)
                        selected = Set(items.map(\.id))
                        explanation = result.explanation; usedModel = result.usedModel
                    } catch is CancellationError { return }
                    catch { self.error = "Couldn’t prepare ideas. Your shopping list is unchanged." }
                }
        }
    }

    private var requestStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            HearthArtwork(name: "WelcomeTable", height: 120)
            VStack(alignment: .leading, spacing: 8) {
                Text("A good shop starts here.").font(AppTheme.displayTitle)
                Text("Tell us what you have in mind. We’ll help with the list. Items already stocked in your pantry or on your shopping list are skipped.").font(.subheadline).foregroundStyle(.secondary)
            }
            ShoppingFormCard {
                Text("What are you planning?").font(.headline)
                TextField("Breakfast for the week, a picnic, or a few essentials…", text: $prompt, axis: .vertical)
                    .focused($editing).lineLimit(3...5).shoppingInputStyle().accessibilityIdentifier("shopping.ai.prompt")
                ViewThatFits(in: .horizontal) {
                    HStack { promptChip("Weekly essentials"); promptChip("Breakfast") }
                    VStack(alignment: .leading) { promptChip("Weekly essentials"); promptChip("Breakfast") }
                }
                if prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Toggle("Use my checked items", isOn: $includeHistory).font(.subheadline).tint(AppTheme.sage)
                }
                if prompt.count > 400 { Text("Keep your request to 400 characters or fewer.").font(.caption).foregroundStyle(.red) }
            }
            Label((aiAvailability.showsAIActions && (publicStatus.configuration?.allows(.aiShopping) ?? true)) ? "On-device intelligence. Always your choice." : "Built-in list ideas. Review before adding.", systemImage: "lock.shield.fill").font(.footnote).foregroundStyle(.secondary)
            DisclosureGroup("How suggestions stay private") {
                Text("Only your request, current item names and optional checked-item names are used on this device. No cloud AI. If Apple’s model is unavailable, you’ll see clearly labeled list ideas instead.").font(.footnote).foregroundStyle(.secondary).padding(.top, 8)
            }.font(.footnote)
            if working { ProgressView("Preparing your ideas…").frame(maxWidth: .infinity).padding() }
        }.disabled(working)
    }

    private func promptChip(_ text: String) -> some View {
        Button { prompt = text; editing = false } label: {
            Text(text).font(.subheadline.weight(.medium)).padding(.horizontal, 14).padding(.vertical, 10)
                .background(AppTheme.sage.opacity(0.08), in: Capsule())
        }.buttonStyle(.plain).foregroundStyle(AppTheme.slate)
    }

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Keep what you need.").font(AppTheme.displayTitle)
                Text("Tap a circle to include an item. Edit any detail below.").font(.subheadline).foregroundStyle(.secondary)
                Label(usedModel ? "AI suggestions · review before adding" : (prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Built-in list ideas · review before adding" : "Request not generated"), systemImage: usedModel ? "sparkles" : "basket")
                    .font(.caption.weight(.semibold)).foregroundStyle(usedModel ? .purple : .secondary)
                Text(explanation ?? "").font(.caption).foregroundStyle(.secondary).accessibilityIdentifier("shopping.ai.status")
            }
            if items.isEmpty { ContentUnavailableView("No new items to add", systemImage: "basket", description: Text(usedModel ? "Matching stocked pantry items and shopping items are skipped. Add an item manually if you want extra." : "Check the explanation above. Try again, or add ingredients manually using a trusted recipe.")) }
            ForEach($items) { $item in
                ShoppingFormCard {
                    HStack(alignment: .top, spacing: 14) {
                        Button {
                            if selected.contains(item.id) { selected.remove(item.id) } else { selected.insert(item.id) }
                        } label: {
                            Image(systemName: selected.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                .font(.title).foregroundStyle(selected.contains(item.id) ? .blue : .secondary).frame(width: 44, height: 52)
                        }.buttonStyle(.plain).accessibilityLabel("Include \(item.name)")
                            .accessibilityValue(selected.contains(item.id) ? "Selected" : "Not selected")
                        VStack(alignment: .leading, spacing: 10) {
                            TextField("Item name", text: $item.name).shoppingInputStyle().accessibilityLabel("Item name")
                            TextField("Quantity · optional", text: $item.quantity).shoppingInputStyle().accessibilityLabel("Quantity")
                        }
                    }
                }
            }
            if !items.isEmpty {
                ShoppingFormCard {
                    ShoppingTimingPicker(neededLater: $neededLater, date: $plannedDate)
                    Label("One pickup plan", systemImage: "bag.fill").font(.headline)
                    Text("Apply to the items you’ve selected.").font(.caption).foregroundStyle(.secondary)
                    ShoppingStoreField(store: $store)
                    Text("Who will buy?").font(.subheadline.weight(.semibold))
                    Picker("Who will buy?", selection: $buyer) {
                        Text("Anyone").tag(nil as UUID?)
                        ForEach(repository.members) { Text($0.displayName).tag(Optional($0.id)) }
                    }.tint(.primary)
                }
            }
        }
    }

    @ViewBuilder private var bottomAction: some View {
        if explanation == nil {
            ShoppingBottomAction(title: working ? "Preparing ideas…" : "Suggest my list", detail: "You’ll review everything before adding", disabled: working || prompt.count > 400, identifier: "shopping.ai.generate") {
                editing = false; working = true; items = []; selected = []; generation += 1
            }
        } else {
            ShoppingBottomAction(title: "Add \(selected.count) items to my list", detail: "Pantry and shopping are checked again before adding.", disabled: selected.isEmpty || working, identifier: "shopping.ai.add") { save() }
        }
    }

    private func save() {
        do {
            let count = try repository.addShoppingSuggestions(items.filter { selected.contains($0.id) }, householdID: householdID, store: store, buyer: buyer, neededLater: neededLater, plannedDate: plannedDate)
            if count > 0 { dismiss() }
            else { error = "These items are already stocked in your pantry or on your shopping list. Nothing was added." }
        } catch { self.error = userFacingError(error) }
    }
}
