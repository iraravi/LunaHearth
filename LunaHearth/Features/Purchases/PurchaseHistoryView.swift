import SwiftUI

private enum PurchasePresentation {
    static func date(_ day: String) -> String {
        ShoppingEntryRules.date(for: day)?.formatted(date: .abbreviated, time: .omitted) ?? day
    }
}

struct PurchaseHistoryView: View {
    var expenseID: UUID? = nil
    var inventoryID: UUID? = nil
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var search = ""
    private var entries: [PurchaseEntry] {
        repository.purchases.filter {
            (expenseID == nil || $0.expenseID == expenseID) && (inventoryID == nil || $0.inventoryID == inventoryID) &&
            (search.isEmpty || $0.name.localizedStandardContains(search) || $0.merchant.localizedStandardContains(search))
        }
    }
    private var groups: [PurchaseEntry] {
        var seen = Set<UUID>()
        return entries.filter { seen.insert($0.purchaseID).inserted }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your purchases").font(AppTheme.sectionTitle).accessibilityAddTraits(.isHeader)
                        Text("From your shopping bag to your home.").font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "bag.fill").font(.largeTitle).foregroundStyle(ExpenseTheme.accent)
                        .padding(16).background(ExpenseTheme.accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 20)).accessibilityHidden(true)
                }.padding(.vertical, 4)
                if groups.isEmpty {
                    ContentUnavailableView(search.isEmpty ? "No purchases yet" : "No matching purchases", systemImage: "receipt",
                        description: Text(search.isEmpty ? "New receipt imports and shopping purchases will appear here." : "Try another store or item name."))
                } else {
                    Text(groups.count == 1 ? "1 purchase" : "\(groups.count) purchases").font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                    LazyVGrid(columns: typeSize.isAccessibilitySize ? [GridItem(.flexible())] : [GridItem(.adaptive(minimum: 270), spacing: 16)], spacing: 16) {
                        ForEach(groups) { group in
                            NavigationLink { PurchaseDetailView(purchaseID: group.purchaseID) } label: { historyCard(group) }
                                .buttonStyle(.plain).accessibilityIdentifier("purchase.group.\(group.purchaseID)")
                                .accessibilityHint("Opens purchased items and their expense and inventory links")
                        }
                    }
                }
            }.padding(20).frame(maxWidth: 1100).frame(maxWidth: .infinity)
        }.navigationTitle("Purchase history").navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Find a store or item")
            .background(ExpenseTheme.canvas).tint(ExpenseTheme.accent).featureCanvas(.expenses)
    }
    private func historyCard(_ group: PurchaseEntry) -> some View {
        let items = repository.purchases.filter { $0.purchaseID == group.purchaseID }
        let expense = repository.expenses.first { $0.id == group.expenseID }
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(group.merchant.isEmpty ? "Shopping purchase" : group.merchant).font(.headline)
                    Text(PurchasePresentation.date(group.day)).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.secondary).accessibilityHidden(true)
            }
            Text(items.prefix(3).map(\.name).joined(separator: ", ") + (items.count > 3 ? "…" : ""))
                .font(.subheadline).foregroundStyle(.secondary).lineLimit(typeSize.isAccessibilitySize ? nil : 2)
            Divider()
            ViewThatFits(in: .horizontal) {
                HStack { Text(items.count == 1 ? "1 item" : "\(items.count) items"); Spacer(); expenseLabel(expense) }
                VStack(alignment: .leading, spacing: 6) { Text(items.count == 1 ? "1 item" : "\(items.count) items"); expenseLabel(expense) }
            }.font(.subheadline.weight(.medium))
        }.foregroundStyle(.primary).padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .purchaseSurface(radius: 22)
            .accessibilityElement(children: .combine)
    }
    @ViewBuilder private func expenseLabel(_ expense: HouseholdExpense?) -> some View {
        if let expense { Text(ExpenseRules.money(expense.amountMinorUnits, currency: expense.currencyCode)).foregroundStyle(ExpenseTheme.accent) }
        else { Label("No expense", systemImage: "receipt").foregroundStyle(.secondary) }
    }
}

struct PurchaseDetailView: View {
    let purchaseID: UUID
    var body: some View {
        PurchaseDetailContent(purchaseID: purchaseID)
        #if DEBUG
            .modifier(UITestAppearance())
        #endif
    }
}

