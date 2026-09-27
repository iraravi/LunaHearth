import SwiftUI

enum InventoryTheme {
    static let canvas = Color("InventoryCanvas"), surface = Color("InventorySurface")
    static let accent = Color("InventoryAccent"), ink = Color("InventoryInk"), muted = Color("InventoryMuted")
}

struct InventoryView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var showingTools = false
    @State private var adding = false
    @State private var scanningReceipt = false
    @State private var scanningPhoto = false
    @State private var ideas = false
    @State private var reviewingDuplicates = false
    @State private var editing: InventoryItem?
    @State private var search = ""
    @State private var filter = "home"
    @AppStorage("inventory.shelfView") private var shelfView = true
    @State private var selectedCategory: PantryCategory?
    @State private var categoryHints: [String: PantryCategory] = [:]
    @State private var organizing = false
    @State private var organizationStatus: String?
    private let organizer: any PantryCategorizationService = OnDevicePantryCategorizationService()
    @State private var error: String?
    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            content(now: timeline.date)
        }
        .featureCanvas(.pantry)
        .sheet(isPresented: $showingTools) {
            GroceryToolsSheet(title: "Pantry, organized.", identifier: "inventory", palette: .inventory,
                hasFilters: filter != "home" || selectedCategory != nil || !search.isEmpty,
                resetFilters: { filter = "home"; selectedCategory = nil; search = "" },
                reviewDuplicates: { reviewingDuplicates = true }) {
                    GroceryToolsMenu(title: "Inventory", value: filterTitle, symbol: "cabinet",
                        identifier: "inventory.filter", palette: .inventory, selection: $filter) {
                            Text("At home").tag("home"); Text("Check dates").tag("dates")
                            Text("Low stock").tag("low"); Text("Used up").tag("used")
                        }
                    InventoryAttentionSummary(items: repository.inventory.filter { !$0.isUsedUp }) { filter = $0; selectedCategory = nil }
                } organization: {
                    aiOrganization(repository.inventory.filter { !$0.isUsedUp })
                }
                .dynamicTypeSize(typeSize)
                .sheet(isPresented: $reviewingDuplicates) { InventoryDuplicateReview() }
        }
        .sheet(isPresented: $scanningReceipt) { if let home = repository.household?.id { ReceiptImportView(householdID: home) } }
        .sheet(isPresented: $scanningPhoto) { if let home = repository.household?.id { PantryPhotoImportView(householdID: home).dynamicTypeSize(typeSize) } }
        .sheet(isPresented: $adding) { InventoryEditor() }
        .sheet(item: $editing) { InventoryEditor(item: $0) }
        .sheet(isPresented: $ideas) { if let home = repository.household?.id { PantryIdeasView(householdID: home) } }
        .task(id: organizing) {
            guard organizing else { return }
            defer { organizing = false }
            let home = repository.household?.id
            let names = Array(Set(repository.inventory.filter { !$0.isUsedUp && PantryVisualRules.category($0.name) == .other }.map(\.name))).sorted().prefix(40).map { $0 }
            guard !names.isEmpty else {
                organizationStatus = "All items have categories. No AI changes were needed."
                return
            }
            do {
                let results = try await organizer.categorize(names)
                try Task.checkCancellation()
                guard repository.household?.id == home else { return }
                if let results {
                    for result in results where names.indices.contains(result.index) { categoryHints[names[result.index]] = result.category }
                    organizationStatus = results.isEmpty ? "No new categories were suggested." : "New categories are ready. Reset anytime."
                } else { organizationStatus = "On-device AI is unavailable. Your visual pantry still works with offline categories." }
            } catch { if !Task.isCancelled { organizationStatus = "Couldn’t organize with AI. Your offline categories are still available." } }
        }
        .onChange(of: repository.household?.id) { _, _ in categoryHints = [:]; organizationStatus = nil; selectedCategory = nil; organizing = false }
        .saveError($error)
    }
    private func pantryTitle(_ active: [InventoryItem]) -> some View {
        GroceryShelfHeader(title: "Your pantry", summary: "\(Set(active.map { IngredientMatching.key($0.name) }).count) ingredients · \(active.count) packs",
            artwork: "EditorialPantry", background: InventoryTheme.accent.opacity(0.08), ink: InventoryTheme.ink,
            muted: InventoryTheme.muted, summaryIdentifier: "inventory.count")
    }
    private func categoryFilters(_ matching: [InventoryItem]) -> some View {
        GroceryCategoryFilters(categories: matching.map { InventoryShelf.category($0, hints: categoryHints) },
            selection: $selectedCategory, accent: InventoryTheme.accent, surface: InventoryTheme.surface,
            ink: InventoryTheme.ink, identifier: "inventory")
    }
    private func aiOrganization(_ active: [InventoryItem]) -> some View {
        GroceryAIOrganizationControls(
            hasUnfamiliarItems: active.contains { PantryVisualRules.category($0.name) == .other },
            hasHints: !categoryHints.isEmpty, organizing: organizing, status: organizationStatus,
            palette: .inventory, identifier: "inventory", organize: { organizing = true },
            reset: { organizing = false; categoryHints = [:]; organizationStatus = nil; selectedCategory = nil })
    }
    private var filterTitle: String {
        switch filter {
        case "dates": "Check dates"
        case "low": "Low stock"
        case "used": "Used up"
        default: "At home"
        }
    }
    private func pantryHeader(active: [InventoryItem], matching: [InventoryItem]) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                if search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                pantryTitle(active)
                if typeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 8) {
                        Button("Scan receipt", systemImage: "doc.viewfinder") { scanningReceipt = true }
                            .frame(minHeight: 44).accessibilityIdentifier("inventory.scanReceipt")
                        Button("Add item", systemImage: "plus") { adding = true }
                            .frame(minHeight: 44).accessibilityLabel("Add inventory item").accessibilityIdentifier("inventory.add")
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                GroceryShelfActions(identifier: "inventory", filterCount: filter == "home" ? 0 : 1, shelves: $shelfView,
                    tools: { showingTools = true }, ideas: { ideas = true })
                Button(typeSize.isAccessibilitySize ? "Kitchen photo" : "Add from kitchen photo", systemImage: "camera.viewfinder") { scanningPhoto = true }
                    .font(.subheadline).fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 44).accessibilityLabel("Add from kitchen photo").accessibilityIdentifier("inventory.scanPhoto")
                } else {
                    Text(matching.count == 1 ? "1 matching item" : "\(matching.count) matching items")
                        .font(.headline).accessibilityIdentifier("inventory.searchCount")
                }
                categoryFilters(matching)
            }.buttonStyle(.borderless)
        }.listRowBackground(Color.clear).listRowSeparator(.hidden).listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 12, trailing: 0))
    }
    private func content(now: Date) -> some View {
        let active = repository.inventory.filter { !$0.isUsedUp }
        let matching = repository.inventory.filter {
            (filter == "used" ? $0.isUsedUp : !$0.isUsedUp) &&
            (filter != "dates" || InventoryRules.needsDateAttention($0.expiryDay, today: now)) &&
            (filter != "low" || $0.isLowStock == true) &&
            IngredientMatching.matchesSearch($0.name, query: search)
        }
        let visible = matching.filter { selectedCategory == nil || InventoryShelf.category($0, hints: categoryHints) == selectedCategory }
        return List {
            pantryHeader(active: active, matching: matching)
            if visible.isEmpty {
                ContentUnavailableView(filter == "home" && search.isEmpty ? "Start with what you have" : "Nothing here yet", systemImage: "cabinet",
                    description: Text(filter == "home" && search.isEmpty ? "Choose starter ideas or add an item. Only its name is required." : "Try another filter or add more items."))
                    .listRowBackground(InventoryTheme.surface)
                if active.isEmpty && filter == "home" && search.isEmpty && selectedCategory == nil {
                    Button("Choose pantry starter items", systemImage: "lightbulb") { ideas = true }
                        .frame(minHeight: 44).accessibilityIdentifier("inventory.empty.start")
                        .listRowBackground(InventoryTheme.surface)
                }
            }
            if shelfView {
                InventoryShelf(items: visible, hints: categoryHints, now: now) { editing = $0 }
            } else {
            ForEach(visible) { item in
                Button { editing = item } label: {
                    HStack(spacing: 14) {
                        Image(systemName: item.isUsedUp ? "checkmark.circle" : "shippingbox")
                            .font(.title2).foregroundStyle(InventoryTheme.accent).frame(width: 42).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.name).font(.headline).foregroundStyle(InventoryTheme.ink)
                            if let quantity = item.quantityText { Text(quantity).font(.subheadline).foregroundStyle(InventoryTheme.muted) }
                            InventoryStatusBadges(item: item, today: HouseholdDay(now).key)
                            if let location = item.location { Text(location).font(.caption).foregroundStyle(InventoryTheme.muted) }
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(InventoryTheme.muted)
                    }.frame(minHeight: 58).padding(.vertical, 5).contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityIdentifier("inventory.item.\(item.name)")
                    .listRowBackground(InventoryTheme.surface)
            }
            }
            Section {
                NavigationLink { ShoppingListView() } label: { Label("Open shopping list", systemImage: "cart") }
            } footer: { Text("Dates come from the pack details you enter. Missing dates stay unknown. Inventory works offline and syncs with your home when iCloud is enabled.") }
        }
        .scrollContentBackground(.hidden).background(InventoryTheme.canvas).tint(InventoryTheme.accent)
        .householdHelp(.pantry)
        .navigationTitle("Groceries at home").navigationBarTitleDisplayMode(.inline)
        .searchable(text: $search, prompt: "Find an ingredient")
        .onChange(of: search) { _, _ in selectedCategory = nil }
        .toolbar {
            if !typeSize.isAccessibilitySize {
            ToolbarItem(placement: .topBarTrailing) { Button("Scan receipt", systemImage: "doc.viewfinder") { scanningReceipt = true }.labelStyle(.iconOnly).accessibilityLabel("Scan receipt").accessibilityIdentifier("inventory.scanReceipt") }
            ToolbarItem(placement: .primaryAction) { Button("Add item", systemImage: "plus") { adding = true }.labelStyle(.iconOnly).accessibilityLabel("Add inventory item").accessibilityIdentifier("inventory.add") }
            }
        }
    }
}

