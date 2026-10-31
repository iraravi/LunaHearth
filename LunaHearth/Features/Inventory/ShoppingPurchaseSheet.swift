import SwiftUI

struct ShoppingPurchaseSheet: View {
    let item: GroceryItem
    var onCompleted: (PurchaseFeedback) -> Void = { _ in }
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dynamicTypeSize) private var textSize
    @Environment(\.dismiss) private var dismiss
    @State private var error: String?
    @State private var choosingExisting = false
    private var matches: [InventoryItem] { repository.inventory.filter { InventoryRules.canRestock(isUsedUp: $0.isUsedUp, expiryDay: $0.expiryDay) && IngredientMatching.same($0.name, item.name) } }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(item.name).font(AppTheme.sectionTitle)
                    Text("Keep it at home, or finish without stocking it.").font(.subheadline).foregroundStyle(InventoryTheme.muted)
                    if repository.inventory.contains(where: { !$0.isUsedUp && IngredientMatching.same($0.name, item.name) && !InventoryRules.canRestock(isUsedUp: $0.isUsedUp, expiryDay: $0.expiryDay) }) {
                        Text("An older pack is past expiry. This purchase will use a separate pack or another recorded pack; expired quantities stay separate.").font(.subheadline).foregroundStyle(InventoryTheme.muted)
                    }
                    if item.purchaseDisposition == "inventory" {
                        choice("Already in pantry", detail: "Finish shopping again without creating another pack.", symbol: "checkmark.circle", identifier: "shopping.purchaseInventory", inventory: true)
                    } else if !matches.isEmpty {
                        Label("Already at home", systemImage: "cabinet").font(.headline)
                        Button {
                            if matches.count == 1, let match = matches.first {
                                do { try repository.recordPurchase(item, addToInventory: true, keeping: match.id); completed() } catch { self.error = error.localizedDescription }
                            } else { choosingExisting = true }
                        } label: {
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: "checkmark.circle").font(.title2).frame(width: 32)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Restock pack").font(.headline)
                                    Text(matches.count == 1 ? RestockQuantity.detail(existing: matches.first?.quantityText, purchased: item.quantityText) : "\(matches.count) saved packs match. Choose which one to restock.")
                                        .font(.subheadline).foregroundStyle(InventoryTheme.muted)
                                }
                                Spacer(minLength: 0)
                            }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
                                .background(InventoryTheme.surface, in: RoundedRectangle(cornerRadius: 20)).contentShape(Rectangle())
                        }.buttonStyle(.plain).foregroundStyle(InventoryTheme.accent).accessibilityIdentifier("shopping.keepInventory.existing")
                        choice("New pack", detail: "Create another pack only if it needs its own amount or expiry date.", symbol: "plus.square.on.square", identifier: "shopping.separateInventory", inventory: true, separate: true)
                    } else {
                        choice("Add to pantry", detail: "Mark this bought and add it to your pantry. You can add an expiry date later.", symbol: "shippingbox.and.arrow.backward", identifier: "shopping.purchaseInventory", inventory: true)
                    }
                    choice("Purchase only", detail: "Mark this bought without adding it to your pantry—for gifts, meals out or items kept elsewhere.", symbol: "gift", identifier: "shopping.purchaseOnly", inventory: false)
                    Text("Changing shopping status later won’t remove a pack from inventory.").font(.caption).foregroundStyle(InventoryTheme.muted)
                }.padding(24)
            }.background(InventoryTheme.canvas).tint(InventoryTheme.accent)
                .navigationTitle("Finish shopping").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
                .sheet(isPresented: $choosingExisting) { ExistingInventoryPurchasePicker(grocery: item) { completed() } }
                .saveError($error)
        }.presentationDetents(matches.isEmpty && !textSize.isAccessibilitySize ? [.medium, .large] : [.large])
    }
    private func completed() {
        let history = repository.purchases.first { $0.groceryID == item.id }
        let stock = history?.inventoryID.flatMap { id in repository.inventory.first { $0.id == id } }
        let detail = item.purchaseDisposition == "inventory"
            ? stock?.quantityText.map { "Pantry · " + $0 } ?? "Recorded in pantry"
            : "Shopping completed · Not added to pantry"
        onCompleted(PurchaseFeedback(name: item.name, detail: detail))
        dismiss()
    }
    private func choice(_ title: String, detail: String, symbol: String, identifier: String, inventory: Bool, keeping: UUID? = nil, separate: Bool = false) -> some View {
        Button {
            do { try repository.recordPurchase(item, addToInventory: inventory, keeping: keeping, allowSeparatePack: separate); completed() } catch { self.error = error.localizedDescription }
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: symbol).font(.title2).frame(width: 32).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.headline)
                    Text(detail).font(.subheadline).foregroundStyle(InventoryTheme.muted)
                }
                Spacer(minLength: 0)
            }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
                .background(InventoryTheme.surface, in: RoundedRectangle(cornerRadius: 20))
        }.buttonStyle(.plain).foregroundStyle(InventoryTheme.accent).accessibilityIdentifier(identifier)
    }
}
