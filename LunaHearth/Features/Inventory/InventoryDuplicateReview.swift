import SwiftUI

/// No automatic merging: equal ingredients can still be different purchased packs.
struct InventoryDuplicateReview: View {
    @Environment(PublicConfigurationStore.self) private var publicStatus
    @Environment(\.aiAvailability) private var aiAvailability
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    @State private var deleting: InventoryItem?
    @State private var editing: InventoryItem?
    @State private var error: String?
    private var groups: [[InventoryItem]] {
        Dictionary(grouping: repository.inventory.filter { !$0.isUsedUp }, by: { IngredientMatching.key($0.name) })
            .values.filter { $0.count > 1 }.map { $0.sorted { $0.createdAt < $1.createdAt } }
            .sorted { ($0.first?.name ?? "") < ($1.first?.name ?? "") }
    }
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Same ingredient, or another pack?").font(AppTheme.sectionTitle)
                    Text("These names match, including known regional aliases. Compare the pack details before removing an extra entry. Quantities are never combined automatically.")
                }
                if groups.isEmpty {
                    ContentUnavailableView("No matching duplicates", systemImage: "checkmark.circle", description: Text((aiAvailability.showsAIActions && (publicStatus.configuration?.allows(.aiDuplicates) ?? true)) ? "Offline name and alias checks found none. Open any item to check less obvious names with on-device AI." : "Offline name and alias checks found no matching duplicates."))
                }
                ForEach(groups, id: \.first?.id) { group in
                    Section(group.first?.name ?? "Similar items") {
                        ForEach(group) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.name).font(.headline)
                                Text([item.quantityText, item.packDetails, item.storeName, item.location, item.expiryDay.map { "Expiry: \($0)" }].compactMap { $0 }.joined(separator: " · ")).font(.subheadline)
                                HStack {
                                    Button("Review pack") { editing = item }.buttonStyle(.borderless)
                                    Spacer()
                                    Button("Remove extra", role: .destructive) { deleting = item }.buttonStyle(.borderless)
                                }
                            }.padding(.vertical, 4)
                        }
                    }
                }
            }.scrollContentBackground(.hidden).background(InventoryTheme.canvas).tint(InventoryTheme.accent)
                .navigationTitle("Similar items").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
                .sheet(item: $editing) { InventoryEditor(item: $0) }
                .confirmationDialog("Remove this extra entry?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
                    Button("Remove \(deleting?.name ?? "entry")", role: .destructive) {
                        guard let item = deleting else { return }
                        do { try repository.deleteInventory(item); deleting = nil } catch { self.error = error.localizedDescription }
                    }
                } message: { Text("Only this pack and its details will be removed from the household inventory. Shopping history and the other packs stay.") }
                .saveError($error)
        }
    }
}
