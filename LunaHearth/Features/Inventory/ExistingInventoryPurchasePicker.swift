import SwiftUI

struct ExistingInventoryPurchasePicker: View {
    let grocery: GroceryItem
    let finished: () -> Void
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    @State private var selected: UUID?
    @State private var removing: InventoryItem?
    @State private var error: String?
    private var matches: [InventoryItem] {
        repository.inventory.filter { InventoryRules.canRestock(isUsedUp: $0.isUsedUp, expiryDay: $0.expiryDay) && IngredientMatching.same($0.name, grocery.name) }
            .sorted { $0.createdAt == $1.createdAt ? $0.id.uuidString < $1.id.uuidString : $0.createdAt < $1.createdAt }
    }
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Choose the entry to restock.").font(AppTheme.sectionTitle)
                    Text("These are saved inventory packs, not new shopping items. Select one to mark bought and clear its Low stock flag. Remove an entry only if it is an accidental duplicate; compatible purchase quantities are added to the selected pack; dates stay unchanged.")
                }
                ForEach(Array(matches.enumerated()), id: \.element.id) { index, pack in
                    Section("Saved pack \(index + 1)") {
                        Button { selected = pack.id } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: selected == pack.id ? "checkmark.circle.fill" : "circle").font(.title2)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(pack.name).font(.headline)
                                    Text(RestockQuantity.detail(existing: pack.quantityText, purchased: grocery.quantityText)).font(.subheadline)
                                    if let details = pack.packDetails { Text(details).font(.caption) }
                                    if let location = pack.location { Text(location).font(.caption) }
                                    if let store = pack.storeName { Text(store).font(.caption) }
                                    Text(InventoryRules.expiryLabel(pack.expiryDay, today: HouseholdDay(.now).key)).font(.caption)
                                }
                                Spacer(minLength: 0)
                            }.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityIdentifier("shopping.existingPack.\(index)")
                        Button("Remove accidental duplicate", role: .destructive) { removing = pack }
                            .buttonStyle(.borderless).accessibilityIdentifier("shopping.removeExistingPack.\(index)")
                    }.listRowBackground(InventoryTheme.surface)
                }
                if matches.isEmpty { Text("No matching active packs remain. Go back to add the new purchase to inventory.") }
            }.scrollContentBackground(.hidden).background(InventoryTheme.canvas).tint(InventoryTheme.accent)
                .navigationTitle("Existing \(grocery.name)").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Back") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Restock selected") {
                            guard let selected else { return }
                            do { try repository.recordPurchase(grocery, addToInventory: true, keeping: selected); dismiss(); finished() }
                            catch { self.error = error.localizedDescription }
                        }.disabled(!matches.contains { $0.id == selected }).accessibilityIdentifier("shopping.useSelectedInventory")
                    }
                }
                .onChange(of: matches.map(\.id)) { _, ids in
                    if let selected, !ids.contains(selected) { self.selected = nil }
                    if ids.count == 1 { selected = ids.first }
                }
                .confirmationDialog("Remove this inventory entry?", isPresented: Binding(get: { removing != nil }, set: { if !$0 { removing = nil } })) {
                    Button("Remove duplicate", role: .destructive) {
                        guard let pack = removing else { return }
                        do { try repository.deleteInventory(pack); removing = nil } catch { self.error = error.localizedDescription }
                    }
                } message: { Text("Only this entry and its details are deleted from household inventory. Other packs and shopping stay. This syncs when enabled and cannot be undone.") }
                .saveError($error)
        }
    }
}
