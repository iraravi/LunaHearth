import SwiftUI

enum TodayPriority: String, CaseIterable, Identifiable {
    case buy = "Buy", dates = "Use soon", restock = "Restock"
    var id: String { rawValue }
    var key: String { switch self { case .buy: "buy"; case .dates: "dates"; case .restock: "restock" } }
    var symbol: String { switch self { case .buy: "basket"; case .dates: "clock"; case .restock: "arrow.triangle.2.circlepath" } }
}

@MainActor struct TodayAttentionData {
    let shopping: [AssignedShoppingItem]
    let dates: [TodayPantryItem]
    let restock: [TodayPantryItem]
    let memberName: String?
    init(repository: LocalHouseholdRepository, personal: PersonalShopping, now: Date) {
        let memberID = repository.household.flatMap { personal.memberID($0.id) }
        let member = repository.members.first { $0.id == memberID }
        memberName = member?.displayName
        let items = repository.groceries.filter { !$0.isCompleted && (member == nil || $0.assignedMemberID == memberID) }.map {
            AssignedShoppingItem(id: $0.id, name: $0.name, quantity: $0.quantityText ?? "", store: repository.shoppingStoreName(for: $0), later: $0.neededLater == true, day: $0.plannedDay)
        }
        let packs = repository.inventory.map {
            TodayPantryItem(id: $0.id, name: $0.name, expiryDay: $0.expiryDay, isUsedUp: $0.isUsedUp, isLowStock: $0.isLowStock == true)
        }
        shopping = TodayAttentionRules.shopping(items, today: HouseholdDay(now).key)
        dates = TodayAttentionRules.dates(packs, today: HouseholdDay(now).key)
        restock = TodayAttentionRules.restock(packs)
    }
    func count(_ priority: TodayPriority) -> Int {
        switch priority { case .buy: shopping.count; case .dates: dates.count; case .restock: restock.count }
    }
}

struct TodayPriorities: View {
    let now: Date
    let wide: Bool
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(PersonalShopping.self) private var personal
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var selection: TodayPriority
    @State private var expanded: TodayPriority?
    var body: some View {
        let data = TodayAttentionData(repository: repository, personal: personal, now: now)
        VStack(alignment: .leading, spacing: 12) {
            (dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4)) : AnyLayout(HStackLayout(spacing: 8))) {
                Text("Pantry & shopping").font(.title3.bold())
                if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 8) }
                NavigationLink { PersonalShoppingView() } label: {
                    Label(data.memberName ?? "For you", systemImage: "person.crop.circle")
                        .font(.caption.weight(.medium)).frame(minHeight: 44)
                }.accessibilityIdentifier("today.personalShopping")
            }
            if wide {
                TodayAlignedCards(columns: 3) {
                    ForEach(TodayPriority.allCases) { priority in panel(priority, data: data) }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(TodayPriority.allCases) { priority in
                            Button { selection = priority } label: {
                                HStack(spacing: 6) {
                                    Text(priority.rawValue)
                                    Text(data.count(priority), format: .number).monospacedDigit()
                                }.font(.subheadline.weight(.semibold)).padding(.horizontal, 14).frame(minHeight: 44)
                                    .background(selection == priority ? TodayTheme.accent : TodayTheme.surface, in: Capsule())
                                    .foregroundStyle(selection == priority ? TodayTheme.canvas : TodayTheme.ink)
                            }.buttonStyle(.plain).accessibilityIdentifier("today.priority.\(priority.key)")
                                .accessibilityAddTraits(selection == priority ? .isSelected : [])
                        }
                    }
                }
                panel(selection, data: data)
            }
        }
        .sheet(item: $expanded) { priority in
            NavigationStack {
                TimelineView(.periodic(from: .now, by: 60)) { timeline in
                    ScrollView {
                        TodayCard { TodayPriorityItems(priority: priority, now: timeline.date, limit: nil) }.padding(20)
                    }.background(TodayTheme.canvas)
                }.navigationTitle(priority == .dates ? "Pantry dates" : priority.rawValue)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { expanded = nil } } }
            }.tint(TodayTheme.accent)
        }
    }

    private func panel(_ priority: TodayPriority, data: TodayAttentionData) -> some View {
        TodayCard {
            HStack {
                TodaySectionHeading(title: priority.rawValue, symbol: priority.symbol)
                Spacer(minLength: 0)
                if data.count(priority) > 3 {
                    Button("All \(data.count(priority))") { expanded = priority }
                        .font(.caption.weight(.semibold)).frame(minHeight: 44)
                        .accessibilityIdentifier("today.all.\(priority.key)")
                }
            }
            TodayPriorityItems(priority: priority, now: now, limit: 3)
        }.accessibilityElement(children: .contain).accessibilityIdentifier("today.panel.\(priority.key)")
    }
}

struct TodayPriorityItems: View {
    let priority: TodayPriority
    let now: Date
    let limit: Int?
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(PersonalShopping.self) private var personal
    @State private var feedback: PurchaseFeedback?
    @State private var purchase: GroceryItem?
    @State private var editing: InventoryItem?
    @State private var error: String?
    private var readOnly: Bool { repository.syncConfiguration?.readOnly == true || repository.syncConfiguration?.recovery == true }
    private var day: String { HouseholdDay(now).key }