private struct PurchaseDetailContent: View {
    let purchaseID: UUID
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var editingExpense = false
    @State private var inventory: InventoryItem?
    private var entries: [PurchaseEntry] { repository.purchases.filter { $0.purchaseID == purchaseID } }
    private var expense: HouseholdExpense? { repository.expenses.first { expense in entries.contains { $0.expenseID == expense.id } } }
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                if let first = entries.first {
                    // Window width, not device identity, chooses the layout. Large text stays stacked.
                    if geometry.size.width >= 820 && !typeSize.isAccessibilitySize {
                        HStack(alignment: .top, spacing: 24) {
                            summary(first).frame(width: 300)
                            purchasedItems.frame(maxWidth: .infinity)
                        }.padding(24).frame(maxWidth: 1200).frame(maxWidth: .infinity)
                    } else {
                        VStack(alignment: .leading, spacing: 24) { summary(first); purchasedItems }
                            .padding(20).frame(maxWidth: 760).frame(maxWidth: .infinity)
                    }
                } else {
                    ContentUnavailableView("Purchase unavailable", systemImage: "receipt").padding(.top, 40)
                }
            }
        }.navigationTitle("Purchase details").navigationBarTitleDisplayMode(.inline)
            .background(ExpenseTheme.canvas).tint(ExpenseTheme.accent).featureCanvas(.expenses)
            .sheet(isPresented: $editingExpense) { ExpenseEditor(item: expense, purchase: expense == nil ? entries.first : nil) }
            .sheet(item: $inventory) { InventoryEditor(item: $0) }
    }
    private func summary(_ first: PurchaseEntry) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "receipt").font(.title).foregroundStyle(ExpenseTheme.accent)
                    .padding(12).background(ExpenseTheme.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 16)).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text(first.merchant.isEmpty ? "Your purchase" : first.merchant).font(AppTheme.sectionTitle).accessibilityAddTraits(.isHeader)
                    Text(PurchasePresentation.date(first.day)).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            if let expense {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Receipt total").font(.caption).foregroundStyle(.secondary)
                    Text(ExpenseRules.money(expense.amountMinorUnits, currency: expense.currencyCode)).font(AppTheme.displayTitle)
                }.accessibilityElement(children: .combine)
                Button { editingExpense = true } label: {
                    Label("View expense", systemImage: "receipt").frame(minHeight: 44)
                }.buttonStyle(.borderless).accessibilityIdentifier("purchase.expense")
            } else {
                Button { editingExpense = true } label: {
                    Label("Add expense", systemImage: "plus.circle").frame(minHeight: 44)
                }.buttonStyle(.borderless).accessibilityIdentifier("purchase.addExpense")
            }
            Divider()
            Text("\(entries.count) items · \(entries.filter { $0.inventoryID != nil }.count) added or restocked").font(.subheadline)
            DisclosureGroup("About this purchase") {
                Text(expense == nil ? "Add an expense to this purchase without stocking items again." : "The receipt total includes tax and discounts. Item totals may differ.")
                Text("Restocking clears Low stock. Review the pack amount and expiry in inventory.")
            }.font(.caption).foregroundStyle(.secondary)
        }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .purchaseSurface(radius: 24)
    }
    private var purchasedItems: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Purchased items").font(.headline).accessibilityAddTraits(.isHeader)
            LazyVStack(spacing: 12) { ForEach(entries) { entry in itemCard(entry) } }
        }
    }
    private func itemCard(_ entry: PurchaseEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                if !typeSize.isAccessibilitySize {
                    Text(PantryVisualRules.icon(entry.name, category: PantryVisualRules.category(entry.name)))
                        .font(.system(size: 32)).frame(width: 52, height: 52)
                        .background(ExpenseTheme.accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 14)).accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text(entry.name).font(.headline)
                    Text(entry.quantity.isEmpty ? "Quantity not recorded" : entry.quantity).font(.subheadline).foregroundStyle(.secondary)
                    if let amount = entry.amountMinorUnits, let currency = entry.currencyCode {
                        Text(ExpenseRules.money(amount, currency: currency) + " · item total").font(.subheadline.weight(.medium))
                    }
                }.accessibilityElement(children: .combine)
            }
            Label(entry.stockAction == "elsewhere" ? "Kept elsewhere" : entry.stockAction == "restocked" ? "Restocked" : "Added to inventory",
                  systemImage: entry.stockAction == "elsewhere" ? "gift" : "checkmark.circle").font(.subheadline).foregroundStyle(.secondary)
            if let item = repository.inventory.first(where: { $0.id == entry.inventoryID }) {
                Button { inventory = item } label: {
                    HStack { Text("View inventory"); Spacer(); Image(systemName: "arrow.up.right") }.frame(minHeight: 44)
                }.font(.subheadline.weight(.medium)).buttonStyle(.borderless)
                    .accessibilityLabel("View \(entry.name) in inventory").accessibilityIdentifier("purchase.inventory.\(entry.id)")
            } else if entry.inventoryID != nil {
                Text("Pack removed · history retained").font(.caption).foregroundStyle(.secondary)
            }
            if let grocery = repository.groceries.first(where: { $0.id == entry.groceryID }) {
                Label(grocery.isCompleted ? "Shopping · bought" : "Shopping · reopened", systemImage: "checklist").font(.caption).foregroundStyle(.secondary)
            }
        }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .purchaseSurface(radius: 20)
    }
}

private struct PurchaseSurface: ViewModifier {
    let radius: CGFloat
    @Environment(\.colorSchemeContrast) private var contrast
    func body(content: Content) -> some View {
        content.background(ExpenseTheme.surface, in: RoundedRectangle(cornerRadius: radius))
            .overlay { RoundedRectangle(cornerRadius: radius).strokeBorder(Color.primary.opacity(contrast == .increased ? 0.45 : 0.04), lineWidth: 1).allowsHitTesting(false).accessibilityHidden(true) }
    }
}
private extension View {
    func purchaseSurface(radius: CGFloat) -> some View { modifier(PurchaseSurface(radius: radius)) }
}
