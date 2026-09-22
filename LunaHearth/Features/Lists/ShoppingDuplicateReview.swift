import SwiftUI

struct ShoppingDuplicateReview: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    @State private var deleting: GroceryItem?
    @State private var editing: GroceryItem?
    @State private var error: String?
    private var groups: [[GroceryItem]] {
        Dictionary(grouping: repository.groceries.filter { !$0.isCompleted }, by: { IngredientMatching.key($0.name) })
            .values.filter { $0.count > 1 }.map { $0.sorted { $0.createdAt < $1.createdAt } }
            .sorted { ($0.first?.name ?? "") < ($1.first?.name ?? "") }
    }
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("One purchase, or two?").font(AppTheme.sectionTitle)
                    Text("These pending names match, including known regional aliases. Different stores, buyers or amounts may be intentional. Review before removing an extra entry.")
                }
                if groups.isEmpty {
                    ContentUnavailableView("No matching duplicates", systemImage: "checkmark.circle", description: Text("Known names and aliases found no duplicates. Edit an item to check less obvious names with on-device AI."))
                }
                ForEach(groups, id: \.first?.id) { group in
                    Section(group.first?.name ?? "Similar items") {
                        ForEach(group) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.name).font(.headline)
                                Text([item.quantityText, repository.shoppingStoreName(for: item), item.assignedMemberID.map { repository.memberName($0) }, item.neededLater == true ? "Later" : "Now", item.plannedDay].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")).font(.subheadline)
                                HStack {
                                    Button("Review item") { editing = item }
                                    Spacer()
                                    Button("Remove extra", role: .destructive) { deleting = item }
                                }.buttonStyle(.borderless)
                            }.padding(.vertical, 4)
                        }
                    }
                }
            }.scrollContentBackground(.hidden).background(ShoppingTheme.canvas).tint(ShoppingTheme.accent)
                .navigationTitle("Similar shopping items").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
                .sheet(item: $editing) { QuickAddView(draft: .editing($0)) }
                .confirmationDialog("Remove this extra shopping item?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
                    Button("Remove \(deleting?.name ?? "item")", role: .destructive) {
                        guard let item = deleting else { return }
                        do { try repository.deletePlanningEntry(id: item.id, kind: .grocery); deleting = nil } catch { self.error = error.localizedDescription }
                    }
                } message: { Text("This removes only the selected shopping entry from the household and syncs the deletion when enabled. Inventory and other purchases stay.") }
                .saveError($error)
        }
    }
}