    var body: some View {
        let data = TodayAttentionData(repository: repository, personal: personal, now: now)
        VStack(alignment: .leading, spacing: 14) {
            Text(priority == .buy ? (data.memberName.map { "Needed now · For \($0)" } ?? "Needed now · Household shopping") : priority == .dates ? "Recorded expiry dates · Next 7 days and past due" : "Marked low at home · One entry per ingredient")
                .font(.caption).foregroundStyle(TodayTheme.muted).fixedSize(horizontal: false, vertical: true)
            if readOnly { Text("This shared home is read-only. You can browse its items.").font(.caption).foregroundStyle(TodayTheme.muted) }
            if data.count(priority) == 0 {
                Label(emptyText, systemImage: "checkmark.circle")
                    .font(.subheadline).foregroundStyle(TodayTheme.muted).padding(.vertical, 10)
            }
            switch priority {
            case .buy:
                ForEach(Array(data.shopping.prefix(limit ?? data.shopping.count))) { item in
                    let buyer = repository.groceries.first { $0.id == item.id }?.assignedMemberID.map { repository.memberName($0) } ?? "Anyone can buy"
                    let detail = [item.quantity, item.store.isEmpty ? "Any store" : item.store, data.memberName == nil ? buyer : ""].filter { !$0.isEmpty }.joined(separator: " · ")
                    Button {
                        purchase = repository.groceries.first { $0.id == item.id }
                    } label: {
                        itemRow(name: item.name, detail: detail, status: TodayAttentionRules.isOverdue(item, today: day) ? "Overdue purchase" : "Needed now", warning: TodayAttentionRules.isOverdue(item, today: day), symbol: "circle")
                    }.buttonStyle(.plain).disabled(readOnly)
                        .accessibilityLabel("Finish shopping for \(item.name)")
                        .accessibilityValue("\(detail), \(TodayAttentionRules.isOverdue(item, today: day) ? "overdue purchase" : "needed now")")
                        .accessibilityIdentifier("today.buy.\(item.name)")
                }
                NavigationLink { ShoppingListView() } label: { footer("Open shopping") }
            case .dates:
                ForEach(Array(data.dates.prefix(limit ?? data.dates.count))) { item in
                    Button { editing = repository.inventory.first { $0.id == item.id } } label: {
                        itemRow(name: item.name, detail: InventoryRules.expiryLabel(item.expiryDay, today: day), status: InventoryRules.expiryState(item.expiryDay, today: day) == .past ? "Past expiry · Check item" : "Check date", warning: InventoryRules.expiryState(item.expiryDay, today: day) == .past, symbol: "chevron.right")
                    }.buttonStyle(.plain).accessibilityIdentifier("today.dates.\(item.name)")
                }
                NavigationLink { InventoryView() } label: { footer("Open pantry") }
            case .restock:
                ForEach(Array(data.restock.prefix(limit ?? data.restock.count))) { item in
                    let alreadyShopping = repository.duplicateShoppingItem(item.name) != nil
                    VStack(alignment: .leading, spacing: 4) {
                        Button { editing = repository.inventory.first { $0.id == item.id } } label: {
                            itemRow(name: item.name, detail: "Low stock", status: nil, warning: false, symbol: "chevron.right")
                        }.buttonStyle(.plain)
                        Button {
                            guard let pack = repository.inventory.first(where: { $0.id == item.id }) else { return }
                            do { try repository.restockInventory(pack) } catch { self.error = userFacingError(error) }
                        } label: {
                            Label(alreadyShopping ? "On shopping list" : "Add to shopping", systemImage: alreadyShopping ? "checkmark.circle" : "plus")
                                .font(.subheadline.weight(.medium)).frame(minHeight: 44)
                        }.buttonStyle(.plain).foregroundStyle(TodayTheme.accent)
                            .disabled(readOnly || alreadyShopping).accessibilityIdentifier("today.restock.\(item.name)")
                    }
                }
                NavigationLink { ShoppingListView() } label: { footer("Open shopping") }
            }
        }
        .sheet(item: $purchase) { ShoppingPurchaseSheet(item: $0) { feedback = $0 } }
        .purchaseFeedback($feedback)
        .sheet(item: $editing) { InventoryEditor(item: $0) }
        .saveError($error)
    }
    private var emptyText: String {
        switch priority {
        case .buy: "No shopping needed now. Later items stay on your list."
        case .dates: "No recorded expiry dates need attention."
        case .restock: "No active ingredients are marked low."
        }
    }
    private func footer(_ title: String) -> some View {
        HStack { Text(title); Spacer(); Image(systemName: "arrow.right").accessibilityHidden(true) }
            .font(.subheadline.weight(.semibold)).foregroundStyle(TodayTheme.accent).frame(minHeight: 44)
    }
    private func itemRow(name: String, detail: String, status: String?, warning: Bool, symbol: String) -> some View {
        HStack(spacing: 12) {
            Text(PantryVisualRules.icon(name, category: PantryVisualRules.category(name)))
                .font(.system(size: 27)).frame(width: 44, height: 48)
                .background(TodayTheme.hero.opacity(0.65), in: RoundedRectangle(cornerRadius: 13)).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(name).font(.subheadline.weight(.semibold)).foregroundStyle(TodayTheme.ink)
                Text(detail).font(.caption).foregroundStyle(TodayTheme.muted)
                if let status {
                    Label(status, systemImage: warning ? "exclamationmark.circle" : "clock")
                        .font(.caption).foregroundStyle(warning ? InventoryStatusBadges.danger : TodayTheme.muted)
                }
            }.fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            Image(systemName: symbol).font(.body).foregroundStyle(TodayTheme.accent).accessibilityHidden(true)
        }.frame(maxWidth: .infinity, minHeight: 54, alignment: .leading).contentShape(Rectangle())
    }
}
