import SwiftUI

/// Presentation only: household items remain local-first, with optional private sync.
struct ShoppingListView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var showingTools = false
    @State private var feedback: PurchaseFeedback?
    @State private var purchase: GroceryItem?
    @State private var adding = false
    @State private var scanningReceipt = false
    @State private var suggesting = false
    @State private var reviewingDuplicates = false
    @State private var showCompleted = false
    @State private var timingFilter = "all"
    @State private var buyerFilter = "all"
    @State private var error: String?
    @AppStorage("shopping.shelfView") private var shelfView = true
    @State private var categoryFilter: PantryCategory?
    @State private var categoryHints: [String: PantryCategory] = [:]
    @State private var organizing = false
    @State private var organizationStatus: String?
    private let organizer: any PantryCategorizationService = OnDevicePantryCategorizationService()
    private func category(_ item: GroceryItem) -> PantryCategory {
        let known = PantryVisualRules.category(item.name)
        return known == .other ? categoryHints[item.name] ?? .other : known
    }
    private func open(_ item: GroceryItem) {
        if item.isCompleted { do { try repository.toggle(item) } catch { self.error = userFacingError(error) } }
        else { purchase = item }
    }

    private func storeName(_ item: GroceryItem) -> String { repository.shoppingStoreName(for: item) }

    private var pending: [GroceryItem] { repository.groceries.filter { !$0.isCompleted } }
    private var visibleItems: [GroceryItem] { matchingItems.filter { categoryFilter == nil || category($0) == categoryFilter } }
    private var matchingItems: [GroceryItem] {
        repository.groceries.filter {
            (showCompleted || !$0.isCompleted) &&
            (timingFilter == "all" || ($0.neededLater == true) == (timingFilter == "later")) &&
            (buyerFilter == "all" || (buyerFilter == "unassigned" ? $0.assignedMemberID == nil : $0.assignedMemberID?.uuidString == buyerFilter))
        }
    }

    var body: some View {
        List {
            Section {
                header
                filters
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))

            if visibleItems.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: pending.isEmpty ? "basket" : "line.3.horizontal.decrease.circle")
                            .font(.largeTitle).foregroundStyle(AppTheme.slate).accessibilityHidden(true)
                        Text(pending.isEmpty ? "A fresh list" : "Nothing here yet").font(.title3.bold())
                        Text(pending.isEmpty ? "Add what your home needs. Check it off as you shop." : "Try another filter to see the rest of your list.")
                            .font(.subheadline).foregroundStyle(ShoppingTheme.muted).multilineTextAlignment(.center)
                        if !pending.isEmpty {
                            Button("Reset filters") { timingFilter = "all"; buyerFilter = "all"; categoryFilter = nil }
                        }
                    }.frame(maxWidth: .infinity).padding(.vertical, 24)
                }.listRowBackground(ShoppingTheme.surface)
            }
            ForEach(Array(Set(visibleItems.map { storeName($0) })).sorted(), id: \.self) { store in
                let items = visibleItems.filter { storeName($0) == store }
                Section {
                    if shelfView {
                        LazyVGrid(columns: typeSize.isAccessibilitySize ? [GridItem(.flexible(), alignment: .top)] : [GridItem(.adaptive(minimum: 155), spacing: 12, alignment: .top)], alignment: .leading, spacing: 12) {
                            ForEach(items) { item in
                                ShoppingShelfCard(item: item, category: category(item), buyer: item.assignedMemberID.map { repository.memberName($0) } ?? "Anyone can buy", store: storeName(item), atHome: repository.inventory.contains { !$0.isUsedUp && IngredientMatching.same($0.name, item.name) }, usedAI: categoryHints[item.name] != nil, open: { open(item) }, addToInventory: item.isCompleted && item.purchaseDisposition != "inventory" && !repository.inventory.contains { $0.sourceGroceryID == item.id } ? { purchase = item } : nil)
                            }
                        }.listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0)).listRowBackground(Color.clear).listRowSeparator(.hidden)
                    } else { ForEach(items) { item in itemRow(item) } }
                } header: {
                    HStack {
                        Label(store.isEmpty ? "Any store" : store, systemImage: "storefront")
                        Spacer()
                        Text(items.count, format: .number).monospacedDigit()
                    }.font(.subheadline.weight(.semibold)).textCase(nil)
                        .foregroundStyle(ShoppingTheme.ink).padding(.vertical, 6)
                }.listRowBackground(ShoppingTheme.surface)
            }
        }
        .listStyle(.insetGrouped).scrollContentBackground(.hidden).background(ShoppingTheme.canvas)
        .foregroundStyle(ShoppingTheme.ink).tint(ShoppingTheme.accent)
        .listSectionSpacing(16)
        .contentMargins(.top, 8, for: .scrollContent)
        .householdHelp(.shopping)
        .navigationTitle("Groceries")
        .featureCanvas(.shopping)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Scan receipt", systemImage: "doc.viewfinder") { scanningReceipt = true }.accessibilityIdentifier("shopping.scanReceipt") }
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink { InventoryView() } label: { Label("Inventory", systemImage: "cabinet") }
                    .accessibilityIdentifier("shopping.inventory")
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Add item", systemImage: "plus") { adding = true }.accessibilityIdentifier("shopping.add")
            }
        }
        .sheet(isPresented: $showingTools) {
            GroceryToolsSheet(title: "Shopping, organized.", identifier: "shopping", palette: .shopping,
                hasFilters: activeFilterCount > 0 || categoryFilter != nil,
                resetFilters: { timingFilter = "all"; buyerFilter = "all"; categoryFilter = nil; showCompleted = false },
                reviewDuplicates: { reviewingDuplicates = true }) {
                    GroceryToolsMenu(title: "When needed", value: timingFilter == "all" ? "All" : (timingFilter == "now" ? "Now" : "Later"),
                        symbol: "clock", identifier: "shopping.filterWhen", palette: .shopping, selection: $timingFilter) {
                            Text("All").tag("all"); Text("Now").tag("now"); Text("Later").tag("later")
                        }
                    Divider()
                    GroceryToolsMenu(title: "Buyer", value: buyerTitle, symbol: "person.crop.circle",
                        identifier: "shopping.filterBuyer", palette: .shopping, selection: $buyerFilter) {
                            Text("Everyone").tag("all"); Text("Unassigned").tag("unassigned")
                            ForEach(repository.members) { Text($0.displayName).tag($0.id.uuidString) }
                        }
                    Divider()
                    Toggle(isOn: $showCompleted) {
                        HStack(spacing: 12) {
                            GroceryToolsIcon(symbol: "checkmark.circle", palette: .shopping)
                            Text("Include bought").font(.subheadline).fixedSize(horizontal: false, vertical: true)
                        }
                    }.frame(minHeight: 56).accessibilityLabel("Include bought items")
                        .accessibilityIdentifier("shopping.showChecked")
                } organization: {
                    GroceryAIOrganizationControls(
                        hasUnfamiliarItems: pending.contains { PantryVisualRules.category($0.name) == .other },
                        hasHints: !categoryHints.isEmpty, organizing: organizing, status: organizationStatus,
                        palette: .shopping, identifier: "shopping", organize: { organizing = true },
                        reset: { organizing = false; categoryHints = [:]; organizationStatus = nil; categoryFilter = nil })
                }
                .dynamicTypeSize(typeSize)
                .sheet(isPresented: $reviewingDuplicates) { ShoppingDuplicateReview() }
        }
        .sheet(item: $purchase) { ShoppingPurchaseSheet(item: $0) { feedback = $0 } }
        .purchaseFeedback($feedback)
        .sheet(isPresented: $scanningReceipt) { if let home = repository.household?.id { ReceiptImportView(householdID: home) } }
        .sheet(isPresented: $adding) { QuickAddView(kind: .grocery, fixedKind: true) }
        .sheet(isPresented: $suggesting) {
            if let home = repository.household { ShoppingSuggestionsView(householdID: home.id) }
        }
        .task(id: organizing) {
            guard organizing else { return }
            defer { organizing = false }
            let home = repository.household?.id
            let names = Array(Set(pending.filter { PantryVisualRules.category($0.name) == .other }.map(\.name))).sorted().prefix(40).map { $0 }
            guard !names.isEmpty else {
                organizationStatus = "All items have categories. No AI changes were needed."
                return
            }
            do {
                let result = try await organizer.categorize(names)
                try Task.checkCancellation()
                guard home == repository.household?.id else { return }
                if let result {
                    for item in result where names.indices.contains(item.index) { categoryHints[names[item.index]] = item.category }
                    organizationStatus = result.isEmpty ? "No new categories were suggested." : "New categories are ready. Reset anytime."
                } else { organizationStatus = "On-device AI is unavailable. Offline shopping shelves are still available." }
            } catch { if !Task.isCancelled { organizationStatus = "AI couldn’t organize these names. Offline shopping shelves are still available." } }
        }
        .onChange(of: repository.household?.id) { _, _ in categoryHints = [:]; organizationStatus = nil; categoryFilter = nil; organizing = false }
        .saveError($error)
    }

    private var header: some View {
        GroceryShelfHeader(title: "Your next shop", summary: "\(pending.filter { $0.neededLater != true }.count) now · \(pending.filter { $0.neededLater == true }.count) later",
            artwork: "WelcomeTable", background: ShoppingTheme.hero, ink: ShoppingTheme.heroInk, muted: ShoppingTheme.heroInk.opacity(0.8))
    }

    private var activeFilterCount: Int {
        (timingFilter == "all" ? 0 : 1) + (buyerFilter == "all" ? 0 : 1) + (showCompleted ? 1 : 0)
    }
    private var filters: some View {
        VStack(alignment: .leading, spacing: 8) {
            GroceryShelfActions(identifier: "shopping", filterCount: activeFilterCount, shelves: $shelfView,
                tools: { showingTools = true }, ideas: { suggesting = true })
            GroceryCategoryFilters(categories: matchingItems.map { category($0) }, selection: $categoryFilter,
                accent: ShoppingTheme.accent, surface: ShoppingTheme.surface, ink: ShoppingTheme.ink, identifier: "shopping")
        }
    }

    private var buyerPicker: some View {
        Menu {
            Picker("Who is buying?", selection: $buyerFilter) {
                Text("Everyone").tag("all")
                Text("Unassigned").tag("unassigned")
                ForEach(repository.members) { Text($0.displayName).tag($0.id.uuidString) }
            }
        } label: {
            Label(buyerTitle, systemImage: "person.crop.circle").font(.subheadline.weight(.medium))
                .foregroundStyle(ShoppingTheme.ink).padding(.vertical, 8)
        }.accessibilityLabel("Who is buying? \(buyerTitle)").accessibilityIdentifier("shopping.filterBuyer")
    }

    private var buyerTitle: String {
        if buyerFilter == "all" { return "Everyone" }
        if buyerFilter == "unassigned" { return "Unassigned" }
        return repository.members.first { $0.id.uuidString == buyerFilter }?.displayName ?? "Everyone"
    }

    private var checkedToggle: some View {
        Button { showCompleted.toggle() } label: {
            Label(showCompleted ? "Hide bought" : "Show bought", systemImage: showCompleted ? "checkmark.circle.fill" : "checkmark.circle")
                .font(.subheadline).foregroundStyle(ShoppingTheme.muted).padding(.vertical, 8)
        }.accessibilityIdentifier("shopping.showChecked")
    }

    private func itemRow(_ item: GroceryItem) -> some View {
        Button {
            if item.isCompleted {
                do { try repository.toggle(item) } catch { self.error = userFacingError(error) }
            } else { purchase = item }
        } label: {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2).foregroundStyle(item.isCompleted ? Color.green : ShoppingTheme.muted)
                VStack(alignment: .leading, spacing: 7) {
                    Text(item.name).font(.body.weight(.semibold)).strikethrough(item.isCompleted)
                        .foregroundStyle(item.isCompleted ? ShoppingTheme.muted : ShoppingTheme.ink)
                    if item.isCompleted, let disposition = item.purchaseDisposition {
                        Label(disposition == "inventory" ? "Added to pantry" : "Purchase only", systemImage: disposition == "inventory" ? "shippingbox" : "gift")
                            .font(.caption).foregroundStyle(ShoppingTheme.muted)
                    }
                    if let quantity = item.quantityText, !quantity.isEmpty {
                        Text(quantity).font(.subheadline).foregroundStyle(ShoppingTheme.muted)
                    }
                    if item.neededLater == true, let key = item.plannedDay, let date = ShoppingEntryRules.date(for: key) {
                        Label { Text(date, format: .dateTime.month(.abbreviated).day().year()) } icon: { Image(systemName: "calendar") }
                            .font(.caption).foregroundStyle(ShoppingTheme.muted)
                    }
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) { timingBadge(item); buyerLabel(item) }
                        VStack(alignment: .leading, spacing: 6) { timingBadge(item); buyerLabel(item) }
                    }
                }
                Spacer(minLength: 0)
            }.frame(minHeight: 60).padding(.vertical, 6).contentShape(Rectangle())
        }.buttonStyle(.plain)
            .accessibilityLabel("\(item.name), \(item.quantityText ?? ""), \(item.storeName?.isEmpty == false ? item.storeName ?? "Any store" : "Any store"), \(item.assignedMemberID.map { repository.memberName($0) } ?? "Anyone can buy"), \(item.neededLater == true ? "needed later" : "needed now"), \(item.isCompleted ? "checked" : "not checked"), \(item.plannedDay ?? "")")
            .accessibilityHint(item.isCompleted ? "Reopen shopping. Existing inventory stays unchanged." : "Choose bought and add to inventory, or bought without adding.")
            .swipeActions(edge: .leading) {
                if item.isCompleted && item.purchaseDisposition != "inventory" && !repository.inventory.contains(where: { $0.sourceGroceryID == item.id }) {
                    Button("Add to pantry", systemImage: "shippingbox") { purchase = item }.tint(InventoryTheme.accent)
                }
            }
            .entryActions(.editing(item))
    }

    private func timingBadge(_ item: GroceryItem) -> some View {
        Text(item.neededLater == true ? "Later" : "Now").font(.caption.weight(.semibold))
            .foregroundStyle(item.neededLater == true ? AppTheme.clay : AppTheme.sage)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background((item.neededLater == true ? AppTheme.clay : AppTheme.sage).opacity(0.10), in: Capsule())
    }

    private func buyerLabel(_ item: GroceryItem) -> some View {
        Label(item.assignedMemberID.map { repository.memberName($0) } ?? "Anyone can buy", systemImage: "person.crop.circle")
            .font(.caption).foregroundStyle(ShoppingTheme.muted)
    }
}