struct InventoryEditor: View {
    @Environment(PublicConfigurationStore.self) private var publicStatus
    @Environment(\.aiAvailability) private var aiAvailability
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    private enum Field: Hashable { case name, quantity, pack, location, store }
    @FocusState private var focused: Field?
    @FocusState private var quantityFocused: Bool
    @State private var draft: InventoryDraft
    @State private var error: String?
    @State private var deleting = false
    @State private var separatePack = false
    @State private var checking = false
    @State private var aiMatches: Set<UUID> = []
    @State private var aiStatus: String?
    private let comparison: any IngredientComparisonService = OnDeviceIngredientComparisonService()
    private var candidates: [InventoryItem] { repository.inventory.filter { !$0.isUsedUp && $0.id != item?.id } }
    private var matches: [InventoryItem] {
        candidates.filter { IngredientMatching.same($0.name, draft.name) || IngredientMatching.possibleTypo($0.name, draft.name) || aiMatches.contains($0.id) }
    }
    private let item: InventoryItem?
    init(item: InventoryItem? = nil) { self.item = item; _draft = State(initialValue: item.map(InventoryDraft.init) ?? InventoryDraft()) }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(item == nil ? "Make room for something good." : "Your pack, your details.", systemImage: "shippingbox").font(.title3.bold())
                        Text("Only the item name is required.").font(.subheadline).foregroundStyle(InventoryTheme.muted)
                    }.padding(.vertical, 6)
                    TextField("Item name (required)", text: $draft.name).focused($focused, equals: .name).accessibilityIdentifier("inventory.name")
                    Toggle("Running low", isOn: $draft.isLowStock).accessibilityIdentifier("inventory.lowStock")
                    Text("Mark this when supplies are low. Restocking clears it; stock use is reviewed when you cook.").font(.caption).foregroundStyle(InventoryTheme.muted)
                }.listRowBackground(InventoryTheme.surface)
                if !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !candidates.isEmpty {
                    Section {
                        ForEach(matches) { match in
                            VStack(alignment: .leading, spacing: 5) {
                                Label(IngredientMatching.same(match.name, draft.name) ? "Already at home: \(match.name)" : "Possibly the same: \(match.name)", systemImage: "square.on.square")
                                    .font(.headline)
                                Text([match.quantityText, match.packDetails, match.location, match.expiryDay.map { "Expiry: \($0)" }].compactMap { $0 }.joined(separator: " · ")).font(.caption)
                            }.accessibilityIdentifier("inventory.duplicateWarning")
                        }
                        if !matches.isEmpty {
                            Button("Keep existing item") { dismiss() }.accessibilityIdentifier("inventory.keepExisting")
                            Toggle("This is a separate pack or ingredient", isOn: $separatePack).accessibilityIdentifier("inventory.separatePack")
                        }
                        if (aiAvailability.showsAIActions && (publicStatus.configuration?.allows(.aiDuplicates) ?? true)) {
                            Button(checking ? "Comparing on your device…" : "Check similar names with AI", systemImage: "sparkles") { checking = true }
                                .disabled(checking).accessibilityIdentifier("inventory.compareAI")
                        }
                        if let aiStatus { Text(aiStatus).font(.caption).foregroundStyle(InventoryTheme.muted) }
                    } footer: {
                        Text((aiAvailability.showsAIActions && (publicStatus.configuration?.allows(.aiDuplicates) ?? true)) ? "Names and regional aliases are checked offline. AI can suggest other matches for review. Separate packs keep their own amounts and dates." : "Names and regional aliases are checked offline. Separate packs keep their own amounts and dates.")
                    }.listRowBackground(InventoryTheme.surface)
                }
                Section {
                    DisclosureGroup {
                        PantryQuantityInput(amount: $draft.measuredAmount, unit: $draft.measuredUnit, custom: $draft.quantity, focused: $quantityFocused)
                        TextField("Pack size / brand", text: $draft.packDetails).focused($focused, equals: .pack).accessibilityIdentifier("inventory.pack")
                        TextField("Storage · e.g. pantry or fridge", text: $draft.location).focused($focused, equals: .location).accessibilityIdentifier("inventory.location")
                        TextField("Store", text: $draft.storeName).focused($focused, equals: .store).accessibilityIdentifier("inventory.store")
                        ShoppingStoreBrowseButton(store: $draft.storeName)
                        Toggle("Packed date", isOn: $draft.hasPackedDate).accessibilityIdentifier("inventory.hasPackedDate")
                        if draft.hasPackedDate { DatePicker("Packed on", selection: $draft.packedDate, displayedComponents: .date) }
                        Toggle("Expiry date", isOn: $draft.hasExpiryDate).accessibilityIdentifier("inventory.hasExpiryDate")
                        if draft.hasExpiryDate { DatePicker("Expires on", selection: $draft.expiryDate, displayedComponents: .date).accessibilityIdentifier("inventory.expiryDate") }
                        Toggle("Purchased date", isOn: $draft.hasPurchasedDate)
                        if draft.hasPurchasedDate { DatePicker("Purchased on", selection: $draft.purchasedDate, displayedComponents: .date) }
                    } label: { Text("Add details (optional)").accessibilityIdentifier("inventory.details") }
                }.listRowBackground(InventoryTheme.surface)
                if let item {
                    Section {
                        Button(item.isUsedUp ? "Mark as at home" : "Mark as used up", systemImage: item.isUsedUp ? "shippingbox" : "checkmark.circle") {
                            do { try repository.setInventoryUsedUp(item, usedUp: !item.isUsedUp); dismiss() } catch { self.error = error.localizedDescription }
                        }.accessibilityIdentifier("inventory.usedUp")
                        Button("Add to shopping", systemImage: "cart.badge.plus") {
                            do { try repository.restockInventory(item); dismiss() } catch { self.error = error.localizedDescription }
                        }.accessibilityIdentifier("inventory.restock")
                        NavigationLink { PurchaseHistoryView(inventoryID: item.id) } label: { Label("Purchase & restock history", systemImage: "clock.arrow.circlepath") }
                            .accessibilityIdentifier("inventory.purchases")
                        Button("Delete this pack", role: .destructive) { deleting = true }
                    } footer: { Text("Each entry is a pack or batch. Add a separate entry for a different expiry date. Buying again starts a new shopping item.") }
                }
            }.scrollContentBackground(.hidden).background(InventoryTheme.canvas).tint(InventoryTheme.accent)
                .navigationTitle(item == nil ? "Add to inventory" : item?.name ?? "Item").navigationBarTitleDisplayMode(.inline)
                .scrollDismissesKeyboard(.interactively)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { focused = nil; quantityFocused = false }.accessibilityIdentifier("inventory.keyboardDone") }
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            do { try repository.saveInventory(draft, editing: item?.id, allowSeparatePack: separatePack); dismiss() } catch { self.error = error.localizedDescription }
                        }.disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (!matches.isEmpty && !separatePack)).accessibilityIdentifier("inventory.save")
                    }
                }
                .onChange(of: draft.name) { _, _ in checking = false; aiMatches = []; aiStatus = nil; separatePack = false }
                .task(id: checking) {
                    guard checking else { return }
                    defer { checking = false }
                    let name = draft.name
                    let snapshot = Array(candidates.prefix(60).map { ($0.id, $0.name) })
                    do {
                        let result = try await comparison.compare(name: name, candidates: snapshot.map { $0.1 })
                        try Task.checkCancellation()
                        guard name == draft.name else { return }
                        aiMatches = Set(result.matchingIndices.compactMap { snapshot.indices.contains($0) ? snapshot[$0].0 : nil })
                        aiStatus = result.usedModel ? "AI checked up to 60 active packs. Possible matches need your review; an empty result is not a guarantee." : "On-device AI is unavailable. Offline name and alias checks are still active."
                    } catch { if !Task.isCancelled { aiStatus = "AI comparison couldn’t finish. Offline checks are still active." } }
                }
                .confirmationDialog("Delete this inventory pack?", isPresented: $deleting) {
                    Button("Delete pack", role: .destructive) {
                        guard let item else { return }
                        do { try repository.deleteInventory(item); dismiss() } catch { self.error = error.localizedDescription }
                    }
                } message: { Text("This removes the pack from this household’s inventory. The shopping history stays.") }
                .saveError($error)
        }
        #if DEBUG
        .modifier(UITestAppearance())
        #endif
    }
}
